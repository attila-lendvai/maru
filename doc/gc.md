# Maru's GC

The current GC is a simple, singly-linked list of chunks that get
marked and sweeped. When more memory is needed, the a new chunk is
`malloc`ed and chained at the end.

A chunk can be opaque, meaning that the payload doesn't contain any
further pointers to other obejcts. Conversely, a non-opaque chunk's
payload may only contain OOPs.

## TODO

I want to emit full heap objects (e.g. the literal strings in code),
into a static, read-only memory segment. In that setup the compiled
code only needs to deal with one kind of string representation (no
more C strings, only full `<string>` objects, it's just that some of
them are in the/a static memory segment).

Split `<header>` into `<chunk-header>` and `<object-header>`. The
chunk's type should be used to mark whether the chunk's payload
contains raw data, or a full object with an <object-header>.

```
(define-record <chunk-header> ()
  (next size [payload type and flags packed into one word]))

(define-record <object-header> ()
  (descriptor (when-at-expand feature/object-canary canary)))

(define-record <object-descriptor> ()
  (type-id
  [description for the GC about which word contains an OOP to be walked]
  ))
```

Or maybe instead of the `<object-descriptor>` its should just point to
the `<type>` object itself?

Chunk type examples:
 - a simple-array of bytes (of chunk-size elements)
 - object (i.e. the chunk payload begins with an `<object-header>`)
 - a boxed float
 - a boxed word
 - etc.
