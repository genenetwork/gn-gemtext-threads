(import (tissue tissue))

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
 #:project "GeneNetwork issue tracker"
 #:issue-files (remove (lambda (filename)
                         (string=? (basename filename)
                                   "README.gmi"))
                       (gemtext-files-in-directory "issues"))
 #:aliases '(("Alexander Kabui" "Alexander" "alex" "alexk")
             ("Arun Isaac" "aruni")
             ("BonfaceKilz" "Bonface Kilz" "bonfacem")
             ("Efraim Flashner" "efraimf")
             ("Erik Garrison" "erikg")
             ("Frederick Muriuki Muriithi" "Muriithi Frederick Muriuki" "fredm" "fred")
             ("Pjotr Prins" "pjotrp")
             ("Rob Williams" "robw")
             ("Arthur Centeno" "acenteno")
             ("jgart")
             ("Zachary Sloan" "zach" "zachs" "zsloan"))
 #:web-css "/style.css"
 #:web-files (cons* (file "style.css"
                          (copier "style.css"))
                    (file "index.html"
                          (skribe-exporter "index.skb"))
                    (file "closed.html"
                          (skribe-exporter "closed.skb"))
                    (file "team.html"
                          (skribe-exporter "team.skb"))
                    (file "topics.html"
                          (skribe-exporter "topics.skb"))
                    (append (tag-pages)
                            (filter-map (lambda (filename)
                                          (cond
                                           ((and (string-suffix? ".gmi" filename)
                                                 (not (string=? (basename filename)
                                                                "README.gmi")))
                                            (file (replace-extension filename "html")
                                                  (gemtext-exporter filename
                                                                    (genenetwork-gemtext-reader filename))))
                                           ((or (string-suffix? ".jpg" filename)
                                                (string-suffix? ".png" filename)
                                                (string-suffix? ".svg" filename))
                                            (file filename
                                                  (copier filename)))
                                           (else #f)))
                                        (git-tracked-files)))))
