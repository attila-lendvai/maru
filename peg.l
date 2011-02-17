(define-class <peg-parser> <parser> ())
(define-selector $gen_cola) ;; forward
(define-selector $start) ;; forward
(define-selector $definition) ;; forward
(define-selector $expression) ;; forward
(define-selector $sequence) ;; forward
(define-selector $predicate) ;; forward
(define-selector $conversion) ;; forward
(define-selector $repetition) ;; forward
(define-selector $atom) ;; forward
(define-selector $llist) ;; forward
(define-selector $rlist) ;; forward
(define-selector $relement) ;; forward
(define-selector $variable) ;; forward
(define-selector $variable2) ;; forward
(define-selector $symbol) ;; forward
(define-selector $symchar) ;; forward
(define-selector $class) ;; forward
(define-selector $string) ;; forward
(define-selector $character) ;; forward
(define-selector $char) ;; forward
(define-selector $identifier) ;; forward
(define-selector $letter) ;; forward
(define-selector $digit) ;; forward
(define-selector $dot) ;; forward
(define-selector $rbrace) ;; forward
(define-selector $lbrace) ;; forward
(define-selector $rparen) ;; forward
(define-selector $lparen) ;; forward
(define-selector $star) ;; forward
(define-selector $plus) ;; forward
(define-selector $query) ;; forward
(define-selector $at) ;; forward
(define-selector $dollar) ;; forward
(define-selector $dollardbl) ;; forward
(define-selector $quotesgl) ;; forward
(define-selector $arrow) ;; forward
(define-selector $colondbl) ;; forward
(define-selector $colon) ;; forward
(define-selector $ampersand) ;; forward
(define-selector $pling) ;; forward
(define-selector $bar) ;; forward
(define-selector $space) ;; forward
(define-selector $comment) ;; forward
(define-selector $eol) ;; forward
(define-selector $blank) ;; forward
(define-selector $equals) ;; forward
(define-method $gen_cola <peg-parser> ()
  (let (e)
    (let ((pos (<parser-stream>-position self.source)))
      (or
        (and
          (set self.result (parser-stream-next self.source))
          (let () (set e self.result) 't)
          (let () (set self.result e) 't)
          )
        (parser-stream-fail self.source pos))
      )
    )
  )
(define-method $start <peg-parser> ()
  ($definition self)
  )
(define-method $definition <peg-parser> ()
  (let (e id)
    (let ((pos (<parser-stream>-position self.source)))
      (or
        (and
          ($space self)
          ($identifier self)
          (let () (set id self.result) 't)
          ($equals self)
          ($expression self)
          (let () (set e self.result) 't)
          (and (= 59 (parser-stream-peek self.source)) (set self.result (parser-stream-next self.source)))
          (let ((_list_ (group)))
            (group-append _list_ 'rule)
            (group-append _list_ id)
            (group-append _list_ e)
            (set self.result _list_))
          )
        (parser-stream-fail self.source pos))
      )
    )
  )
(define-method $expression <peg-parser> ()
  (let (s e s)
    (let ((pos (<parser-stream>-position self.source)))
      (or
        (and
          ($sequence self)
          (let () (set s self.result) 't)
          (let ((_list_ (group)))
            (and
              (let ((pos (<parser-stream>-position self.source)))
                (or
                  (and
                    ($bar self)
                    ($expression self)
                    (let () (set e self.result) 't)
                    (let ((_list_ (group)))
                      (group-append _list_ 'match-first)
                      (group-append _list_ s)
                      (group-append _list_ e)
                      (set self.result _list_))
                    (let () (set s self.result) 't)
                    )
                  (parser-stream-fail self.source pos))
                )
              (group-append _list_ self.result))
            (set self.result _list_))
          (let () (set self.result s) 't)
          )
        (parser-stream-fail self.source pos))
      )
    )
  )
(define-method $sequence <peg-parser> ()
  (let (p e p)
    (let ((pos (<parser-stream>-position self.source)))
      (or
        (and
          ($predicate self)
          (let () (set p self.result) 't)
          (let ((_list_ (group)))
            (and
              (let ((pos (<parser-stream>-position self.source)))
                (or
                  (and
                    ($sequence self)
                    (let () (set e self.result) 't)
                    (let ((_list_ (group)))
                      (group-append _list_ 'match-both)
                      (group-append _list_ p)
                      (group-append _list_ e)
                      (set self.result _list_))
                    (let () (set p self.result) 't)
                    )
                  (parser-stream-fail self.source pos))
                )
              (group-append _list_ self.result))
            (set self.result _list_))
          (let () (set self.result p) 't)
          )
        (parser-stream-fail self.source pos))
      )
    )
  )
(define-method $predicate <peg-parser> ()
  (let (e e)
    (or
      (let ((pos (<parser-stream>-position self.source)))
        (or
          (and
            ($pling self)
            ($conversion self)
            (let () (set e self.result) 't)
            (let ((_list_ (group)))
              (group-append _list_ 'peek-not)
              (group-append _list_ e)
              (set self.result _list_))
            )
          (parser-stream-fail self.source pos))
        )
      (let ((pos (<parser-stream>-position self.source)))
        (or
          (and
            ($ampersand self)
            ($conversion self)
            (let () (set e self.result) 't)
            (let ((_list_ (group)))
              (group-append _list_ 'peek-for)
              (group-append _list_ e)
              (set self.result _list_))
            )
          (parser-stream-fail self.source pos))
        )
      ($conversion self)
      )
    )
  )
(define-method $conversion <peg-parser> ()
  (let (e e e e)
    (let ((pos (<parser-stream>-position self.source)))
      (or
        (and
          ($repetition self)
          (let () (set e self.result) 't)
          (let ((_list_ (group)))
            (while
              (or
                (let ((pos (<parser-stream>-position self.source)))
                  (or
                    (and
                      ($at self)
                      (let ((_list_ (group)))
                        (group-append _list_ 'make-span)
                        (group-append _list_ e)
                        (set self.result _list_))
                      (let () (set e self.result) 't)
                      )
                    (parser-stream-fail self.source pos))
                  )
                (let ((pos (<parser-stream>-position self.source)))
                  (or
                    (and
                      ($dollardbl self)
                      (let ((_list_ (group)))
                        (group-append _list_ 'make-symbol)
                        (group-append _list_ e)
                        (set self.result _list_))
                      (let () (set e self.result) 't)
                      )
                    (parser-stream-fail self.source pos))
                  )
                (let ((pos (<parser-stream>-position self.source)))
                  (or
                    (and
                      ($dollar self)
                      (let ((_list_ (group)))
                        (group-append _list_ 'make-string)
                        (group-append _list_ e)
                        (set self.result _list_))
                      (let () (set e self.result) 't)
                      )
                    (parser-stream-fail self.source pos))
                  )
                )
              (group-append _list_ self.result))
            (set self.result _list_))
          (let () (set self.result e) 't)
          )
        (parser-stream-fail self.source pos))
      )
    )
  )
(define-method $repetition <peg-parser> ()
  (let (e e e e)
    (let ((pos (<parser-stream>-position self.source)))
      (or
        (and
          ($atom self)
          (let () (set e self.result) 't)
          (let ((_list_ (group)))
            (and
              (or
                (let ((pos (<parser-stream>-position self.source)))
                  (or
                    (and
                      ($query self)
                      (let ((_list_ (group)))
                        (group-append _list_ 'match-zero-one)
                        (group-append _list_ e)
                        (set self.result _list_))
                      (let () (set e self.result) 't)
                      )
                    (parser-stream-fail self.source pos))
                  )
                (let ((pos (<parser-stream>-position self.source)))
                  (or
                    (and
                      ($star self)
                      (let ((_list_ (group)))
                        (group-append _list_ 'match-zero-more)
                        (group-append _list_ e)
                        (set self.result _list_))
                      (let () (set e self.result) 't)
                      )
                    (parser-stream-fail self.source pos))
                  )
                (let ((pos (<parser-stream>-position self.source)))
                  (or
                    (and
                      ($plus self)
                      (let ((_list_ (group)))
                        (group-append _list_ 'match-one-more)
                        (group-append _list_ e)
                        (set self.result _list_))
                      (let () (set e self.result) 't)
                      )
                    (parser-stream-fail self.source pos))
                  )
                )
              (group-append _list_ self.result))
            (set self.result _list_))
          (let () (set self.result e) 't)
          )
        (parser-stream-fail self.source pos))
      )
    )
  )
(define-method $atom <peg-parser> ()
  (let (i e e e e e e e e e e)
    (or
      (let ((pos (<parser-stream>-position self.source)))
        (or
          (and
            ($lbrace self)
            ($expression self)
            (let () (set e self.result) 't)
            ($rbrace self)
            (let () (set self.result e) 't)
            )
          (parser-stream-fail self.source pos))
        )
      (let ((pos (<parser-stream>-position self.source)))
        (or
          (and
            ($character self)
            (let () (set e self.result) 't)
            (let ((_list_ (group)))
              (group-append _list_ 'match-object)
              (group-append _list_ e)
              (set self.result _list_))
            )
          (parser-stream-fail self.source pos))
        )
      (let ((pos (<parser-stream>-position self.source)))
        (or
          (and
            ($string self)
            (let () (set e self.result) 't)
            (let ((_list_ (group)))
              (group-append _list_ 'match-string)
              (group-append _list_ e)
              (set self.result _list_))
            )
          (parser-stream-fail self.source pos))
        )
      (let ((pos (<parser-stream>-position self.source)))
        (or
          (and
            ($class self)
            (let () (set e self.result) 't)
            (let ((_list_ (group)))
              (group-append _list_ 'match-class)
              (group-append _list_ e)
              (set self.result _list_))
            )
          (parser-stream-fail self.source pos))
        )
      (let ((pos (<parser-stream>-position self.source)))
        (or
          (and
            ($identifier self)
            (let () (set e self.result) 't)
            (let ((_list_ (group)))
              (group-append _list_ 'match-rule)
              (group-append _list_ e)
              (set self.result _list_))
            )
          (parser-stream-fail self.source pos))
        )
      (let ((pos (<parser-stream>-position self.source)))
        (or
          (and
            ($dot self)
            (let ((_list_ (group)))
              (group-append _list_ 'match-any)
              (set self.result _list_))
            )
          (parser-stream-fail self.source pos))
        )
      (let ((pos (<parser-stream>-position self.source)))
        (or
          (and
            ($arrow self)
            (or
              (let ((pos (<parser-stream>-position self.source)))
                (or
                  (and
                    ($identifier self)
                    (let () (set e self.result) 't)
                    (let ((_list_ (group)))
                      (group-append _list_ 'result-variable)
                      (group-append _list_ e)
                      (set self.result _list_))
                    )
                  (parser-stream-fail self.source pos))
                )
              (let ((pos (<parser-stream>-position self.source)))
                (or
                  (and
                    ($character self)
                    (let () (set e self.result) 't)
                    (let ((_list_ (group)))
                      (group-append _list_ 'result-object)
                      (group-append _list_ e)
                      (set self.result _list_))
                    )
                  (parser-stream-fail self.source pos))
                )
              (let ((pos (<parser-stream>-position self.source)))
                (or
                  (and
                    ($string self)
                    (let () (set e self.result) 't)
                    (let ((_list_ (group)))
                      (group-append _list_ 'result-string)
                      (group-append _list_ e)
                      (set self.result _list_))
                    )
                  (parser-stream-fail self.source pos))
                )
              (let ((pos (<parser-stream>-position self.source)))
                (or
                  (and
                    ($rlist self)
                    (let () (set e self.result) 't)
                    (let ((_list_ (group)))
                      (group-append _list_ 'result-list)
                      (group-append-all _list_ e)
                      (set self.result _list_))
                    )
                  (parser-stream-fail self.source pos))
                )
              )
            )
          (parser-stream-fail self.source pos))
        )
      (let ((pos (<parser-stream>-position self.source)))
        (or
          (and
            ($llist self)
            (let () (set e self.result) 't)
            (let ((_list_ (group)))
              (group-append _list_ 'match-list)
              (group-append _list_ e)
              (set self.result _list_))
            )
          (parser-stream-fail self.source pos))
        )
      (let ((pos (<parser-stream>-position self.source)))
        (or
          (and
            ($colon self)
            ($identifier self)
            (let () (set i self.result) 't)
            (let ((_list_ (group)))
              (group-append _list_ 'assign-result)
              (group-append _list_ i)
              (set self.result _list_))
            )
          (parser-stream-fail self.source pos))
        )
      )
    )
  )
(define-method $llist <peg-parser> ()
  (let (e)
    (let ((pos (<parser-stream>-position self.source)))
      (or
        (and
          ($lparen self)
          ($expression self)
          (let () (set e self.result) 't)
          ($rparen self)
          (let () (set self.result e) 't)
          )
        (parser-stream-fail self.source pos))
      )
    )
  )
(define-method $rlist <peg-parser> ()
  (let (e)
    (let ((pos (<parser-stream>-position self.source)))
      (or
        (and
          ($lparen self)
          (let ((_list_ (group)))
            (while
              ($relement self)
              (group-append _list_ self.result))
            (set self.result _list_))
          (let () (set e self.result) 't)
          ($rparen self)
          (let () (set self.result e) 't)
          )
        (parser-stream-fail self.source pos))
      )
    )
  )
(define-method $relement <peg-parser> ()
  (let (e e e)
    (or
      (let ((pos (<parser-stream>-position self.source)))
        (or
          (and
            ($symbol self)
            (let () (set e self.result) 't)
            (let ((_list_ (group)))
              (group-append _list_ 'result-list-symbol)
              (group-append _list_ e)
              (set self.result _list_))
            )
          (parser-stream-fail self.source pos))
        )
      (let ((pos (<parser-stream>-position self.source)))
        (or
          (and
            ($variable2 self)
            (let () (set e self.result) 't)
            (let ((_list_ (group)))
              (group-append _list_ 'result-list-variable-splicing)
              (group-append _list_ e)
              (set self.result _list_))
            )
          (parser-stream-fail self.source pos))
        )
      (let ((pos (<parser-stream>-position self.source)))
        (or
          (and
            ($variable self)
            (let () (set e self.result) 't)
            (let ((_list_ (group)))
              (group-append _list_ 'result-list-variable)
              (group-append _list_ e)
              (set self.result _list_))
            )
          (parser-stream-fail self.source pos))
        )
      )
    )
  )
(define-method $variable <peg-parser> ()
  (let ((pos (<parser-stream>-position self.source)))
    (or
      (and
        ($colon self)
        ($identifier self)
        )
      (parser-stream-fail self.source pos))
    )
  )
(define-method $variable2 <peg-parser> ()
  (let ((pos (<parser-stream>-position self.source)))
    (or
      (and
        ($colondbl self)
        ($identifier self)
        )
      (parser-stream-fail self.source pos))
    )
  )
(define-method $symbol <peg-parser> ()
  (let (id)
    (let ((pos (<parser-stream>-position self.source)))
      (or
        (and
          (and
            (let ((pos (<parser-stream>-position self.source)))
              (and
                (let ((pos (<parser-stream>-position self.source)))
                  (or
                    (and
                      ($symchar self)
                      (let ((_list_ (group)))
                        (while
                          (or
                            ($symchar self)
                            ($digit self)
                            )
                          (group-append _list_ self.result))
                        (set self.result _list_))
                      )
                    (parser-stream-fail self.source pos))
                  )
                (set self.result (group-from-to pos (<parser-stream>-position self.source))))
              )
            (set self.result (string->symbol (group->string self.result))))
          (let () (set id self.result) 't)
          ($space self)
          (let () (set self.result id) 't)
          )
        (parser-stream-fail self.source pos))
      )
    )
  )
(define-method $symchar <peg-parser> ()
  (set self.result (parser-stream-match-class self.source "!#$%&*+,-/<=>@ABCDEFGHIJKLMNOPQRSTUVWXYZ^_abcdefghijklmnopqrstuvwxyz|~"))
  )
(define-method $class <peg-parser> ()
  (let (s)
    (let ((pos (<parser-stream>-position self.source)))
      (or
        (and
          (and (= 91 (parser-stream-peek self.source)) (set self.result (parser-stream-next self.source)))
          (and
            (let ((_list_ (group)))
              (while
                (let ((pos (<parser-stream>-position self.source)))
                  (or
                    (and
                      (let ((pos (<parser-stream>-position self.source)))
                        (if
                          (and (= 93 (parser-stream-peek self.source)) (set self.result (parser-stream-next self.source)))
                          (parser-stream-fail self.source pos)
                          't)
                        )
                      ($char self)
                      )
                    (parser-stream-fail self.source pos))
                  )
                (group-append _list_ self.result))
              (set self.result _list_))
            (set self.result (group->string self.result)))
          (let () (set s self.result) 't)
          (and (= 93 (parser-stream-peek self.source)) (set self.result (parser-stream-next self.source)))
          ($space self)
          (let () (set self.result s) 't)
          )
        (parser-stream-fail self.source pos))
      )
    )
  )
(define-method $string <peg-parser> ()
  (let (s)
    (let ((pos (<parser-stream>-position self.source)))
      (or
        (and
          (and (= 34 (parser-stream-peek self.source)) (set self.result (parser-stream-next self.source)))
          (and
            (let ((_list_ (group)))
              (while
                (let ((pos (<parser-stream>-position self.source)))
                  (or
                    (and
                      (let ((pos (<parser-stream>-position self.source)))
                        (if
                          (and (= 34 (parser-stream-peek self.source)) (set self.result (parser-stream-next self.source)))
                          (parser-stream-fail self.source pos)
                          't)
                        )
                      ($char self)
                      )
                    (parser-stream-fail self.source pos))
                  )
                (group-append _list_ self.result))
              (set self.result _list_))
            (set self.result (group->string self.result)))
          (let () (set s self.result) 't)
          (and (= 34 (parser-stream-peek self.source)) (set self.result (parser-stream-next self.source)))
          ($space self)
          (let () (set self.result s) 't)
          )
        (parser-stream-fail self.source pos))
      )
    )
  )
(define-method $character <peg-parser> ()
  (let (c)
    (let ((pos (<parser-stream>-position self.source)))
      (or
        (and
          (and (= 39 (parser-stream-peek self.source)) (set self.result (parser-stream-next self.source)))
          ($char self)
          (let () (set c self.result) 't)
          (and (= 39 (parser-stream-peek self.source)) (set self.result (parser-stream-next self.source)))
          ($space self)
          (let () (set self.result c) 't)
          )
        (parser-stream-fail self.source pos))
      )
    )
  )
(define-method $char <peg-parser> ()
  (or
    (let ((pos (<parser-stream>-position self.source)))
      (or
        (and
          (and (= 92 (parser-stream-peek self.source)) (set self.result (parser-stream-next self.source)))
          (or
            (let ((pos (<parser-stream>-position self.source)))
              (or
                (and
                  (and (= 116 (parser-stream-peek self.source)) (set self.result (parser-stream-next self.source)))
                  (let () (set self.result 9) 't)
                  )
                (parser-stream-fail self.source pos))
              )
            (let ((pos (<parser-stream>-position self.source)))
              (or
                (and
                  (and (= 110 (parser-stream-peek self.source)) (set self.result (parser-stream-next self.source)))
                  (let () (set self.result 10) 't)
                  )
                (parser-stream-fail self.source pos))
              )
            (let ((pos (<parser-stream>-position self.source)))
              (or
                (and
                  (and (= 114 (parser-stream-peek self.source)) (set self.result (parser-stream-next self.source)))
                  (let () (set self.result 13) 't)
                  )
                (parser-stream-fail self.source pos))
              )
            (let ((pos (<parser-stream>-position self.source)))
              (or
                (and
                  (and (= 34 (parser-stream-peek self.source)) (set self.result (parser-stream-next self.source)))
                  (let () (set self.result 34) 't)
                  )
                (parser-stream-fail self.source pos))
              )
            (let ((pos (<parser-stream>-position self.source)))
              (or
                (and
                  (and (= 39 (parser-stream-peek self.source)) (set self.result (parser-stream-next self.source)))
                  (let () (set self.result 39) 't)
                  )
                (parser-stream-fail self.source pos))
              )
            (let ((pos (<parser-stream>-position self.source)))
              (or
                (and
                  (and (= 92 (parser-stream-peek self.source)) (set self.result (parser-stream-next self.source)))
                  (let () (set self.result 92) 't)
                  )
                (parser-stream-fail self.source pos))
              )
            (set self.result (parser-stream-next self.source))
            )
          )
        (parser-stream-fail self.source pos))
      )
    (set self.result (parser-stream-next self.source))
    )
  )
(define-method $identifier <peg-parser> ()
  (let (id)
    (let ((pos (<parser-stream>-position self.source)))
      (or
        (and
          (and
            (let ((pos (<parser-stream>-position self.source)))
              (and
                (let ((pos (<parser-stream>-position self.source)))
                  (or
                    (and
                      ($letter self)
                      (let ((_list_ (group)))
                        (while
                          (or
                            ($letter self)
                            ($digit self)
                            )
                          (group-append _list_ self.result))
                        (set self.result _list_))
                      )
                    (parser-stream-fail self.source pos))
                  )
                (set self.result (group-from-to pos (<parser-stream>-position self.source))))
              )
            (set self.result (string->symbol (group->string self.result))))
          (let () (set id self.result) 't)
          ($space self)
          (let () (set self.result id) 't)
          )
        (parser-stream-fail self.source pos))
      )
    )
  )
(define-method $letter <peg-parser> ()
  (set self.result (parser-stream-match-class self.source "ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz"))
  )
(define-method $digit <peg-parser> ()
  (set self.result (parser-stream-match-class self.source "0123456789"))
  )
(define-method $dot <peg-parser> ()
  (let ((pos (<parser-stream>-position self.source)))
    (or
      (and
        (and (= 46 (parser-stream-peek self.source)) (set self.result (parser-stream-next self.source)))
        ($space self)
        )
      (parser-stream-fail self.source pos))
    )
  )
(define-method $rbrace <peg-parser> ()
  (let ((pos (<parser-stream>-position self.source)))
    (or
      (and
        (and (= 125 (parser-stream-peek self.source)) (set self.result (parser-stream-next self.source)))
        ($space self)
        )
      (parser-stream-fail self.source pos))
    )
  )
(define-method $lbrace <peg-parser> ()
  (let ((pos (<parser-stream>-position self.source)))
    (or
      (and
        (and (= 123 (parser-stream-peek self.source)) (set self.result (parser-stream-next self.source)))
        ($space self)
        )
      (parser-stream-fail self.source pos))
    )
  )
(define-method $rparen <peg-parser> ()
  (let ((pos (<parser-stream>-position self.source)))
    (or
      (and
        (and (= 41 (parser-stream-peek self.source)) (set self.result (parser-stream-next self.source)))
        ($space self)
        )
      (parser-stream-fail self.source pos))
    )
  )
(define-method $lparen <peg-parser> ()
  (let ((pos (<parser-stream>-position self.source)))
    (or
      (and
        (and (= 40 (parser-stream-peek self.source)) (set self.result (parser-stream-next self.source)))
        ($space self)
        )
      (parser-stream-fail self.source pos))
    )
  )
(define-method $star <peg-parser> ()
  (let ((pos (<parser-stream>-position self.source)))
    (or
      (and
        (and (= 42 (parser-stream-peek self.source)) (set self.result (parser-stream-next self.source)))
        ($space self)
        )
      (parser-stream-fail self.source pos))
    )
  )
(define-method $plus <peg-parser> ()
  (let ((pos (<parser-stream>-position self.source)))
    (or
      (and
        (and (= 43 (parser-stream-peek self.source)) (set self.result (parser-stream-next self.source)))
        ($space self)
        )
      (parser-stream-fail self.source pos))
    )
  )
(define-method $query <peg-parser> ()
  (let ((pos (<parser-stream>-position self.source)))
    (or
      (and
        (and (= 63 (parser-stream-peek self.source)) (set self.result (parser-stream-next self.source)))
        ($space self)
        )
      (parser-stream-fail self.source pos))
    )
  )
(define-method $at <peg-parser> ()
  (let ((pos (<parser-stream>-position self.source)))
    (or
      (and
        (and (= 64 (parser-stream-peek self.source)) (set self.result (parser-stream-next self.source)))
        ($space self)
        )
      (parser-stream-fail self.source pos))
    )
  )
(define-method $dollar <peg-parser> ()
  (let ((pos (<parser-stream>-position self.source)))
    (or
      (and
        (and (= 36 (parser-stream-peek self.source)) (set self.result (parser-stream-next self.source)))
        ($space self)
        )
      (parser-stream-fail self.source pos))
    )
  )
(define-method $dollardbl <peg-parser> ()
  (let ((pos (<parser-stream>-position self.source)))
    (or
      (and
        (set self.result (parser-stream-match-string self.source "$$"))
        ($space self)
        )
      (parser-stream-fail self.source pos))
    )
  )
(define-method $quotesgl <peg-parser> ()
  (let ((pos (<parser-stream>-position self.source)))
    (or
      (and
        (and (= 39 (parser-stream-peek self.source)) (set self.result (parser-stream-next self.source)))
        ($space self)
        )
      (parser-stream-fail self.source pos))
    )
  )
(define-method $arrow <peg-parser> ()
  (let ((pos (<parser-stream>-position self.source)))
    (or
      (and
        (set self.result (parser-stream-match-string self.source "->"))
        ($space self)
        )
      (parser-stream-fail self.source pos))
    )
  )
(define-method $colondbl <peg-parser> ()
  (let ((pos (<parser-stream>-position self.source)))
    (or
      (and
        (set self.result (parser-stream-match-string self.source "::"))
        ($space self)
        )
      (parser-stream-fail self.source pos))
    )
  )
(define-method $colon <peg-parser> ()
  (let ((pos (<parser-stream>-position self.source)))
    (or
      (and
        (and (= 58 (parser-stream-peek self.source)) (set self.result (parser-stream-next self.source)))
        ($space self)
        )
      (parser-stream-fail self.source pos))
    )
  )
(define-method $ampersand <peg-parser> ()
  (let ((pos (<parser-stream>-position self.source)))
    (or
      (and
        (and (= 38 (parser-stream-peek self.source)) (set self.result (parser-stream-next self.source)))
        ($space self)
        )
      (parser-stream-fail self.source pos))
    )
  )
(define-method $pling <peg-parser> ()
  (let ((pos (<parser-stream>-position self.source)))
    (or
      (and
        (and (= 33 (parser-stream-peek self.source)) (set self.result (parser-stream-next self.source)))
        ($space self)
        )
      (parser-stream-fail self.source pos))
    )
  )
(define-method $bar <peg-parser> ()
  (let ((pos (<parser-stream>-position self.source)))
    (or
      (and
        (and (= 124 (parser-stream-peek self.source)) (set self.result (parser-stream-next self.source)))
        ($space self)
        )
      (parser-stream-fail self.source pos))
    )
  )
(define-method $space <peg-parser> ()
  (let ((_list_ (group)))
    (while
      (or
        ($blank self)
        ($eol self)
        ($comment self)
        )
      (group-append _list_ self.result))
    (set self.result _list_))
  )
(define-method $comment <peg-parser> ()
  (let ((pos (<parser-stream>-position self.source)))
    (or
      (and
        (and (= 35 (parser-stream-peek self.source)) (set self.result (parser-stream-next self.source)))
        (let ((_list_ (group)))
          (while
            (let ((pos (<parser-stream>-position self.source)))
              (or
                (and
                  (let ((pos (<parser-stream>-position self.source)))
                    (if
                      ($eol self)
                      (parser-stream-fail self.source pos)
                      't)
                    )
                  (set self.result (parser-stream-next self.source))
                  )
                (parser-stream-fail self.source pos))
              )
            (group-append _list_ self.result))
          (set self.result _list_))
        )
      (parser-stream-fail self.source pos))
    )
  )
(define-method $eol <peg-parser> ()
  (or
    (let ((pos (<parser-stream>-position self.source)))
      (or
        (and
          (and (= 10 (parser-stream-peek self.source)) (set self.result (parser-stream-next self.source)))
          (let ((_list_ (group)))
            (while
              (and (= 13 (parser-stream-peek self.source)) (set self.result (parser-stream-next self.source)))
              (group-append _list_ self.result))
            (set self.result _list_))
          )
        (parser-stream-fail self.source pos))
      )
    (let ((pos (<parser-stream>-position self.source)))
      (or
        (and
          (and (= 13 (parser-stream-peek self.source)) (set self.result (parser-stream-next self.source)))
          (let ((_list_ (group)))
            (while
              (and (= 10 (parser-stream-peek self.source)) (set self.result (parser-stream-next self.source)))
              (group-append _list_ self.result))
            (set self.result _list_))
          )
        (parser-stream-fail self.source pos))
      )
    )
  )
(define-method $blank <peg-parser> ()
  (set self.result (parser-stream-match-class self.source "	 "))
  )
(define-method $equals <peg-parser> ()
  (let ((pos (<parser-stream>-position self.source)))
    (or
      (and
        (and (= 61 (parser-stream-peek self.source)) (set self.result (parser-stream-next self.source)))
        ($space self)
        )
      (parser-stream-fail self.source pos))
    )
  )
