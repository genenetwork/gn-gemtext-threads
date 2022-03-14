(import (rnrs programs)
        (ice-9 match)
        (skribilo engine)
        (tissue web))

(let ((html-engine (find-engine 'html)))
  (engine-custom-set! html-engine 'css "/style.css")
  (match (command-line)
    ((_ output-directory)
     (build-website output-directory
                    #:title "GeneNetwork issue tracker"
                    #:tags-path "/tags"))
    (_
     (error "Invalid command-line usage"))))
