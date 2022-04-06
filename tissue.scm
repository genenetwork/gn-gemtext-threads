(import (tissue tissue))

(tissue-configuration
 #:project "GeneNetwork issue tracker"
 #:aliases '(("Alexander Kabui" "alex")
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
                                                                       (gemtext-reader)))))
                                        (git-tracked-files)))))
