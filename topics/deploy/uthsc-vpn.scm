(use-modules ((gnu packages guile-xyz) #:select (guile-ini guile-lib guile-smc))
             ((gnu packages vpn) #:select (openconnect-sso vpn-slice))
             (guix gexp))

;; Put in the hosts you are interested in here.
(define %hosts
  (list "octopus01"
        "tux01.genenetwork.org"))

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
        (invoke #$(file-append openconnect-sso "/bin/openconnect-sso")
                "--server" "uthscvpn1.uthsc.edu"
                "--authgroup" "UTHSC"
                "--"
                "--script" (string-join (cons #$(file-append vpn-slice "/bin/vpn-slice")
                                              '#$%hosts))))))

(program-file "uthsc-vpn" uthsc-vpn)
