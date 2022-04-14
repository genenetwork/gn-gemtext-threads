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
 #:aliases '(("Alexander Kabui" "Alexander" "alex")
             ("Arun Isaac" "aruni")
             ("BonfaceKilz" "bonfacem")
             ("Efraim Flashner" "efraimf")
             ("Erik Garrison" "erikg")
             ("Frederick Muriuki Muriithi" "Muriithi Frederick Muriuki" "fredm")
             ("Pjotr Prins" "pjotrp")
             ("Rob Williams" "robw")
             ("acenteno")
             ("jgart")
             ("zsloan"))
 #:web-css "/style.css"
 #:web-files (cons* (file "style.css"
                          (copier "style.css"))
                    (file "index.html"
                          (skribe-exporter "index.skb"))
                    (file "team.html"
                          (skribe-exporter "team.skb"))
                    (append (tag-pages)
                            (filter-map (lambda (filename)
                                          (and (string-suffix? ".gmi" filename)
                                               (not (string=? (basename filename)
                                                              "README.gmi"))
                                               (file (replace-extension filename "html")
                                                     (gemtext-exporter filename
                                                                       (genenetwork-gemtext-reader filename)))))
                                        (git-tracked-files)))))
