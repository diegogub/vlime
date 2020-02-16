(in-package :vlime)


(defvar vlime-symbol-prefix "§§")


(defmethod yason:encode ((sym symbol) &optional stream)
  (yason:encode
    (yason::encode-symbol-as-string sym nil vlime-symbol-prefix)
    stream))

(defun encode-via-yason (obj package)
  (declare (ignore package))
  (with-output-to-string (s) 
    (let ((yason:*list-encoder* #'yason:encode-alist)
          (yason:*symbol-key-encoder* #'yason::encode-symbol-as-string))
      (yason:encode obj s))))

(defun recover-symbols (input &optional package)
  (declare (ignore package))
  (labels 
      ((make-sym (stg)
         (let* ((p (position #\: stg)))
           (cond
             ((zerop p)
              ;; Just FIND-SYMBOL, or INTERN?
              (find-symbol (subseq stg 1) :keyword))
             (T
              ;; get PKG::SYM
              (assert (eql #\: (aref stg (1+ p))))
              ;; intern?
              (find-symbol (subseq stg (+ 2 p))
                           (subseq stg 0 p))))))
       (rec (tree)
         (cond 
           ((null tree)
            tree)
           ((stringp tree)
            (multiple-value-bind (match? after)
                (alexandria:starts-with-subseq vlime-symbol-prefix 
                                               tree
                                               :test #'eql
                                               :return-suffix t)
              (if match?
                  (make-sym after)
                  tree)))
           ((consp tree)
            (cons (rec (car tree))
                  (rec (cdr tree))))
           ((arrayp tree)
            (map 'vector #'rec tree))
           (t
            tree))))
    (let ((tree0 (yason:parse input)))
      (rec tree0))))

(defun use-json ()
  (with-open-file (da "/tmp/dsfg"
                      :if-exists :append
                      :direction :output
                      :if-does-not-exist :create)
    (format da "X~s~%" (multiple-value-list (get-decoded-time))))
  (swank::set-data-protocol
    #'encode-via-yason
    #'recover-symbols))


#+(or)
(recover-symbols 
    "[\"§§:RETURN\",[\"§§:OK\",true],1]")


#+(or)
(vlime::encode-via-yason '(:ad 2 yason:encode 1.12d00) nil)                                                                                                                   

#+(or)
(use-json)
