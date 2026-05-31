;;; -*- mode: lisp; coding: us-ascii -*-

(define-function variable-value (env name)
  ;;(safety 3 (assert (= 0 (unbox <long> (<env>-level env)))) "variable-value called with non-toplevel env "env)
  (aif (defined? name env)
      (<variable>-value it)
    (error "variable-value: '"name"' is not defined in env "env)))

(define-function maybe-variable-value (env name)
  (awhen (defined? name env)
    (<variable>-value it)))

(define-function set-variable-value (env name value)
  ;;(safety 3 (assert (= 0 (unbox <long> (<env>-level env)))) "set-variable-value called with non-toplevel env "env)
  ;;(safety 3 (or (symbol? name) (fatal "set-variable-value called with a non-symbol name")))
  ;;(debug (platform/diag-print "set-variable-value for " (string (symbol->string name)) "\n"))
  (aif (defined? name env)
      (set (<variable>-value it) value)
    (environment-define env name value)
    value))
