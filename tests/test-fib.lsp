(defun fib (a)
  (cond (= a 1) 1
        (= a 2) 1
        true (+ (fib (- a 1)) (fib (- a 2)))))
(fib 30)