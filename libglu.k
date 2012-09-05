(require "dlopen.k")

(define-function init-libglu ()
  (init-dlopen)
  (define libglu (dlopen "libGLU"))
  (define gluPerspective	(subr "gluPerspective"	"dddd"))
  )
