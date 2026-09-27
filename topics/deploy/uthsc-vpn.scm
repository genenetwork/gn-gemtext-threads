;; $(guix build -f uthsc-vpn.scm)
;;
;; Update this ==> 2026-09-27: Known working guix commit: 825f0743

(use-modules ((gnu packages check)
              #:select (python-pytest python-pytest-asyncio python-pytest-httpserver))
             ((gnu packages freedesktop) #:select (python-pyxdg))
             ((gnu packages python-build)
              #:select (python-poetry-core python-toml python-colorama
                                           python-wheel python-setuptools))
             ((gnu packages python-crypto)
              #:select (python-keyring python-pyotp))
             ((gnu packages python-web) #:select (python-requests python-urllib3))
             ((gnu packages python-xyz)
              #:select (python-attrs python-charset-normalizer
                                     python-prompt-toolkit python-pysocks
                                     python-structlog))
             ((gnu packages guile-xyz) #:select (guile-ini guile-lib guile-smc))
             ((gnu packages qt) #:select (python-pyqt-6 python-pyqtwebengine-6))
             ((gnu packages vpn) #:select (openconnect vpn-slice))
             ((gnu packages xml) #:select (python-lxml))
             (guix build-system pyproject)
             (guix build-system python)
             (guix download)
             (guix gexp)
             (guix git-download)
             ((guix licenses) #:prefix license:)
             (guix packages))

;; Put in the hosts you are interested in here.
(define %hosts
  (list "octopus01"
        "octopus02"
        "octopus03"
        "octopus04"
        "rabbit"
        "tux01"
        "tux02"
        "tux03"
        "tux04"
        "tux05"
        ))

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

(define python-charset-normalizer-2.10
  (package
    (inherit python-charset-normalizer)
    (version "2.1.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "charset-normalizer" version))
       (sha256
        (base32 "04zlajr77f6c7ai59l46as1idi0jjgbvj72lh4v5wfpz2s070pjp"))))
    (build-system python-build-system)
    (arguments
     (list #:tests? #f))))

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
    (native-inputs (list python-setuptools))
    (propagated-inputs
     (modify-inputs (package-propagated-inputs python-requests)
       (replace "python-charset-normalizer" python-charset-normalizer-2.10)
       (replace "python-urllib3" python-urllib3-1.26)))))

(define-public python-lxml-4.9
  ;; removed from guix in commit d45b0d2. Copied here to keep build sane.
  (hidden-package
   (package
     (inherit python-lxml)
     (name "python-lxml")
     (version "4.9.4")
     (source
      (origin
        (method url-fetch)
        (uri (pypi-uri "lxml" version))
        (sha256
         (base32 "03l86qr5xzvz0jcbk669sj8nbw1fjshmf0b7l83gl5cfnx81wm5i"))))
     (arguments
      (list #:tests? #f                 ;some tests fail with newer libxml2
            #:phases
            #~(modify-phases %standard-phases
                (add-after 'unpack 'relax-gcc-14-strictness
                  (lambda _
                    (setenv "CFLAGS"
                            "-Wno-error=incompatible-pointer-types")))))))))

(define-public python-keyring-23
  (package
    (inherit python-keyring)
    (version "23.9.3")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "keyring" version))
       (sha256
        (base32
         "19f4jpsxng9sjfqi8ww5hgg196r2zh1zb8g71wjr1xa27kc1vc39"))))
    (arguments
     (list
      #:phases
      #~(modify-phases %standard-phases
          (add-before 'check 'workaround-test-failure
            (lambda _
              ;; Workaround a failure in the test_entry_point test (see:
              ;; https://github.com/jaraco/keyring/issues/526).
              (delete-file-recursively "keyring.egg-info"))))))
    (native-inputs
     (modify-inputs (package-native-inputs python-keyring)
       (prepend  python-toml python-wheel)
       (delete "python-pyfakefs" "python-setuptools-scm")))
    (propagated-inputs
     (modify-inputs (package-propagated-inputs python-keyring)
       (delete "python-jeepney"
               "python-jaraco-context"
               "python-jaraco-functools")))))

(define-public openconnect-sso
  (package
    (name "openconnect-sso")
    ;; 0.8.0 was released in 2021, the latest update on master HEAD is from
    ;; 2023.
    (properties '((commit . "94128073ef49acb3bad84a2ae19fdef926ab7bdf")
                  (revision . "0")))
    (version (git-version "0.8.0"
                          (assoc-ref properties 'revision)
                          (assoc-ref properties 'commit)))
    (source
      (origin
        (method git-fetch)
        (uri (git-reference
               (url "https://github.com/vlaci/openconnect-sso")
              (commit (assoc-ref properties 'commit))))
        (file-name (git-file-name name version))
        (sha256
         (base32 "08cqd40p9vld1liyl6qrsdrilzc709scyfghfzmmja3m1m7nym94"))))
    (build-system pyproject-build-system)
    (arguments
     `(#:phases
       (modify-phases %standard-phases
          (add-after 'unpack 'use-poetry-core
            (lambda _
              ;; Patch to use the core poetry API.
              (substitute* "pyproject.toml"
                (("poetry.masonry.api")
                 "poetry.core.masonry.api"))))
         (add-after 'unpack 'patch-openconnect
           (lambda* (#:key inputs #:allow-other-keys)
             (substitute* "openconnect_sso/app.py"
               (("\"openconnect\"")
                (string-append "\""
                               (search-input-file inputs "/sbin/openconnect")
                               "\"")))))

         ;; Fails for keyring, despite having a valid version
         (delete 'sanity-check))))
    (inputs
     (list openconnect
           python-attrs
           python-colorama
           python-keyring-23
           python-lxml-4.9
           python-prompt-toolkit
           python-pyotp
           python-pyqt-6
           python-pyqtwebengine-6
           python-pysocks
           python-pyxdg
           python-requests
           python-structlog
           python-toml))
    (native-inputs
     (list python-poetry-core
           python-pytest
           python-pytest-asyncio
           python-pytest-httpserver))
    (home-page "https://github.com/vlaci/openconnect-sso")
    (synopsis "OpenConnect wrapper script supporting Azure AD (SAMLv2)")
    (description
     "This package provides a wrapper script for OpenConnect supporting Azure AD
(SAMLv2) authentication to Cisco SSL-VPNs.")
    (license license:gpl3)))

;; Login to the UTHSC VPN fails with an SSLV3_ALERT_HANDSHAKE_FAILURE
;; on newer python-requests.
(define openconnect-sso-uthsc
  (package
    (inherit openconnect-sso)
    (name "openconnect-sso-uthsc")
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
                #$(local-file "uthsc-certificate-chain.pem"))

        ;; Force software rendering — forwarded X11 has no working GLX/GPU,
        ;; so QtWebEngine's Chromium GL init crashes without these.
        (setenv "QTWEBENGINE_CHROMIUM_FLAGS"
                "--disable-gpu --disable-gpu-compositing --in-process-gpu")
        (setenv "QT_OPENGL" "software")
        (setenv "LIBGL_ALWAYS_SOFTWARE" "1")

        (invoke #$(file-append openconnect-sso-uthsc "/bin/openconnect-sso")
                "--server" "uthscvpn1.uthsc.edu" ; ask us for end-point or see UT docs
                "--authgroup" "UTHSC"
                "--"
                "--script" (string-join (cons #$(file-append vpn-slice "/bin/vpn-slice")
                                              '#$%hosts))))))

(program-file "uthsc-vpn" uthsc-vpn)
