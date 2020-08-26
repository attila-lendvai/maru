;;; -*- mode: lisp; coding: us-ascii -*-

(define-function is_blank (c)   (or      ( = ?   c)                     ; sp
                                         ( = ?\t c)                     ; ht
                                         ( = ?\n c)                     ; nl
                                         ( = ?\v c)                     ; vt
                                         ( = ?\f c)                     ; ff
                                         ( = ?\r c)))                   ; cr

(define-function is_digit10 (c)     (and (<= ?0  c) (<= c ?9)))         ; 0 1 2 3 4 5 6 7 8 9

(define-function is_digit16 (c) (or (and (<= ?0  c) (<= c ?9))          ; 0 1 2 3 4 5 6 7 8 9
                                    (and (<= ?a  c) (<= c ?f))          ; a b c d e f
                                    (and (<= ?A  c) (<= c ?F))))        ; A B C D E F

(define-function is_alpha (c)   (or (and (<= ?a  c) (<= c ?z))          ; a b c d e f g h i j k l m n o p q r s t u v w x y z
                                    (and (<= ?A  c) (<= c ?Z))))        ; A B C D E F G H I J K L M N O P Q R S T U V W X Y Z

(define-function is_letter (c)  (or      ( = ?!  c)                     ; !
                                    (and (<= ?#  c) (<= c ?&))          ; # $ % &
                                    (and (<= ?*  c) (<= c ?/))          ; * + , - . /
                                         ( = ?:  c)                     ; :
                                    (and (<= ?<  c) (<= c ?Z))          ; < = > ?  @ A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
                                         ( = ?\\ c)                     ; \
                                         ( = ?^  c)                     ; ^
                                         ( = ?_  c)                     ; _
                                    (and (<= ?a  c) (<= c ?z))          ; a b c d e f g h i j k l m n o p q r s t u v w x y z
                                         ( = ?|  c)                     ; |
                                         ( = ?~  c)))                   ; ~

(define-function is_octal (c)           (and (<= ?0 c) (<= c ?7)))

(define-function is_hexadecimal (c)     (or (and (<= ?0 c) (<= c ?9))
                                            (and (<= ?a c) (<= c ?f))
                                            (and (<= ?A c) (<= c ?F))))

(define-function digit_value (c)
  (cond
    ((and (<= ?0 c) (<= c ?9))  (- c ?0))
    ((and (<= ?a c) (<= c ?z))  (- c (- ?a 10)))
    ((and (<= ?A c) (<= c ?Z))  (- c (- ?A 10)))
    (else                       (fatal1 "illegal digit in character escape: %c" c))))

(define k/read) ; forward

(define-function read_char (c stream)
  (if (= ?\\ c)
      (let ()
        (set c (libc/fgetc stream))
        (cond
          ((= c ?a)                     ?\a)
          ((= c ?b)                     ?\b)
          ((= c ?f)                     ?\f)
          ((= c ?n)                     ?\n)
          ((= c ?r)                     ?\r)
          ((= c ?t)                     ?\t)
          ((= c ?v)                     ?\v)
          ((= c ?u)                     (let ((a (libc/fgetc stream))
                                              (b (libc/fgetc stream))
                                              (c (libc/fgetc stream))
                                              (d (libc/fgetc stream)))
                                          (or (and (is_hexadecimal a)
                                                   (is_hexadecimal b)
                                                   (is_hexadecimal c)
                                                   (is_hexadecimal d))
                                              (k/error "illegal character escape"))
                                          (+ (<< (digit_value a) 24)
                                             (+ (<< (digit_value b) 16)
                                                (+ (<< (digit_value c)  8)
                                                   (digit_value d))))))
          ((= c ?x)                     (let ((x 0))
                                          (when (is_hexadecimal (set c (libc/fgetc stream)))
                                            (set x (digit_value c))
                                            (if (is_hexadecimal (set c (libc/fgetc stream)))
                                                (let ()
                                                  (set x (+ (* x 16) (digit_value c)))
                                                  (set c (libc/fgetc stream)))
                                              (k/error "illegal character escape")))
                                          (libc/ungetc c stream)
                                          x))
          ((and (<= ?0 c) (<= c ?7))    (let ((x (digit_value c)))
                                          (when (is_octal (set c (libc/fgetc stream)))
                                            (set x (+ (* x 8) (digit_value c)))
                                            (if (is_octal (set c (libc/fgetc stream)))
                                                (let ()
                                                  (set x (+ (* x 8) (digit_value c)))
                                                  (set c (libc/fgetc stream)))
                                              (k/error "illegal character escape")))
                                          (libc/ungetc c stream)
                                          x))
          (else                 (if (or (is_alpha c) (is_digit10 c))
                                    (fatal1 "illegal character escape: \\%c" c)
                                  c))))
    c))

(define-function read_number (c stream)
  (gc/let* ((buf (new-<buffer>)))
    (let ((negative?	false)
          (base		10))
      (if (= ?- c)
          (set negative? true)
        (buffer/append buf c))
      (while (is_digit10 (set c (libc/fgetc stream)))
        (buffer/append buf c))
      ;; a 0x prefix?
      (when (and (= ?x c)
                 (= 1 (buffer/position buf)))
        (set base 16)
        (buffer/append buf c)
        (while (is_digit16 (set c (libc/fgetc stream)))
          (buffer/append buf c)))
      (libc/ungetc c stream)
      (let* ((str	(buffer/contents buf))
             (endptr	str)
             (result	(libc/strtoul str (address-of endptr) base)))
        (when (and (= -1 result)
                   (or (not negative?)
                       (not (= 0 (libc/strcmp str "1")))))
          (fatal1 "invalid number in source code, libc/strtoul failed for '%s' (printed without the sign here)" str))
        (new-<long> (if negative? (- result) result))))))

(define-function read_symbol (c stream)
  (gc/let* ((buf (new-<buffer>)))
    (while (or (is_letter c) (is_digit10 c))
      (buffer/append buf c)
      (set c (libc/fgetc stream)))
    (libc/ungetc c stream)
    (k/intern (buffer/contents buf))))

(define-function read_string (c stream)
  (gc/let* ((buf (new-<buffer>)))
    (while (!= ?\" (set c (libc/fgetc stream)))
      (set c (read_char c stream))
      (when (= libc/EOF c)
        (k/error "unterminated string literal"))
      (buffer/append buf c))
    (new-<string>-from-cstring (buffer/contents buf))))

(define-function read_list (delim stream)
  (let* ((head (new-<pair> () ()))
         (tail head)
         (elt  ()))
    (gc/protect (head elt)
      (while (and (!= k/+done+ (set elt (k/read stream)))
                  (!= symbol/dot elt))
        (set elt (new-<pair> elt ()))
        (set tail (put/tail tail elt)))
      (and (= symbol/dot elt) (put/tail tail (k/read stream))))
    (let ((c (libc/fgetc stream)))
      (if (= delim c)
          (get/tail head)
        (fatal1 "missing closing '%c' delimiter while reading list" delim)))))

(define-function read_quote (prefix stream)
  (gc/let* ((qobj (k/read stream)))
    (when (= k/+done+ qobj)
      (k/error "EOF while reading quoted literal"))
    (set qobj (new-<pair> qobj ()))
    (set qobj (new-<pair> prefix qobj))
    qobj))

(set k/read (lambda (stream)
  (while 1
    (let ((c (libc/fgetc stream)))
      (cond
        ((is_blank c)   ())
        ((= ?? c)       (return (new-<long> (read_char (libc/fgetc stream) stream))))
        ((= ?- c)       (return (if (is_digit10 (libc/ungetc (libc/fgetc stream) stream))
                                    (read_number c stream)
                                    (read_symbol c stream))))
        ((= ?\' c)      (return (read_quote symbol/quote stream)))
        ((= ?\` c)      (return (read_quote symbol/quasiquote stream)))
        ((= ?\, c)      (return (let ((d (libc/fgetc stream)))
                                  (if (= ?@ d)
                                      (read_quote symbol/unquote_splicing stream)
                                    (libc/ungetc d stream)
                                    (read_quote symbol/unquote stream)))))
        ((is_letter c)  (return (read_symbol c stream)))
        ((= ?\( c)      (return (read_list ?\) stream)))        ((= ?\) c)      (return (let () (libc/ungetc c stream) k/+done+)))
        ((= ?\[ c)      (return (read_list ?\] stream)))        ((= ?\] c)      (return (let () (libc/ungetc c stream) k/+done+)))
        ((= ?\{ c)      (return (read_list ?\} stream)))        ((= ?\} c)      (return (let () (libc/ungetc c stream) k/+done+)))
        ((is_digit10 c) (return (read_number c stream)))
        ((= ?\; c)      (while (and (!= ?\n (set c (libc/fgetc stream)))
                                    (!= ?\r c)
                                    (!= libc/EOF c))))
        ((= ?\" c)      (return (read_string c stream)))
        ((= c libc/EOF) (if (libc/feof stream)
                            (return k/+done+)
                          (fatal "error while reading from libc stream")))
        (else           (fatal1 "illegal character: %c" c))))))
)
