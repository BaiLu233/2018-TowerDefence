(in-package :bot)

(defun make-parser-name (class-name-symbol)
  (let ((name (symbol-name class-name-symbol)))
    (intern (concatenate 'string "PARSE-" name))))

(defun make-keyword (sym)
  (let ((name (symbol-name sym)))
    (intern name "KEYWORD")))

(defun camel-case (str)
  (let ((parts (cl-ppcre:split "-+" str)))
    (format nil "~{~a~}" (cons (car parts) 
                               (mapcar #'string-capitalize (cdr parts))))))

(defun snake-case (str)
  (cl-ppcre:regex-replace-all "-" str "_"))

(defun screaming-snake-case (str)
  (string-upcase (snake-case str)))

(defun has-cdr (x)
  (and (consp x) (cdr x)))

(defun has-car (x)
  (and (consp x) (car x)))

(defun make-keys (slots case-fn)
  (mapcar (lambda (s) 
            (if (has-cdr s)
                (has-cdr s)
                (funcall case-fn (string-downcase (symbol-name s))))) slots))

(defun make-init-arg (slot-spec)
  (if (has-car slot-spec)
      (make-keyword (car slot-spec))
      (make-keyword slot-spec)))

(defmacro define-parser (class-name slots case-fn)
  (let* ((keys (make-keys slots case-fn))
         (init-args (mapcar #'make-init-arg slots))
         (parser-name (make-parser-name class-name)))
    (alexandria:with-gensyms (json-obj)
      (let ((constructor-params 
             (apply #'append (loop for key in keys
                                for init-arg in init-args 
                                collect (list init-arg 
                                              (list 'gethash key json-obj))))))
        `(defun ,parser-name (json)
           (let ((,json-obj (yason:parse json)))
             (make-instance ',class-name ,@constructor-params)))))))

(defun get-slot (slot-spec)
  (if (has-car slot-spec)
      (car slot-spec)
      slot-spec))

(defmacro define-data-class (name slots)
    (let ((slot-defs (loop for slot in slots 
                        collect (list (get-slot slot) 
                                      :accessor (get-slot slot) :initarg (make-init-arg slot)))))
      `(defclass ,name ()
         ,slot-defs)))

(defmacro define-poclo (name slots case-fn)
  `(progn 
     (define-data-class ,name ,slots)
     (define-parser ,name ,slots ,case-fn)))
