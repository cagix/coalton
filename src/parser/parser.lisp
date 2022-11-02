(defpackage #:coalton-impl/parser/parser
  (:use
   #:cl
   #:coalton-impl/parser/base
   #:coalton-impl/parser/types
   #:coalton-impl/parser/expression)
  (:shadowing-import-from
   #:coalton-impl/parser/base
   #:parse-error)
  (:local-nicknames
   (#:cst #:concrete-syntax-tree)
   (#:util #:coalton-impl/util))
  (:export
   #:keyword-src                        ; STRUCT
   #:make-keyword-src                   ; CONSTRUCTOR
   #:keyword-src-name                   ; ACCESSOR
   #:keyword-src-source                 ; ACCESSOR
   #:keyword-src-list                   ; TYPE
   #:identifier-src                     ; STRUCT
   #:make-identifier-src                ; CONSTRUCTOR
   #:identifier-src-name                ; ACCESSOR
   #:identifier-src-source              ; ACCESSOR
   #:identifier-src-list                ; TYPE
   #:constructor                        ; STRUCT
   #:make-constructor                   ; CONSTRUCTOR
   #:constructor-name                   ; ACCESSOR
   #:constructor-name                   ; ACCESSOR
   #:constructor-fields                 ; ACCESSOR
   #:constructor-source                 ; ACCESSOR
   #:constructor-list                   ; TYPE
   #:toplevel-define-type               ; STRUCT
   #:make-toplevel-define-type          ; CONSTRUCTOR
   #:toplevel-define-type-name          ; ACCESSOR
   #:toplevel-define-type-vars          ; ACCESSOR
   #:toplevel-define-type-ctors         ; ACCESSOR
   #:toplevel-define-type-source        ; ACCESSOR
   #:toplevel-define-type-list          ; TYPE
   #:toplevel-declare                   ; STRUCT
   #:make-toplevel-declare              ; CONSTRUCTOR
   #:toplevel-declare-name              ; ACCESSOR
   #:toplevel-declare-type              ; ACCESSOR
   #:toplevel-declare-source            ; ACCESSOR
   #:toplevel-declare-list              ; TYPE
   #:toplevel-define                    ; STRUCT
   #:make-toplevel-define               ; CONSTRUCTOR
   #:toplevel-define-name               ; ACCESSOR
   #:toplevel-define-vars               ; ACCESSOR
   #:toplevel-define-body               ; ACCESSOR
   #:toplevel-define-source             ; ACCESSOR
   #:toplevel-define-list               ; TYPE
   #:fundep                             ; STRUCT
   #:make-fundep                        ; CONSTRUCTOR
   #:fundep-left                        ; ACCESSOR
   #:fundep-right                       ; ACCESSOR
   #:fundep-source                      ; ACCESSOR
   #:fundep-list                        ; TYPE
   #:method-definition                  ; STRUCT
   #:make-method-definition             ; STRUCT
   #:method-definition-name             ; ACCESSOR
   #:method-definition-type             ; ACCESSOR
   #:method-definition-source           ; ACCESSOR
   #:method-definition-list             ; TYPE
   #:toplevel-define-class              ; STRUCT
   #:make-toplevel-define-class         ; CONSTRUCTOR
   #:toplevel-define-class-name         ; ACCESSOR
   #:toplevel-define-class-vars         ; ACCESSOR
   #:toplevel-define-class-preds        ; ACCESSOR
   #:toplevel-define-class-methods      ; ACCESSOR
   #:toplevel-define-class-source       ; ACCESSOR
   #:toplevel-define-class-type         ; TYPE
   #:instance-method-definition         ; STRUCT
   #:make-instance-method-definition    ; CONSTRUCTOR
   #:instance-method-definition-name    ; ACCESSOR
   #:instance-method-definition-vars    ; ACCESSOR
   #:instance-method-definition-body    ; ACCESSOR
   #:instance-method-definition-source  ; ACCESSOR
   #:instance-method-definition-list    ; TYPE
   #:toplevel-define-instance           ; STRUCT
   #:make-toplevel-define-instance      ; CONSTRUCTOR
   #:toplevel-define-instance-context   ; ACCESSOR
   #:toplevel-define-instance-pred      ; ACCESSOR
   #:toplevel-define-instance-methods   ; ACCESSOR
   #:toplevel-define-instance-source    ; ACCESSOR
   #:toplevel-define-instance-list      ; TYPE
   #:program                            ; STRUCT
   #:make-program                       ; CONSTRUCTOR
   #:program-package                    ; ACCESSOR
   #:program-file                       ; ACCESSOR
   #:program-types                      ; ACCESSOR
   #:program-declares                   ; ACCESSOR
   #:program-defines                    ; ACCESSOR
   #:program-classes                    ; ACCESSOR
   #:program-instances                  ; ACCESSOR
   #:parse-file                         ; FUNCTION
   ))

(in-package #:coalton-impl/parser/parser)

;;
;; Symbols with source information
;;

(defstruct (keyword-src
            (:copier nil))
  (name   (util:required 'name)   :type keyword :read-only t)
  (source (util:required 'source) :type cons    :read-only t))

(defun keyword-src-list-p (x)
  (and (alexandria:proper-list-p x)
       (every #'keyword-src-p x)))

(deftype keyword-src-list ()
  '(satisfies keyword-src-list-p))

(defstruct (identifier-src
            (:copier nil))
  (name   (util:required 'name)   :type identifier :read-only t)
  (source (util:required 'source) :type cons       :read-only t))

(defun identifier-src-list-p (x)
  (and (alexandria:proper-list-p x)
       (every #'identifier-src-p x)))

(deftype identifier-src-list ()
  '(satisfies identifier-src-list-p))

;;
;; Attributes
;;

(defstruct (attribute
            (:constructor nil)
            (:copier nil))
  (source (util:required 'source) :type cons :read-only t))

(defstruct (attribute-monomorphize
            (:include attribute)))

(defstruct (attribute-repr
            (:include attribute))
  (type (util:required 'type) :type keyword-src       :read-only t)
  (arg  (util:required 'arg)  :type (or null cst:cst) :read-only t))

;;
;; Toplevel Structures
;;

(defstruct (constructor
            (:copier nil))
  (name   (util:required 'name)   :type identifier-src :read-only t)
  (fields (util:required 'fields) :type ty-list        :read-only t)
  (source (util:required 'source) :type cons           :read-only t))

(defun constructor-list-p (x)
  (and (alexandria:proper-list-p x)
       (every #'constructor-p x)))

(deftype constructor-list ()
  '(satisfies constructor-list-p))

(defstruct (toplevel-define-type
            (:copier nil))
  (name   (util:required 'name)   :type identifier-src           :read-only t)
  (vars   (util:required 'vars)   :type keyword-src-list         :read-only t)
  (ctors  (util:required 'ctors)  :type constructor-list         :read-only t)
  (source (util:required 'source) :type cons                     :read-only t)
  (repr   (util:required 'repr)   :type (or null attribute-repr) :read-only nil))

(eval-when (:load-toplevel :compile-toplevel :execute)
  (defun toplevel-define-type-list-p (x)
    (and (alexandria:proper-list-p x)
         (every #'toplevel-define-type-p x))))

(deftype toplevel-define-type-list ()
  '(satisfies toplevel-define-type-list-p))

(defstruct (toplevel-declare
            (:copier nil))
  (name         (util:required 'name)         :type identifier-src                  :read-only t)
  (type         (util:required 'type)         :type qualified-ty                    :read-only t)
  (source       (util:required 'source)       :type cons                            :read-only t)
  (monomorphize (util:required 'monomorphize) :type (or null attribute-monomorphize) :read-only nil))

(eval-when (:load-toplevel :compile-toplevel :execute)
  (defun toplevel-declare-list-p (x)
    (and (alexandria:proper-list-p x)
         (every #'toplevel-declare-p x))))

(deftype toplevel-declare-list ()
  '(satisfies toplevel-declare-list-p))

(defstruct (toplevel-define
            (:copier nil))
  (name         (util:required 'name)         :type identifier-src                  :read-only t)
  (vars         (util:required 'vars)         :type identifier-src-list             :read-only t)
  (body         (util:required 'body)         :type node-body                       :read-only t)
  (source       (util:required 'source)       :type cons                            :read-only t)
  (monomorphize (util:required 'monomorphize) :type (or null attribute-monomorphize) :read-only nil))

(eval-when (:load-toplevel :compile-toplevel :execute)
  (defun toplevel-define-list-p (x)
    (and (alexandria:proper-list-p x)
         (every #'toplevel-define-p x))))

(deftype toplevel-define-list ()
  '(satisfies toplevel-define-list-p))

(defstruct (fundep
            (:copier nil))
  (left   (util:required 'left)   :type keyword-src-list :read-only t)
  (right  (util:required 'right)  :type keyword-src-list :read-only t)
  (source (util:required 'source) :type cons             :read-only t))

(defun fundep-list-p (x)
  (and (alexandria:proper-list-p x)
       (every #'fundep-p x)))

(deftype fundep-list ()
  '(satisfies fundep-list-p))

(defstruct (method-definition
            (:copier nil))
  (name   (util:required 'name)   :type identifier-src :read-only t)
  (type   (util:required 'type)   :type qualified-ty   :read-only t)
  (source (util:required 'source) :type cons           :read-only t))

(defun method-definition-list-p (x)
  (and (alexandria:proper-list-p x)
       (every #'method-definition-p x)))

(deftype method-definition-list ()
  '(satisfies method-definition-list-p))

(defstruct (toplevel-define-class
            (:copier nil))
  (name     (util:required 'name)     :type identifier-src         :read-only t)
  (vars     (util:required 'vars)     :type keyword-src-list       :read-only t)
  (preds    (util:required 'preds)    :type ty-predicate-list      :read-only t)
  (fundeps  (util:required 'fundeps)  :type fundep-list            :read-only t)
  (methods  (util:required 'methods)  :type method-definition-list :read-only t)
  (source   (util:required 'source)   :type cons                   :read-only t)
  ;; Source information for context, name, and vars
  (head-src (util:required 'head-src) :type cons                   :read-only t))

(eval-when (:load-toplevel :compile-toplevel :execute)
  (defun toplevel-define-class-list-p (x)
    (and (alexandria:proper-list-p x)
         (every #'toplevel-define-class-p x))))

(deftype toplevel-define-class-list ()
  '(satisfies toplevel-define-class-list-p))

(defstruct (instance-method-definition
            (:copier nil))
  (name   (util:required 'name)   :type identifier-src      :read-only t)
  (vars   (util:required 'vars)   :type identifier-src-list :read-only t)
  (body   (util:required 'body)   :type node-body           :read-only t)
  (source (util:required 'source) :type cons                :read-only t))

(eval-when (:load-toplevel :compile-toplevel :execute)
  (defun instance-method-definition-list-p (x)
    (and (alexandria:proper-list-p x)
         (every #'instance-method-definition-p x))))

(deftype instance-method-definition-list ()
  '(satisfies instance-method-definition-list-p))

(defstruct (toplevel-define-instance
            (:copier nil))
  (context  (util:required 'context)  :type ty-predicate-list               :read-only t)
  (pred     (util:required 'pred)     :type ty-predicate                    :read-only t)
  (methods  (util:required 'methods)  :type instance-method-definition-list :read-only t)
  (source   (util:required 'source)   :type cons                            :read-only t)
  ;; Source information for the context and the pred
  (head-src (util:required 'head-src) :type cons                            :read-only t))

(eval-when (:load-toplevel :compile-toplevel :execute)
  (defun toplevel-define-instance-list-p (x)
    (and (alexandria:proper-list-p x)
         (every #'toplevel-define-instance-p x))))

(deftype toplevel-define-instance-list ()
  '(satisfies toplevel-define-instance-list-p))

(defstruct (program
            (:copier nil))
  (package   (util:required 'package) :type package                       :read-only t)
  (file      (util:required 'file)    :type sb-sys::fd-stream             :read-only t)
  (types     nil                      :type toplevel-define-type-list     :read-only nil)
  (declares  nil                      :type toplevel-declare-list         :read-only nil)
  (defines   nil                      :type toplevel-define-list          :read-only nil)
  (classes   nil                      :type toplevel-define-class-list    :read-only nil)
  (instances nil                      :type toplevel-define-instance-list :read-only nil))

;;
;; Empty package for reading (package) forms
;;
(defpackage #:coalton-impl/parser/read
  (:use))

;; TODO: handle trailing attributes

(defun parse-file (filename)
  (with-open-file (file filename :if-does-not-exist :error)
    (let* (;; Setup eclector readtable
           (eclector.readtable:*readtable*
             (eclector.readtable:copy-readtable eclector.readtable:*readtable*))

           ;; Initial package to read (package) forms into
           (*package* (find-package "COALTON-IMPL/PARSER/READ"))

           ;; Read unspecified floats as double floats
           (*read-default-float-format* 'double-float)

           ;; Read the (package) form
           (package-form (eclector.concrete-syntax-tree:read file nil 'eof)))

      (when (eq package-form 'eof)
        (error "file starts with eof"))

      (setf *package* (parse-package package-form file))

      (let* ((program (make-program :package *package* :file file))

             (attributes (make-array 0 :adjustable t :fill-pointer t)))

        (block parse-loop
          (loop :with elem := nil
                :do (setf elem (eclector.concrete-syntax-tree:read file nil 'eof))

                :when (eq elem 'eof)
                  :do (return-from parse-loop)

                :do (when (and (parse-toplevel-form elem program attributes file)
                               (plusp (length attributes)))
                      (util:coalton-bug "parse-toplevel-form indicated that a form was parsed but did not
consume all attributes"))))

        (unless (zerop (length attributes))
          (error 'parse-error
                 :err (coalton-error
                       (cdr (aref attributes 0)) file
                       :message "Orphan attribute"
                       :primary-note "attribute must be attached to another form")))

        (setf (program-types program) (nreverse (program-types program)))
        (setf (program-declares program) (nreverse (program-declares program)))
        (setf (program-defines program) (nreverse (program-defines program)))
        (setf (program-classes program) (nreverse (program-classes program)))

        program))))

(defun parse-package (form file)
  "Parses a coalton package decleration in the form of (package {name})"
  (declare (type cst:cst form)
           (type sb-sys::fd-stream file)
           (values package))

  ;; Package declarations must start with "PACKAGE"
  (unless (equalp (symbol-name (cst:raw (cst:first form))) "PACKAGE")
    (error 'parse-error
           :err (coalton-error
                 (cst:first form) file
                 :message "Malformed package declaration"
                 :primary-note "package declarations must start with `package`")))

  ;; Package declarations must have a name
  (unless (cst:consp (cst:rest form))
    (error 'parse-error
           :err (coalton-error
                 (cst:first form) file
                 :message "Malformed package declaration"
                 :primary-note "missing package name")))

  ;; Package declarations cannot contain more than two forms
  (when (cst:consp (cst:rest (cst:rest form)))
    (error 'parse-error
           :err (coalton-error
                 (cst:first (cst:rest (cst:rest form))) file
                 :message "Malformed package declaration"
                 :primary-note "unexpected forms")))

  (unless (identifier-p (cst:raw (cst:second form)))
    (error 'parse-error
           :err (coalton-error
                 (cst:second form) file
                 :message "Malformed package declaration"
                 :primary-note "package name must be a symbol")))

  (let* ((package-name (symbol-name (cst:raw (cst:second form))))

         (package (find-package package-name)))

    (unless package
      (setf package (make-package package-name :use '("COALTON" "COALTON-PRELUDE"))))

    (values package)))


(defun parse-toplevel-form (form program attributes file)
  (declare (type cst:cst form)
           (type program program)
           (type (vector (cons attribute cst:cst)) attributes)
           (type sb-sys::fd-stream file)
           (values boolean &optional))

  ;; Toplevel forms must begin with an atom
  (when (cst:consp (cst:first form))
    (error 'parse-error
           :err (coalton-error
                 (cst:first form) file
                 :message "Malformed toplevel form"
                 :primary-note "unexpected list")))

  (case (cst:raw (cst:first form))
    (coalton:monomorphize
     (vector-push-extend
      (cons
       (parse-monomorhpize form file)
       form)
      attributes)

     (return-from parse-toplevel-form nil))

    (coalton:repr
     (vector-push-extend
      (cons
       (parse-repr form file)
       form)
      attributes)

     (return-from parse-toplevel-form nil))

    (coalton:define
        (let ((define (parse-define form file))

              (monomorphize)
              (monomorphize-form))
          (loop :for (attribute . attribute-form) :across attributes
                :do (etypecase attribute
                      (attribute-repr
                       (error 'parse-error
                              :err (coalton-error
                                    attribute-form file
                                    :message "Invalid target for repr attribute"
                                    :primary-note "repr must be attached to a define-type"
                                    :notes
                                    (list
                                     (make-coalton-error-note
                                      :type :secondary
                                      :span (identifier-src-source (toplevel-define-name define))
                                      :message "when parsing define")))))

                      (attribute-monomorphize
                       (when monomorphize
                         (error 'parse-error
                                :err (coalton-error
                                      attribute-form file
                                      :message "Duplicate monomorphize attribute"
                                      :primary-note "monomorphize attribute here"
                                      :notes
                                      (list
                                       (make-coalton-error-note
                                        :type :secondary
                                        :span (cst:source monomorphize-form)
                                        :message "previous attribute here")
                                       (make-coalton-error-note
                                        :type :secondary
                                        :span (identifier-src-source (toplevel-define-name define))
                                        :message "when parsing define")))))

                       (setf monomorphize attribute)
                       (setf monomorphize-form attribute-form))))

          (setf (fill-pointer attributes) 0)
          (setf (toplevel-define-monomorphize define) monomorphize)
          (push define (program-defines program))
          (return-from parse-toplevel-form t)))

    (coalton:declare
     (let ((declare (parse-declare form file))

           (monomorphize)
           (monomorphize-form))

       (loop :for (attribute . attribute-form) :across attributes
             :do (etypecase attribute
                   (attribute-repr
                    (error 'parse-error
                           :err (coalton-error
                                 attribute-form file
                                 :message "Invalid target for repr attribute"
                                 :primary-note "repr must be attached to a define-type"
                                 :notes
                                 (list
                                  (make-coalton-error-note
                                   :type :secondary
                                   :span (cst:source form)
                                   :message "when parsing declare")))))

                   (attribute-monomorphize
                    (when monomorphize
                      (error 'parse-error
                             :err (coalton-error
                                   attribute-form file
                                   :message "Duplicate monomorphize attribute"
                                   :primary-note "monomorphize attribute here"
                                   :notes
                                   (list
                                    (make-coalton-error-note
                                     :type :secondary
                                     :span (cst:source monomorphize-form)
                                     :message "previous attribute here")
                                    (make-coalton-error-note
                                     :type :secondary
                                     :span (cst:source form)
                                     :message "when parsing declare")))))

                    (setf monomorphize attribute)
                    (setf monomorphize-form attribute-form))))

       (setf (fill-pointer attributes) 0)
       (setf (toplevel-declare-monomorphize declare) monomorphize)
       (push declare (program-declares program))
       (return-from parse-toplevel-form t)))

    (coalton:define-type
        (let* ((type (parse-define-type form file))

               (repr)
               (repr-form))

          (loop :for (attribute . attribute-form) :across attributes
                :do (etypecase attribute
                      (attribute-repr
                       (when repr
                         (error 'parse-error
                                :err (coalton-error
                                      attribute-form file
                                      :message "Duplicate repr atttribute"
                                      :primary-note "repr attribute here"
                                      :notes
                                      (list
                                       (make-coalton-error-note
                                        :type :secondary
                                        :span (cst:source repr-form)
                                        :message "previous attribute here")
                                       (make-coalton-error-note
                                        :type :secondary
                                        :span (identifier-src-source (toplevel-define-type-name type))
                                        :message "when parsing define-type")))))

                       (setf repr attribute)
                       (setf repr-form attribute-form))

                      (attribute-monomorphize
                       (error 'parse-error
                              :err (coalton-error
                                    attribute-form file
                                    :message "Invalid target for monomorphize attribute"
                                    :primary-note "monomorphize must be attached to a define or declare form"
                                    :notes
                                    (list
                                     (make-coalton-error-note
                                      :type :secondary
                                      :span (identifier-src-source (toplevel-define-type-name type))
                                      :message "when parsing define-type"))))))) 

          (setf (fill-pointer attributes) 0)
          (setf (toplevel-define-type-repr type) repr)
          (push type (program-types program))
          (return-from parse-toplevel-form t)))

    (coalton:define-class
        (let ((class (parse-define-class form file)))

          (unless (zerop (length attributes))
            (error 'parse-error
                   :err (coalton-error
                         (cdr (aref attributes 0)) file
                         :message "Invalid attribute for define-class"
                         :primary-note "define-class cannot have attributes"
                         :notes
                         (list
                          (make-coalton-error-note
                           :type :secondary
                           :span (toplevel-define-class-head-src class)
                           :message "while parsing define-class")))))

          (push class (program-classes program))
          (return-from parse-toplevel-form t)))

    (coalton:define-instance
        (let ((instance (parse-define-instance form file)))

          (unless (zerop (length attributes))
            (error 'parse-error
                   :err (coalton-error
                         (cdr (aref attributes 0)) file
                         :message "Invalid attribute for define-instance"
                         :primary-note "define-instance cannot have attributes"
                         :notes
                         (list
                          (make-coalton-error-note
                           :type :secondary
                           :span (toplevel-define-instance-head-src instance)
                           :message "while parsing define-instance")))))
      

          (push instance (program-instances program))
          (return-from parse-toplevel-form t)))

    (t
     (error 'parse-error
            :err (coalton-error
                  (cst:first form) file
                  :message "Invalid toplevel form"
                  :primary-note "unknown toplevel form")))))


(defun parse-define (form file)
  (declare (type cst:cst form)
           (type sb-sys::fd-stream file)
           (values toplevel-define))

  (assert (cst:consp form))

  (let ((name)
        (arguments)
        (docstring)
        (body))

    ;; (define)
    (unless (cst:consp (cst:rest form))
      (error 'parse-error
             :err (coalton-error
                   form file
                   :message "Malformed definition"
                   :primary-note "expected define body")))

    ;; (define x)
    (unless (cst:consp (cst:rest (cst:rest form)))
      (error 'parse-error
             :err (coalton-error
                   form file
                   :message "Malformed definition"
                   :primary-note "expected value")))

    (setf (values name arguments) (parse-argument-list (cst:second form) file))

    (setf (values docstring body) (parse-definition-body (cst:rest (cst:rest form)) form file))

    (make-toplevel-define
     :name name
     :vars arguments
     :body body
     :monomorphize nil
     :source (cst:source form))))

(defun parse-declare (form file)
  (declare (type cst:cst form)
           (type sb-sys::fd-stream file)
           (values toplevel-declare))

  (assert (cst:consp form))

    ;; (declare)
    (unless (cst:consp (cst:rest form))
      (error 'parse-error
             :err (coalton-error
                   form file
                   :message "Malformed declaration"
                   :primary-note "expected body")))

    ;; (declare x)
    (unless (cst:consp (cst:rest (cst:rest form)))
      (error 'parse-error
             :err (coalton-error
                   form file
                   :message "Malformed declaration"
                   :primary-note "expected declared type")))

    ;; (declare x y z)
    (when (cst:consp (cst:rest (cst:rest (cst:rest form))))
      (error 'parse-error
             :err (coalton-error
                   (cst:first (cst:rest (cst:rest (cst:rest form)))) file
                   :message "Malformed declaration"
                   :primary-note "unexpected trailing form")))

    ;; (declare 0.5 x)
    (unless (identifier-p (cst:raw (cst:second form)))
      (error 'parse-error
             :err (coalton-error
                   (cst:second form) file
                   :message "Malformed declaration"
                   :primary-note "expected symbol")))

    (make-toplevel-declare
     :name (make-identifier-src
            :name (cst:raw (cst:second form))
            :source (cst:source (cst:second form)))
     :type (parse-qualified-type (cst:third form) file)
     :monomorphize nil
     :source (cst:source form)))

(defun parse-define-type (form file)
  (declare (type cst:cst form)
           (type sb-sys::fd-stream file)
           (values toplevel-define-type))

  (assert (cst:consp form))

  (let ((name)
        (variables)
        (constructors))
    (declare (type (or null identifier-src) name)
             (type keyword-src-list variables)
             (type constructor-list constructors))

    ;; (define-type)
    (unless (cst:consp (cst:rest form))
      (error 'parse-error
             :err (coalton-error
                   form file
                   :message "Malformed type definition"
                   :primary-note "expected body")))

    (if (cst:atom (cst:second form))
        (progn                          ; (define-type T ...)
          (unless (identifier-p (cst:raw (cst:second form)))
            (error 'parse-error
                   :err (coalton-error
                         (cst:second form) file
                         :message "Malformed type definition"
                         :primary-note "expected symbol")))

          (setf name (make-identifier-src :name (cst:raw (cst:second form))
                                          :source (cst:source form))))

        (progn                          ; (define-type (T ...) ...)
          ;; (define-type ((T) ...) ...)
          (unless (cst:atom (cst:first (cst:second form)))
            (error 'parse-error
                   :err (coalton-error
                         (cst:first (cst:second form)) file
                         :message "Malformed type definition"
                         :primary-note "expected symbol"
                         :help-notes
                         (list
                          (make-coalton-error-help
                           :span (cst:source (cst:second form))
                           :replacement
                           (lambda (existing)
                             (subseq existing 1 (1- (length existing))))
                           :message "remove parentheses")))))

          ;; (define-type (1 ...) ...)
          (unless (identifier-p (cst:raw (cst:first (cst:second form))))
            (error 'parse-error
                   :err (coalton-error
                         (cst:first (cst:second form)) file
                         :message "Malformed type definition"
                         :primary-note "expected symbol")))

          (setf name (make-identifier-src :name (cst:raw (cst:first (cst:second form)))
                                          :source (cst:source (cst:first (cst:second form)))))

          ;; (define-type (T) ...)
          (when (cst:atom (cst:rest (cst:second form)))
            (error 'parse-error
                   :err (coalton-error
                         (cst:second form) file
                         :message "Malformed type definition"
                         :primary-note "nullary types should not have parentheses"
                         :help-notes
                         (list
                          (make-coalton-error-help
                           :span (cst:source (cst:second form))
                           :replacement
                           (lambda (existing)
                             (subseq existing 1 (1- (length existing))))
                           :message "remove unnecessary parentheses")))))

          (loop :for vars := (cst:rest (cst:second form)) :then (cst:rest vars)
                :while (cst:consp vars)
                :do (push (parse-type-variable (cst:first vars) file) variables))))

    (loop :for constructors_ := (cst:nthrest 2 form) :then (cst:rest constructors_)
          :while (cst:consp constructors_)
          :do (push (parse-constructor (cst:first constructors_) form file) constructors))

    (make-toplevel-define-type
     :name name
     :vars variables
     :ctors constructors
     :repr nil
     :source (cst:source form))))

(defun parse-define-class (form file)
  (declare (type cst:cst form)
           (type sb-sys::fd-stream file)
           (values toplevel-define-class))

  (assert (cst:consp form))

  (let ((unparsed-name)
        (unparsed-variables)
        (name)
        (variables)
        (fundeps)
        (predicates)
        (methods))

    ;; (define-class)
    (unless (cst:consp (cst:rest form))
      (error 'parse-error
             :err (coalton-error
                   form file
                   :message "Malformed class definition"
                   :primary-note "expected body")))

    ;; (define-class C)
    (unless (cst:consp (cst:second form))
      (error 'parse-error
             :err (coalton-error
                   (cst:second form) file
                   :message "Malformed class definition"
                   :primary-note "expected class type variable(s)"
                   :help-notes
                   (list
                    (make-coalton-error-help
                     :span (cst:source (cst:second form))
                     :replacement
                     (lambda (existing)
                       (concatenate 'string "(" existing " :a)"))
                     :message "add class type variable `:a`")))))

    (unless (cst:proper-list-p (cst:second form))
      (error 'parse-error
             :err (coalton-error
                   (cst:second form) file
                   :message "Malformed class definition"
                   :primary-note "unexpected dotted list")))

    (multiple-value-bind (left right)
        (util:take-until (lambda (cst)
                           (and (cst:atom cst)
                                (eq (cst:raw cst) 'coalton:=>)))
                         (cst:listify (cst:second form)))

      ;; (=> C ...)
      (when (and (null left) right)
        (error 'parse-error
               :err (coalton-error
                     (cst:first (cst:second form)) file
                     :message "Malformed class definition"
                     :primary-note "unnecessary `=>`"
                     :help-notes
                     (cond
                       ;; If this is the only thing in the list then don't suggest anything
                       ((cst:atom (cst:rest (cst:second form)))
                        nil)
                       ;; If there is nothing to the right of C then emit without list
                       ((cst:atom (cst:rest (cst:rest (cst:second form))))
                        (list
                         (make-coalton-error-help
                          :span (cst:source (cst:second form))
                          :replacement
                          (lambda (existing)
                            (subseq existing 4 (1- (length existing))))
                          :message "remove `=>`")))
                       (t
                        (list
                         (make-coalton-error-help
                          :span (cst:source (cst:second form))
                          :replacement
                          (lambda (existing)
                            (concatenate 'string
                                         (subseq existing 0 1)
                                         (subseq existing 4)))
                          :message "remove `=>`")))))))

      ;; (... =>)
      (when (and left right (null (cdr right)))
        (error 'parse-error
               :err (coalton-error
                     (cst:second form) file
                     :message "Malformed class definition"
                     :primary-note "missing class name")))

      (if (null right)
          ;; No predicates
          (progn
            (setf unparsed-name (first left))
            (setf unparsed-variables (rest left)))

          ;; Some predicates
          (progn
            (setf unparsed-name (second right))
            (setf unparsed-variables (nthcdr 2 right))))

      ;; (define-class ((C) ...))
      (unless (cst:atom unparsed-name)
        (error 'parse-error
               :err (coalton-error
                     unparsed-name file
                     :message "Malformed class definition"
                     :primary-note "unnecessary parentheses"
                     :help-notes
                     (list
                      (make-coalton-error-help
                       :span (cst:source unparsed-name)
                       :replacement
                       (lambda (existing)
                         (subseq existing 1 (1- (length existing))))
                       :message "remove unnecessary parentheses")))))

      (unless (identifier-p (cst:raw unparsed-name))
        (error 'parse-error
               :err (coalton-error
                     unparsed-name file
                     :message "Malformed class definition"
                     :primary-note "expected symbol")))

      (setf name (cst:raw unparsed-name))

      (when (null unparsed-variables)
        (error 'parse-error
               :err (coalton-error
                     unparsed-name file
                     :message "Malformed class definition"
                     :primary-note "expected class type variable(s)"
                     :help-notes
                     (list
                      (make-coalton-error-help
                       :span (cst:source unparsed-name)
                       :replacement
                       (lambda (existing)
                         (if (cst:consp (cst:second form))
                             (concatenate 'string existing " :a")
                             (concatenate 'string "(" existing " :a)")))
                       :message "add class type variable `:a`")))))


      (multiple-value-bind (left right)
          (util:take-until #'cst:consp unparsed-variables)

        (setf variables
              (loop :for var :in left
                    :collect (parse-type-variable var file)))

        (setf fundeps
              (loop :for fundep :in right
                    :collect (parse-fundep fundep file))))

      ;; (... => C ...)
      (when right
        (if (cst:atom (first left))
            ;; (C1 ... => C2 ...)
            (setf predicates (list (parse-predicate left (util:cst-source-range left) file)))

            ;; ((C1 ...) (C2 ...) ... => C3 ...)
            (setf predicates
                  (loop :for pred :in left
                        :collect (parse-predicate (cst:listify pred) (cst:source pred) file)))))

      (setf methods
            (loop :for methods := (cst:rest (cst:rest form)) :then (cst:rest methods)
                  :while (cst:consp methods)
                  :collect (parse-method (cst:first methods) form file)))

       (make-toplevel-define-class
        :name (make-identifier-src
               :name name
               :source (cst:source unparsed-name))
        :vars variables
        :preds predicates
        :fundeps fundeps
        :methods methods
        :source (cst:source form)
        :head-src (cst:source (cst:second form))))))

(defun parse-define-instance (form file)
  (declare (type cst:cst form)
           (type sb-sys::fd-stream file)
           (values toplevel-define-instance))

  (assert (cst:consp form))

  (let ((unparsed-context)
        (context)
        (unparsed-predicate)
        (predicate))

    ;; (define-instance)
    (unless (cst:consp (cst:rest form))
      (error 'parse-error
             :err (coalton-error
                   form file
                   :highlight :end
                   :message "Malformed instance definition"
                   :primary-note "expected an instance head")))

    ;; (define-instance 5)
    (unless (cst:consp (cst:second form))
      (error 'parse-error
             :err (coalton-error
                   (cst:second form) file
                   :message "Malformed instance definition"
                   :primary-note "expected a list")))

    (unless (cst:proper-list-p (cst:second form))
      (error 'parse-error
             :err (coalton-error
                   (cst:second form) file
                   :message "Malformed instance definition"
                   :primary-note "unexpected dotted list")))

    (multiple-value-bind (left right)
        (util:take-until
         (lambda (form)
           (and (cst:atom form)
                (eq (cst:raw form) 'coalton:=>)))
         (cst:listify (cst:second form)))

      (if (null right)
          ;; No context
          (setf unparsed-predicate left)

          ;; Some context
          (progn
            (setf unparsed-predicate (cdr right))
            (setf unparsed-context left)))


      ;; (... =>)
      (when (and left right (null (cdr right)))
        (error 'parse-error
               :err (coalton-error
                     (first right) file
                     :message "Malformed instance head"
                     :primary-note "unexpected `=>`"
                     :help-notes
                     (list
                      (make-coalton-error-help
                       :span (cst:source (first right))
                       :replacement
                       (lambda (existing)
                         (declare (ignore existing))
                         "")
                       :message "remove the `=>`")))))

      ;; (=> ...)
      (when (and (null left) right)
        (error 'parse-error
               :err (coalton-error
                     (first right) file
                     :message "Malformed instance head"
                     :primary-note "unexpected `=>`"
                     :help-notes
                     (list
                      (make-coalton-error-help
                       :span (cst:source (first right))
                       :replacement
                       (lambda (existing)
                         (declare (ignore existing))
                         "")
                       :message "remove the `=>`")))))

      (when unparsed-context
        (if (cst:atom (first unparsed-context))
            (setf context (list (parse-predicate unparsed-context (util:cst-source-range unparsed-context) file)))

            (setf context
                  (loop :for unparsed :in unparsed-context
                        :collect (parse-predicate (cst:listify unparsed) (cst:source unparsed) file)))))

      (setf predicate (parse-predicate unparsed-predicate (util:cst-source-range unparsed-predicate) file))

      (make-toplevel-define-instance
       :context context
       :pred predicate
       :methods (loop :for methods := (cst:rest (cst:rest form)) :then (cst:rest methods)
                      :while (cst:consp methods)
                      :for method := (cst:first methods)
                      :collect (parse-instance-method-definition method (cst:second form) file))
       :source (cst:source form)
       :head-src (cst:source (cst:second form))))))

(defun parse-method (method-form form file)
  (declare (type cst:cst method-form)
           (type sb-sys::fd-stream file)
           (values method-definition))

  ;; m or (m)
  (unless (and (cst:consp method-form)
               (cst:consp (cst:rest method-form)))
    (error 'parse-error
           :err (coalton-error
                 method-form file
                 :message "Malformed method definition"
                 :primary-note "missing method type"
                 :notes
                 (list
                  (make-coalton-error-note
                   :type :secondary
                   :span (cst:source (cst:second form))
                   :message "in this class definition")))))

  ;; (m t ...)
  (when (cst:consp (cst:rest (cst:rest method-form)))
    (error 'parse-error
           :err (coalton-error
                 (cst:first (cst:rest (cst:rest method-form))) file
                 :message "Malformed method definition"
                 :primary-note "unexpected trailing form"
                 :notes
                 (list
                  (make-coalton-error-note
                   :type :secondary
                   :span (cst:source (cst:second form))
                   :message "in this class definition")))))

  ;; (0.5 t ...)
  (unless (and (cst:atom (cst:first method-form))
               (identifier-p (cst:raw (cst:first method-form))))
    (error 'parse-error
           :err (coalton-error
                 (cst:first method-form) file
                 :message "Malformed method definition"
                 :primary-note "expected symbol"
                 :notes
                 (list
                  (make-coalton-error-note
                   :type :secondary
                   :span (cst:source (cst:second form))
                   :message "in this class definition")))))

  (make-method-definition
   :name (make-identifier-src
          :name (cst:raw (cst:first method-form))
          :source (cst:source (cst:first method-form)))
   :type (parse-qualified-type (cst:second method-form) file)
   :source (cst:source method-form)))

(defun parse-type-variable (form file)
  (declare (type cst:cst form)
           (type sb-sys::fd-stream file)
           (values keyword-src &optional))

  (when (cst:consp form)
    (error 'parse-error
           :err (coalton-error
                 form file
                 :message "Invalid type variable"
                 :primary-note "expected keyword symbol")))

  (unless (keywordp (cst:raw form))
    (error 'parse-error
           :err (coalton-error
                 form file
                 :message "Invalid type variable"
                 :primary-note "expected keyword symbol"
                 :help-notes
                 (when (symbolp (cst:raw form))
                   (list
                    (make-coalton-error-help
                     :span (cst:source form)
                     :replacement
                     (lambda (existing)
                       (concatenate 'string ":" existing))
                     :message "add `:` to symbol"))))))

  (make-keyword-src
   :name (cst:raw form)
   :source (cst:source form)))

(defun parse-constructor (form enclosing-form file)
  (declare (type cst:cst form enclosing-form)
           (type sb-sys::fd-stream file)
           (values constructor))

  (let ((unparsed-name)
        (unparsed-fields))

    (if (cst:atom form)
        (setf unparsed-name form)
        (progn
          (setf unparsed-name (cst:first form))
          (setf unparsed-fields (cst:listify (cst:rest form)))))

    (unless (cst:atom unparsed-name)
      (error 'parse-error
             :err (coalton-error
                   unparsed-name file
                   :message "Malformed constructor"
                   :primary-note "expected symbol"
                   :notes
                   (list
                    (make-coalton-error-note
                     :type :secondary
                     :span (cst:source (cst:second enclosing-form))
                     :message "in this type definition")))))

    (unless (identifier-p (cst:raw unparsed-name))
      (error 'parse-error
             :err (coalton-error
                   unparsed-name file
                   :message "Malformed constructor"
                   :primary-note "expected symbol"
                   :notes
                   (list
                    (make-coalton-error-note
                     :type :secondary
                     :span (cst:source (cst:second enclosing-form))
                     :message "in this type definition")))))

    (make-constructor
     :name (make-identifier-src
            :name (cst:raw unparsed-name)
            :source (cst:source unparsed-name)) 
     :fields (loop :for field :in unparsed-fields
                   :collect (parse-type field file))
     :source (cst:source form))))


(defun parse-argument-list (form file)
  (declare (type cst:cst form)
           (type sb-sys::fd-stream file)
           (values identifier-src identifier-src-list))

  ;; (define x 1)
  (when (cst:atom form)
    (return-from parse-argument-list (values (parse-identifier form file) nil)))

  ;; (define (0.5 x y) ...)
  (unless (identifier-p (cst:raw (cst:first form)))
    (error 'parse-error
           :err (coalton-error
                 (cst:first form) file
                 :message "Malformed function definition"
                 :primary-note "expected symbol")))

  ;; (define (f) ...)
  (when (cst:atom (cst:rest form))
    (error 'parse-error
           :err (coalton-error
                 form file
                 :message "Malformed function definition"
                 :primary-note "expected 1 or more arguments")))

  (values
   (make-identifier-src
    :name (cst:raw (cst:first form))
    :source (cst:source form))

   (loop :for vars := (cst:rest form) :then (cst:rest vars)
         :while (cst:consp vars)
         :collect (parse-identifier (cst:first vars) file))))

(defun parse-identifier (form file)
  (declare (type cst:cst form)
           (type sb-sys::fd-stream file)
           (values identifier-src))

  (unless (cst:atom form)
    (error 'parse-error
           :err (coalton-error
                 form file
                 :message "Unexpected list"
                 :primary-note "expected an identifier")))

  (unless (identifier-p (cst:raw form))
    (error 'parse-error
           :err (coalton-error
                 form file
                 :message "Unexpected form"
                 :primary-note "expected an identifier")))

  (make-identifier-src
   :name (cst:raw form)
   :source (cst:source form)))

(defun parse-definition-body (form enclosing-form file)
  (declare (type cst:cst form)
           (type cst:cst enclosing-form)
           (type sb-sys::fd-stream file)
           (values (or null string) node-body))

  (let ((docstring)
        (unparsed-body))

    ;; (define y 2)
    (when (cst:atom (cst:rest form))
      (return-from parse-definition-body (values nil (parse-body form enclosing-form file))))

    (if (and (cst:atom (cst:first form))
             (stringp (cst:raw (cst:first form))))
        (progn
          (setf docstring (cst:raw (cst:first form)))
          (setf unparsed-body (cst:rest form)))

        (setf unparsed-body form))

    (values docstring (parse-body unparsed-body enclosing-form file))))

(defun parse-instance-method-definition (form parent-form file)
  (declare (type cst:cst form)
           (type cst:cst parent-form)
           (type sb-sys::fd-stream file)
           (values instance-method-definition))

  (let* ((name)
         (arguments)
         (context-note
           (make-coalton-error-note
            :type :secondary
            :span (cst:source parent-form)
            :message "when parsing instance")))

    (unless (cst:consp form)
      (error 'parse-error
             :err (coalton-error
                   form file
                   :message "Malformed method definition"
                   :primary-note "expected list"
                   :notes (list context-note))))

    (unless (cst:proper-list-p form)
      (error 'parse-error
             :err (coalton-error
                   form file
                   :message "Malformed method definition"
                   :primary-note "unexpected dotted list"
                   :notes (list context-note))))

    (unless (and (cst:atom (cst:first form))
                 (eq (cst:raw (cst:first form)) 'coalton:define))
      (error 'parse-error
             :err (coalton-error
                   (cst:first form) file
                   :message "Malformed method definition"
                   :primary-note "expected method definition"
                   :notes (list context-note))))

    (unless (cst:consp (cst:rest form))
      (error 'parse-error
             :err (coalton-error
                   form file
                   :message "Malformed method definition"
                   :primary-note "expected definition name"
                   :notes (list context-note))))


    (setf (values name arguments) (parse-argument-list (cst:second form) file))

    (make-instance-method-definition
     :name name
     :vars arguments
     :body (parse-body (cst:rest (cst:rest form)) form file)
     :source (cst:source form))))

(defun parse-fundep (form file)
  (declare (type cst:cst form)
           (type sb-sys::fd-stream file)
           (values fundep))

  (unless (cst:consp form)
    (error 'parse-error
           :err (coalton-error
                 form file
                 :message "Malformed functional dependency"
                 :primary-note "expected a list")))

  (unless (cst:proper-list-p form)
    (error 'parse-error
           :err (coalton-error
                 form file
                 :message "Malformed functional dependency"
                 :primary-note "unexpected dotted list")))

  (multiple-value-bind (left right)
      (util:take-until
       (lambda (cst)
         (and (cst:atom cst)
              (eq (cst:raw cst) 'coalton:->)))
       (cst:listify form))

    (unless left
      (error 'parse-error
             :err (coalton-error
                   form file
                   :message "Malformed functional dependency"
                   :primary-note "expected one or more type variables")))

    (unless (cdr right)
      (error 'parse-error
             :err (coalton-error
                   form file
                   :highlight :end
                   :message "Malformed functional dependency"
                   :primary-note "expected one ore more type variables")))

    (make-fundep
     :left (loop :for var :in left
                 :collect (parse-type-variable var file))
     :right (loop :for var :in (cdr right)
                  :collect (parse-type-variable var file))
     :source (cst:source form))))


(defun parse-monomorhpize (form file)
  (declare (type cst:cst form)
           (type sb-sys::fd-stream file)
           (values attribute-monomorphize))

  (assert (cst:consp form))

  (when (cst:consp (cst:rest form))
    (error 'parse-error
           :err (coalton-error
                 form file
                 :message "Malformed monomophize attribute"
                 :primary-note "unexpected form")))

  (make-attribute-monomorphize
   :source (cst:source form)))

(defun parse-repr (form file)
  (declare (type cst:cst form)
           (type sb-sys::fd-stream file)
           (values attribute-repr))

  (assert (cst:consp form))

  (unless (cst:consp (cst:rest form))
    (error 'parse-error
           :err (coalton-error
                 form file
                 :highlight :end
                 :message "Malformed repr attribute"
                 :primary-note "expected keyword symbol")))

  (let ((type (parse-type-variable (cst:second form) file)))
    (if (eq (keyword-src-name type) :native)

        (progn ;; :native reprs must have an argument
          (unless (cst:consp (cst:rest (cst:rest form)))
            (error 'parse-error
                   :err (coalton-error
                         form file
                         :highlight :end
                         :message "Malformed repr :native attribute"
                         :primary-note "expected a lisp type")))

          (when (cst:consp (cst:rest (cst:rest (cst:rest form))))
            (error 'parse-error
                   :err (coalton-error
                         (cst:first (cst:rest (cst:rest (cst:rest form)))) file
                         :message "Malformed repr :native attribute"
                         :primary-note "unexpected form")))

          (make-attribute-repr
           :type type
           :arg (cst:third form)
           :source (cst:source form)))

        (progn ;; other reprs do not have an argument
          (when (cst:consp (cst:rest (cst:rest form)))
            (error 'parse-error
                   :err (coalton-error
                         (cst:first (cst:rest (cst:rest form))) file
                         :message "Malformed repr attribute"
                         :primary-note "unexpected form")))

          (case (keyword-src-name type)
            (:lisp nil)
            (:transparent nil)
            (:enum nil)
            (t
             (error 'parse-error
                    :err (coalton-error
                          (cst:second form) file
                          :message "Unknown repr attribute"
                          :primary-note "expected one of :lisp, :transparent, :enum, or :native"))))

          (make-attribute-repr
           :type type
           :arg nil
           :source (cst:source form))))))