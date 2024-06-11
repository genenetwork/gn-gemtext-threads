(import (tissue tissue))

(define %css
  "/style.css")

(define %engine
  (html-engine #:css %css))

(define %github-repo-uri
  "https://github.com/genenetwork/gn-gemtext-threads")

(define %repo-branch
  "main")

(define (genenetwork-gemtext-reader file)
  (lambda (port)
    (match ((gemtext-reader) port)
      ((? eof-object? eof) eof)
      (('document body ...)
       `(document
         (ref #:url ,(string-append %github-repo-uri "/edit/" %repo-branch "/" file)
              #:text "Edit this page")
         " | "
         (ref #:url ,(string-append %github-repo-uri "/blame/" %repo-branch "/" file)
              #:text "Blame")
         ,@body)))))

(tissue-configuration
 #:aliases '(("Alexander Kabui" "Alexander" "alex" "alexk")
             ("Arun Isaac" "arun" "aruni")
             ("BonfaceKilz" "Bonface Kilz" "bonfacem")
	     ("Felix Lisso" "fetche" "flisso")
             ("Efraim Flashner" "efraimf")
             ("Erik Garrison" "erikg")
             ("Frederick Muriuki Muriithi" "Muriithi Frederick Muriuki" "fredm" "fred")
             ("Pjotr Prins" "pjotrp")
             ("Rob Williams" "robw")
             ("Arthur Centeno" "acenteno")
             ("jgart")
	     ("Solomon Shelby" "soloshelby" "SidiBlak")
	     ("priscilla")
             ("Zachary Sloan" "zach" "zachs" "zsloan")
             ("Artyom Bologov" "aartaka" "artyom" "artyomb")
             ("John Nduli" "jnduli" "rookie101"))
 #:indexed-documents (append (map (lambda (filename)
                                    (slot-set (read-gemtext-issue filename)
                                              'web-uri
                                              (string-append "/" (string-remove-suffix ".gmi" filename))))
                                  (gemtext-files-in-directory "issues"))
                             (map (lambda (filename)
                                    (slot-set (read-gemtext-document filename)
                                              'web-uri
                                              (string-append "/" (string-remove-suffix ".gmi" filename))))
                                  (gemtext-files-in-directory "topics")))
 #:web-files (cons* (file "style.css"
                          (copier "style.css"))
                    (filter-map (lambda (filename)
                                  (cond
                                   ((and (string-suffix? ".gmi" filename)
                                         (not (string=? (basename filename)
                                                        "README.gmi")))
                                    (file (replace-extension filename "html")
                                          (gemtext-exporter filename
                                                            #:reader (genenetwork-gemtext-reader filename)
                                                            #:engine %engine)))
                                   ((or (string-suffix? ".jpg" filename)
                                        (string-suffix? ".png" filename)
                                        (string-suffix? ".svg" filename)
                                        (string-suffix? ".scm" filename))
                                    (file filename
                                          (copier filename)))
                                   (else #f)))
                                (git-tracked-files))))
