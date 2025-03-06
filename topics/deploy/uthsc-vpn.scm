(use-modules ((gnu packages python-web) #:select (python-requests python-urllib3))
             ((gnu packages guile-xyz) #:select (guile-ini guile-lib guile-smc))
             ((gnu packages vpn) #:select (openconnect-sso vpn-slice))
             (guix build-system python)
             (guix download)
             (guix gexp)
             (guix packages))

;; Put in the hosts you are interested in here.
(define %hosts
  (list "octopus01"
        "tux01.genenetwork.org"
        "tux03.genenetwork.org"
        "tux04.genenetwork.org"))

(define (ini-file name scm)
  "Return a file-like object representing INI file with @var{name} and
@var{scm} data."
  (computed-file name
                 (with-extensions (list guile-ini guile-lib guile-smc)
                   #~(begin
                       (use-modules (srfi srfi-26)
                                    (ini))

                       (call-with-output-file #$output
                         (cut scm->ini #$scm #:port <>))))))

(define python-urllib3-1.26
  (package
    (inherit python-urllib3)
    (version "1.26.15")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "urllib3" version))
       (sha256
        (base32
         "01dkqv0rsjqyw4wrp6yj8h3bcnl7c678qkj845596vs7p4bqff4a"))))
    (build-system python-build-system)))

(define python-requests-2.28
  (package
    (inherit python-requests)
    (name "python-requests")
    (version "2.28.1")
    (source (origin
              (method url-fetch)
              (uri (pypi-uri "requests" version))
              (sha256
               (base32
                "10vrr7bijzrypvms3g2sgz8vya7f9ymmcv423ikampgy0aqrjmbw"))))
    (build-system python-build-system)
    (arguments (list #:tests? #f))
    (native-inputs (list))
    (propagated-inputs
     (modify-inputs (package-propagated-inputs python-requests)
       (replace "python-urllib3" python-urllib3-1.26)))))

;; Login to the UTHSC VPN fails with an SSLV3_ALERT_HANDSHAKE_FAILURE
;; on newer python-requests.
(define openconnect-sso-uthsc
  (package
    (inherit openconnect-sso)
    (inputs
     (modify-inputs (package-inputs openconnect-sso)
       (replace "python-requests" python-requests-2.28)))))

(define uthsc-vpn
  (with-imported-modules '((guix build utils))
    #~(begin
        (use-modules (guix build utils))

        (setenv "OPENSSL_CONF"
                #$(ini-file "openssl.cnf"
                            #~'((#f
                                 ("openssl_conf" . "openssl_init"))
                                ("openssl_init"
                                 ("ssl_conf" . "ssl_sect"))
                                ("ssl_sect"
                                 ("system_default" . "system_default_sect"))
                                ("system_default_sect"
                                 ("Options" . "UnsafeLegacyRenegotiation")))))
        (setenv "REQUESTS_CA_BUNDLE"
                #$(local-file "uthsc-certificate.pem"))
        (invoke #$(file-append openconnect-sso-uthsc "/bin/openconnect-sso")
                "--server" "uthscvpn1.uthsc.edu"
                "--authgroup" "UTHSC"
                "--"
                "--script" (string-join (cons #$(file-append vpn-slice "/bin/vpn-slice")
                                              '#$%hosts))))))

(program-file "uthsc-vpn" uthsc-vpn)
