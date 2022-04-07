(:!
 _G "concat"
 (lambda (:rest args)
   (local len (length args))
   (local inner)
   (set inner (lambda (i)
                (cond (nil? (: args i))
                    (cond (>= i (*lua-subtraction* len 1)) (: args len)
                          true (inner (*lua-addition* i 1)))
                    true (block
                             (local removed (car (: args i)))
                           (:! args i (cdr (: args i)))
                           (cons removed (inner i))))))
   (cond (= len 0)
         nil
         true (inner 1))))

(:! *macros-table* 'defmacro
  (lambda (name args :rest body)
    (list ':! '*macros-table* (list 'quote name)
          (concat (list 'lambda args) (array-to-list body)))))

(defmacro defun (name args :rest body)
    (list ':! '_G (: name "value")
          (concat (list 'lambda args) (array-to-list body))))

(defun cadr (lst)
  (car (cdr lst)))

(defun cadar (lst)
  (car (cdr (car lst))))

(defun caddr (lst)
  (car (cdr (cdr lst))))

(defun cadddr (lst)
  (car (cdr (cdr (cdr lst)))))

(defun caar (lst)
  (car (car lst)))


(defmacro if (pred true-branch :rest else-branch)
  (cond (> (length else-branch) 0) (list 'cond pred true-branch 'true (cons 'block (array-to-list else-branch)))
        true (list 'cond pred true-branch)))

(defmacro or (:rest preds)
  (cond (= (length preds) 0) 'true
        (= (length preds) 1) (: preds 1)
        true (list 'cond
                   (: preds 1) 'true
                   'true (cons 'or (cdr (array-to-list preds))))))

(defmacro and (:rest preds)
  (cond (= (length preds) 0) 'true
        (= (length preds) 1) (: preds 1)
        true (list 'cond
                   (: preds 1) (cons 'and (cdr (array-to-list preds)))
                   'true 'false)))

; this is slow
(defmacro quasiquote (form)
  (local quasiquote-list)
  (local quasiquote-element)
  (local unquote-spliced)
  (local rest)
  (set quasiquote-list
       (lambda (lst)
         (cond (nil? lst) lst
               (and (list? lst) (= (car lst) 'unquote)) (cdr lst)
               (and (list? lst) (list? (car lst)) (= (caar lst) 'unquote-splice))
                   (block
                       (set unquote-spliced (cadar lst))
                     (set rest (cdr lst))
                     nil)
               true (cons (quasiquote-element (car lst)) (quasiquote-list (cdr lst))))))
  (set quasiquote-element
       (lambda (sexp)
         (list 'quasiquote sexp)))
  (local lst
         (cond (and (list? form) (= (car form) 'unquote)) (cadr form)
               (and (list? form) (= (car form) 'unquote-splice)) (assert false "`,@ is not allowed")
               (list? form) (cons 'list (quasiquote-list form))
               true (list 'quote form)))
  (if (not (nil? unquote-spliced))
      (list 'concat lst unquote-spliced (list 'quasiquote rest))
      lst))

(defmacro for (loop-expr :rest body)
  (local start-of-loop (gensym "start-of-loop"))
  (local end-of-loop (gensym "start-of-loop"))
  (local loop-variable (car loop-expr))
  (local body-lst (array-to-list body))
  (local for-in-list
         (lambda ()
           (local lst-variable (gensym "lst"))
           (local loop-lst (caddr loop-expr))
           `(block
              (local ,loop-variable)
              (local ,lst-variable ,loop-lst)
              (label ,start-of-loop)
              (if (nil? ,lst-variable)
                  (goto ,end-of-loop))
              (set ,loop-variable (car ,lst-variable))
              (block
                  ,@body-lst)
              (set ,lst-variable (cdr ,lst-variable))
              (goto ,start-of-loop)
              (label ,end-of-loop)
              nil)))
  (local for-from-to
         (lambda (from to)
           (local to-variable (gensym "to"))
           `(block
              (local ,loop-variable ,from)
              (local ,to-variable ,to)
              (label ,start-of-loop)
              (if (> ,loop-variable ,to-variable)
                  (goto ,end-of-loop))
              (block
                  ,@body-lst)
              (set ,loop-variable (*lua-addition* ,loop-variable 1))
              (goto ,start-of-loop)
              (label ,end-of-loop)
              nil)))
  (assert (>= (length loop-expr) 3))
  (cond (= (cadr loop-expr) ':in) (for-in-list)
        (= (cadr loop-expr) ':from) (for-from-to (caddr loop-expr) (cadddr loop-expr))
        (= (cadr loop-expr) ':to) (for-from-to 1 (caddr loop-expr))
        true (assert false "do not know how to expand for of this form")))

(defun + (:rest nums)
  (local result 0)
  (for (i :from 1 (length nums))
       (set result (*lua-addition* result (: nums i))))
  result)

(defun - (first :rest rest)
  (if (= (length rest) 0)
      (*lua-subtraction* 0 first)
      (for (i :from 1 (length rest))
           (set first (*lua-subtraction* first (: rest i))))
      first))

(defun * (:rest nums)
  (local result 1)
  (for (i :from 1 (length nums))
       (set result (*lua-multiplication* result (: nums i))))
  result)

(defun / (first :rest rest)
  (*lua-division* first (apply * rest)))

(defun and (:rest preds)
  (local result true)
  (for (i :from 1 (length preds))
       (set result (and result (: preds i))))
  result)

(defun or (:rest preds)
  (local result false)
  (for (i :from 1 (length preds))
       (set result (or result (: preds i))))
  result)

(defun foldr (proc init lst)
  (if (nil? lst)
      init
      (proc (car lst) (foldr proc init (cdr lst)))))

(defun foldl (proc init lst)
  (for (elem :in lst)
       (set init (proc elem init)))
  init)

(defun map (proc lst)
  (foldr (lambda (a b) (cons (proc a) b))
         '() lst))

; seems to trigger a luajit bug where caar stops working very oddly
;(block
;  (local proc-symbols '("car" "cdr"))
;  (for (i :to 5)
;       (local new-proc-symbols '())
;       (for (proc-symbol :in proc-symbols)
;            (local without-first ((: string "sub") proc-symbol 2))
;            (local new-car (concat-strings "ca" without-first))
;            (:! _G new-car (lambda (a) (car ((: _G proc-symbol) a))))
;            (local new-cdr (concat-strings "cd" without-first))
;            (:! _G new-cdr (lambda (a) (cdr ((: _G proc-symbol) a))))
;            (set new-proc-symbols (concat (list new-car new-cdr) new-proc-symbols)))
;       (set proc-symbols new-proc-symbols)))

(defmacro macro-expand (form)
  `((lambda () (apply (: *macros-table* ',(car form)) ',(cdr form)))))