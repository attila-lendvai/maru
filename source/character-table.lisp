(in-package :maru.eval)

(defconstant %char-print    (ash 1 0))
(defconstant %char-blank    (ash 1 1))
(defconstant %char-alpha    (ash 1 3))
(defconstant %char-digit10  (ash 1 4))
(defconstant %char-digit16  (ash 1 5))
(defconstant %char-letter   (ash 1 6))

(defparameter +character-table+
  (coerce (vector
  #|  00 nul |# 0
  #|  01 soh |# 0
  #|  02 stx |# 0
  #|  03 etx |# 0
  #|  04 eot |# 0
  #|  05 enq |# 0
  #|  06 ack |# 0
  #|  07 bel |# 0
  #|  08 bs  |# 0
  #|  09 ht  |# 0
  #|  0a nl  |# (+ %char-print %char-blank)
  #|  0b vt  |# 0
  #|  0c np  |# (+ %char-print %char-blank)
  #|  0d cr  |# (+ %char-print %char-blank)
  #|  0e so  |# 0
  #|  0f si  |# 0
  #|  10 dle |# 0
  #|  11 dc1 |# 0
  #|  12 dc2 |# 0
  #|  13 dc3 |# 0
  #|  14 dc4 |# 0
  #|  15 nak |# 0
  #|  16 syn |# 0
  #|  17 etb |# 0
  #|  18 can |# 0
  #|  19 em  |# 0
  #|  1a sub |# 0
  #|  1b esc |# 0
  #|  1c fs  |# 0
  #|  1d gs  |# 0
  #|  1e rs  |# 0
  #|  1f us  |# 0
  #|  20 sp  |# (+ %char-print %char-blank)
  #|  21  !  |# (+ %char-print %char-letter)
  #|  22  "  |# (+ %char-print %char-print)
  #|  23  #  |# (+ %char-print %char-letter)
  #|  24  $  |# (+ %char-print %char-letter)
  #|  25  %  |# (+ %char-print %char-letter)
  #|  26  &  |# (+ %char-print %char-letter)
  #|  27  '  |# %char-print
  #|  28  (  |# %char-print
  #|  29  )  |# %char-print
  #|  2a  *  |# (+ %char-print %char-letter)
  #|  2b  +  |# (+ %char-print %char-letter)
  #|  2c     |# (+ %char-print %char-letter)
  #|  2d  -  |# (+ %char-print %char-letter)
  #|  2e  .  |# (+ %char-print %char-letter)
  #|  2f  /  |# (+ %char-print %char-letter)
  #|  30  0  |# (+ %char-print %char-digit10 %char-digit16)
  #|  31  1  |# (+ %char-print %char-digit10 %char-digit16)
  #|  32  2  |# (+ %char-print %char-digit10 %char-digit16)
  #|  33  3  |# (+ %char-print %char-digit10 %char-digit16)
  #|  34  4  |# (+ %char-print %char-digit10 %char-digit16)
  #|  35  5  |# (+ %char-print %char-digit10 %char-digit16)
  #|  36  6  |# (+ %char-print %char-digit10 %char-digit16)
  #|  37  7  |# (+ %char-print %char-digit10 %char-digit16)
  #|  38  8  |# (+ %char-print %char-digit10 %char-digit16)
  #|  39  9  |# (+ %char-print %char-digit10 %char-digit16)
  #|  3a  :  |# (+ %char-print %char-letter)
  #|  3b  ;  |# %char-print
  #|  3c  <  |# (+ %char-print %char-letter)
  #|  3d  =  |# (+ %char-print %char-letter)
  #|  3e  >  |# (+ %char-print %char-letter)
  #|  3f  ?  |# (+ %char-print %char-letter)
  #|  40  @  |# (+ %char-print %char-letter)
  #|  41  A  |# (+ %char-print %char-letter %char-alpha %char-digit16)
  #|  42  B  |# (+ %char-print %char-letter %char-alpha %char-digit16)
  #|  43  C  |# (+ %char-print %char-letter %char-alpha %char-digit16)
  #|  44  D  |# (+ %char-print %char-letter %char-alpha %char-digit16)
  #|  45  E  |# (+ %char-print %char-letter %char-alpha %char-digit16)
  #|  46  F  |# (+ %char-print %char-letter %char-alpha %char-digit16)
  #|  47  G  |# (+ %char-print %char-letter %char-alpha)
  #|  48  H  |# (+ %char-print %char-letter %char-alpha)
  #|  49  I  |# (+ %char-print %char-letter %char-alpha)
  #|  4a  J  |# (+ %char-print %char-letter %char-alpha)
  #|  4b  K  |# (+ %char-print %char-letter %char-alpha)
  #|  4c  L  |# (+ %char-print %char-letter %char-alpha)
  #|  4d  M  |# (+ %char-print %char-letter %char-alpha)
  #|  4e  N  |# (+ %char-print %char-letter %char-alpha)
  #|  4f  O  |# (+ %char-print %char-letter %char-alpha)
  #|  50  P  |# (+ %char-print %char-letter %char-alpha)
  #|  51  Q  |# (+ %char-print %char-letter %char-alpha)
  #|  52  R  |# (+ %char-print %char-letter %char-alpha)
  #|  53  S  |# (+ %char-print %char-letter %char-alpha)
  #|  54  T  |# (+ %char-print %char-letter %char-alpha)
  #|  55  U  |# (+ %char-print %char-letter %char-alpha)
  #|  56  V  |# (+ %char-print %char-letter %char-alpha)
  #|  57  W  |# (+ %char-print %char-letter %char-alpha)
  #|  58  X  |# (+ %char-print %char-letter %char-alpha)
  #|  59  Y  |# (+ %char-print %char-letter %char-alpha)
  #|  5a  Z  |# (+ %char-print %char-letter %char-alpha)
  #|  5b  [  |# %char-print
  #|  5c  \  |# (+ %char-print %char-letter)
  #|  5d  ]  |# %char-print
  #|  5e  ^  |# (+ %char-print %char-letter)
  #|  5f  _  |# (+ %char-print %char-letter)
  #|  60  `  |# %char-print
  #|  61  a  |# (+ %char-print %char-letter %char-alpha %char-digit16)
  #|  62  b  |# (+ %char-print %char-letter %char-alpha %char-digit16)
  #|  63  c  |# (+ %char-print %char-letter %char-alpha %char-digit16)
  #|  64  d  |# (+ %char-print %char-letter %char-alpha %char-digit16)
  #|  65  e  |# (+ %char-print %char-letter %char-alpha %char-digit16)
  #|  66  f  |# (+ %char-print %char-letter %char-alpha %char-digit16)
  #|  67  g  |# (+ %char-print %char-letter %char-alpha)
  #|  68  h  |# (+ %char-print %char-letter %char-alpha)
  #|  69  i  |# (+ %char-print %char-letter %char-alpha)
  #|  6a  j  |# (+ %char-print %char-letter %char-alpha)
  #|  6b  k  |# (+ %char-print %char-letter %char-alpha)
  #|  6c  l  |# (+ %char-print %char-letter %char-alpha)
  #|  6d  m  |# (+ %char-print %char-letter %char-alpha)
  #|  6e  n  |# (+ %char-print %char-letter %char-alpha)
  #|  6f  o  |# (+ %char-print %char-letter %char-alpha)
  #|  70  p  |# (+ %char-print %char-letter %char-alpha)
  #|  71  q  |# (+ %char-print %char-letter %char-alpha)
  #|  72  r  |# (+ %char-print %char-letter %char-alpha)
  #|  73  s  |# (+ %char-print %char-letter %char-alpha)
  #|  74  t  |# (+ %char-print %char-letter %char-alpha)
  #|  75  u  |# (+ %char-print %char-letter %char-alpha)
  #|  76  v  |# (+ %char-print %char-letter %char-alpha)
  #|  77  w  |# (+ %char-print %char-letter %char-alpha)
  #|  78  x  |# (+ %char-print %char-letter %char-alpha)
  #|  79  y  |# (+ %char-print %char-letter %char-alpha)
  #|  7a  z  |# (+ %char-print %char-letter %char-alpha)
  #|  7b  {  |# %char-print
  #|  7c  |  |# (+ %char-print %char-letter)
  #|  7d  }  |# %char-print
  #|  7e  ~  |# (+ %char-print %char-letter)
  #|  7f del |# 0)
          '(vector (unsigned-byte 8))))

(macrolet ((frob (name flag)
             `(defun ,name (c)
                (and (typep c 'character)
                     (let ((code (char-code c)))
                       (and (<= 0 code 127)
                            (/= 0 (boole boole-and (aref +character-table+ code) ,flag))))))))
  (frob is-print? %char-print)
  (frob is-alpha? %char-alpha)
  (frob is-digit10? %char-digit10)
  (frob is-digit16? %char-digit16)
  (frob is-letter? %char-letter))
