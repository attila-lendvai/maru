// -*- c-basic-offset: 2 -*-
/*; -*- mode: c; coding: us-ascii -*- */

/* The C implementation of the maru.10 VM.
 *
 * This program is the bottom of maru's bootstrap chain: it animates the
 * lisp sources of the maru.10 stage (boot.l, its type system, its
 * compiler, its platform layer). All of that is lisp, and the lisp is
 * deliberately not part of this branch: it is loaded from a maru.10
 * checkout. See doc/agent/maru-10-c99.txt.
 *
 * Two invariants shape this file:
 *
 *  - The object layout must match the host's source/types.l, because
 *    the lisp that this VM runs reaches these objects through accessor
 *    forms that expand to literal slot offsets.
 *
 *  - The C functions mirror the shape of their lisp counterparts
 *    (source/evaluator/{eval,vm-functions,reader,printer}.l), function
 *    by function, so that the two can be read side by side.
 */

#define _DEFAULT_SOURCE 1

#include <assert.h>
#include <errno.h>
#include <signal.h>
#include <stdarg.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>

union Object;
typedef union Object *oop;

typedef oop (*imp_t)(oop args, oop ctx);

#define GC_APP_HEADER	int type;

#if defined(LIB_GC)
# include "libgc.c"
#else
# include "gc.c"
#endif
#include "buffer.c"

#define	nil	((oop)0)

/*;
;;; types
;;;
;;; The ids mirror the allocation order of the host's source/types.l.
;;; They are a host-internal contract: source/types.l maps them to the
;;; slave's own ids (%type-id-map/host->slave). The host-only ones
;;; (<subr>) come last, outside of the mapped range.
 */

enum {
  Type			= 1,
  Record		= 2,
  ImmediateType		= 3,	/* ids 3 and 4 are the two <type> subclasses */
  BoxedType		= 4,	/* that source/types.l defines first */
  Data			= 5,
  Undefined		= 6,
  Long			= 7,
  Fixed			= 8,
  Symbol		= 9,
  Array			= 10,
  MemoryBlock		= 11,
  String		= 12,
  Expr			= 13,
  Form			= 14,
  Variable		= 15,
  Env			= 16,
  Context		= 17,
  Pair			= 18,
  TargetFunction	= 19,
  LowerCell		= 20
};

struct Data		{ };			/* raw bytes, never traced */
struct Long		{ long bits; };		/* unused: longs are immediate */
struct String		{ oop size, elements; };	/* elements: <data> */
struct Symbol		{ oop name; };			/* name: <string> */
struct Pair		{ oop head, tail, source; };	/* +host source */
struct Array		{ oop size, elements; };	/* elements: <data> */
struct MemoryBlock	{ oop size, elements; };
struct Expr		{ oop parameters, body, env, ctx, name; };
struct Form		{ oop function, symbol; };
struct Fixed		{ oop function; };

struct Variable		{ oop name, value, env, index; };
struct Env		{ oop parent, level, offset, bindings, stable, name; };
struct Context		{ oop home, env, bindings, callee; };
struct TargetFunction	{ oop program_code, name; };
struct LowerCell	{ void *word; };

union Object {
  struct Data		Data;
  struct Long		Long;
  struct String		String;
  struct Symbol		Symbol;
  struct Pair		Pair;
  struct Array		Array;
  struct MemoryBlock	MemoryBlock;
  struct Expr		Expr;
  struct Form		Form;
  struct Fixed		Fixed;
  struct Variable	Variable;
  struct Env		Env;
  struct Context	Context;
  struct TargetFunction	TargetFunction;
  struct LowerCell	LowerCell;
};

#define setType(OBJ, TYPE)		(ptr2hdr(OBJ)->type= (TYPE))

static int getType(oop obj)		{ return obj ? (((uintptr_t)obj & 1) ? Long : ptr2hdr(obj)->type) : Undefined; }

#define is(TYPE, OBJ)			((OBJ) && (TYPE == getType(OBJ)))

static void fatal(char *reason, ...);

#if defined(NDEBUG)
# define checkType(OBJ, TYPE) OBJ
#else
# define checkType(OBJ, TYPE) _checkType(OBJ, TYPE, #TYPE, __FILE__, __LINE__)
  static inline oop _checkType(oop obj, int type, char *name, char *file, int line)
  {
    if (obj && !((uintptr_t)obj & 1) && !ptr2hdr(obj)->used) {
      fatal("%s:%i: attempt to access dead object %s (%p, allocated at %s:%ld, size %ld)",
	    file, line, name, obj, GC_file(obj), GC_line(obj), (long)GC_size(obj));
    }
    if (!is(type, obj))						fatal("%s:%i: typecheck failed for %s (%i != %i)\n", file, line, name, type, getType(obj));
    return obj;
  }
#endif

#define get(OBJ, TYPE, FIELD)		(checkType(OBJ, TYPE)->TYPE.FIELD)
#define set(OBJ, TYPE, FIELD, VALUE)	(checkType(OBJ, TYPE)->TYPE.FIELD= (VALUE))

/*;
;;; heap
*/

static oop _newBits(int type, size_t size, const char *file, int line)
{
  oop obj= GC_malloc_atomic(size);
  GC_stamp(obj, file, line, 0);
  setType(obj, type);
  return obj;
}

static oop _newOops(int type, size_t size, const char *file, int line)
{
  oop obj= GC_malloc(size);
  GC_stamp(obj, file, line, 0);
  setType(obj, type);
  return obj;
}

#define	newDataSized(SIZE)	_newBits(Data, (SIZE), __FILE__, __LINE__)
#define	newOops(TYPE)		_newOops(TYPE, sizeof(struct TYPE), __FILE__, __LINE__)

static oop newData(size_t len)			{ return newDataSized(len); }

/*; longs are immediates: (n << 1) | 1, so () is the well known word 0 */
#define	longTagBits	1
#define	longTagMask	(((long)1 << longTagBits) - 1)

static int isLong(oop obj)	{ return 0 != ((uintptr_t)obj & longTagMask); }

static oop newLong(long val)
{
  long tagged= (val << longTagBits) | longTagMask;
  if ((tagged >> longTagBits) != val) fatal("integer out of range: %ld", val);
  return (oop)tagged;
}

static long getLong(oop obj)	{ return (long)obj >> longTagBits; }

#define	isPair(OBJ)	is(Pair, (OBJ))

static oop car(oop obj)		{ return isPair(obj) ? get(obj, Pair,head) : nil; }
static oop cdr(oop obj)		{ return isPair(obj) ? get(obj, Pair,tail) : nil; }


/*;
;;; strings
;;;
;;; <string> is a record of (size elements): size is a boxed <long>, and
;;; elements is a <data> blob of bytes. The blob is always kept NUL
;;; terminated and up to date at [size], so that C can use it directly.
 */

static oop newStringN(const char *bytes, size_t len)
{
  oop elements= newData(len + 1);			GC_PROTECT(elements);
  oop obj= newOops(String);				GC_PROTECT(obj);
  memcpy((char *)elements, bytes, len);
  set(obj, String,size, newLong(len));
  set(obj, String,elements, elements);
  GC_UNPROTECT(obj);  GC_UNPROTECT(elements);
  return obj;
}

static oop newString(const char *cstr)	{ return newStringN(cstr, strlen(cstr)); }

static size_t stringLength(oop string)	{ return getLong(get(string, String,size)); }

static char *stringBytes(oop string)	{ return (char *)get(string, String,elements); }

/* a NUL terminated view of the string bytes; see string-ensure-zero-
 * terminated in source/evaluator/arrays.l */
static char *stringCString(oop string);

/*;
;;; symbols
;;;
;;; <symbol> is a record of (name), where name is a <string>. Interning
;;; is the host's job; the lisp side uses the STRING->SYMBOL primitive,
;;; which is the same table.
 */

static size_t arrayLength_(oop array);
static oop arrayAt_(oop array, size_t index);
static oop arrayInsert_(oop array, size_t index, oop value);

#define	symbolTableSize	4096		/* power of two */

static oop	allSymbols= nil;	/* <array> of interned symbols */
static int	*symbolBuckets= 0;	/* index+1 into allSymbols, 0 is empty */
static int	*symbolNext= 0;		/* next index+1 in the same bucket */
static int	symbolCapacity= 0;

static unsigned symbolHash(const char *bytes, size_t len)
{
  unsigned hash= 2166136261;
  size_t index;
  for (index= 0; index < len; ++index) hash= (hash ^ (unsigned char)bytes[index]) * 16777619;
  return hash;
}

static void symbolTableGrow(void)
{
  int newCapacity= symbolCapacity ? symbolCapacity * 2 : 256;
  int *newNext= realloc(symbolNext, newCapacity * sizeof(int));
  if (!newNext) fatal("out of memory");
  symbolNext= newNext;
  for (; symbolCapacity < newCapacity; ++symbolCapacity) symbolNext[symbolCapacity]= 0;
}

static oop newSymbol(oop name)		/* name: <string>, uninterned */
{
  oop obj= newOops(Symbol);
  set(obj, Symbol,name, name);
  return obj;
}

static oop internN(const char *bytes, size_t len)
{
  unsigned	hash= symbolHash(bytes, len);
  int		bucket= hash & (symbolTableSize - 1);
  int		index= symbolBuckets[bucket];
  while (index) {
    oop sym= arrayAt_((oop)allSymbols, index - 1);
    oop name= get(sym, Symbol,name);
    if ((stringLength(name) == len) && (0 == memcmp(stringBytes(name), bytes, len)))
      return sym;
    index= symbolNext[index - 1];
  }
  {
    oop name= newStringN(bytes, len);			GC_PROTECT(name);
    oop sym= newSymbol(name);				GC_PROTECT(sym);
    int position= (int)arrayLength_(allSymbols);
    if (position == symbolCapacity) symbolTableGrow();
    arrayInsert_(allSymbols, position, sym);
    symbolNext[position]= symbolBuckets[bucket];
    symbolBuckets[bucket]= position + 1;
    GC_UNPROTECT(sym);  GC_UNPROTECT(name);
    return sym;
  }
}

static oop intern(const char *cstr)	{ return internN(cstr, strlen(cstr)); }

static oop symbolName(oop symbol)	{ return get(symbol, Symbol,name); }
static char *symbolBytes(oop symbol)	{ return stringBytes(symbolName(symbol)); }

/*;
;;; pairs and arrays
*/

static oop newPair(oop head, oop tail)
{
  oop obj= newOops(Pair);
  set(obj, Pair,head, head);
  set(obj, Pair,tail, tail);
  return obj;
}

static size_t arrayLength_(oop array)	{ return getLong(get(array, Array,size)); }

static size_t arrayCapacity(oop array)
{
  oop elements= get(array, Array,elements);
  return elements ? GC_size(elements) / sizeof(oop) : 0;
}

static oop arrayAt_(oop array, size_t index)
{
  oop elements= get(array, Array,elements);
  if (!elements || (index >= arrayLength_(array))) return nil;
  return ((oop *)elements)[index];
}

static oop arrayAtPut_(oop array, size_t index, oop value)
{
  oop elements;
  if (!(elements= get(array, Array,elements)) || (index >= arrayCapacity(array))) fatal("arrayAtPut: no such array element: %ld", (long)index);
  ((oop *)elements)[index]= value;
  return value;
}

static void arraySetLength(oop array, size_t length)	{ set(array, Array,size, newLong(length)); }

/* grow the backing <data> blob; the elements of the new blob are zeroed */
static void arrayGrow(oop array, size_t capacity)
{
  size_t	 oldCapacity= arrayCapacity(array);
  oop		 elements;
  if (capacity <= oldCapacity) return;
  elements= _newOops(Data, capacity * sizeof(oop), __FILE__, __LINE__);	GC_PROTECT(elements);
  if (oldCapacity) memcpy((oop *)elements, (oop *)get(array, Array,elements), oldCapacity * sizeof(oop));
  set(array, Array,elements, elements);
  GC_UNPROTECT(elements);
}

static oop arrayAppend_(oop array, oop value)
{
  size_t length= arrayLength_(array);
  if (length == arrayCapacity(array)) arrayGrow(array, length ? length * 2 : 8);
  arrayAtPut_(array, length, value);
  arraySetLength(array, length + 1);
  return value;
}

static oop arrayInsert_(oop array, size_t index, oop value)
{
  size_t length= arrayLength_(array);
  if (index > length) index= length;
  if (length == arrayCapacity(array)) arrayGrow(array, length ? length * 2 : 8);
  if (index < length)
    memmove(((oop *)get(array, Array,elements)) + index + 1,
	    ((oop *)get(array, Array,elements)) + index,
	    (length - index) * sizeof(oop));
  arrayAtPut_(array, index, value);
  arraySetLength(array, length + 1);
  return value;
}

/* source/evaluator/arrays.l: the setter grows and extends the size */
static oop arraySetAt_(oop array, size_t index, oop value)
{
  size_t capacity= arrayCapacity(array);
  if (index >= capacity) {
    if (capacity == 0) capacity= 4;
    while (index >= capacity) capacity*= 2;
    arrayGrow(array, capacity);
  }
  if (index >= arrayLength_(array)) arraySetLength(array, index + 1);
  arrayAtPut_(array, index, value);
  return value;
}

static oop newArray(size_t capacity)
{
  oop obj= newOops(Array);				GC_PROTECT(obj);
  set(obj, Array,size, newLong(0));
  set(obj, Array,elements, nil);
  if (capacity) arrayGrow(obj, capacity);
  GC_UNPROTECT(obj);
  return obj;
}

/*; a raw word in the lower realm, boxed so that it can live in the heap */
static oop newLowerCell(void *word)
{
  oop obj= _newBits(LowerCell, sizeof(void *), __FILE__, __LINE__);
  set(obj, LowerCell,word, word);
  return obj;
}

/*; generic slot access: (oop-at obj index) */
static oop oopAt(oop obj, size_t index)
{
  if (!obj || isLong(obj)) fatal("oopAt: not an object: %p", (void *)obj);
  return ((oop *)obj)[index];
}

static oop oopAtPut(oop obj, size_t index, oop value)
{
  if (!obj || isLong(obj)) fatal("oopAtPut: not an object: %p", (void *)obj);
  ((oop *)obj)[index]= value;
  return value;
}

/*;
;;; roots
*/


static oop	s_quote, s_quasiquote, s_unquote, s_unquote_splicing, s_dot;

static int	verbosity= 0;
static int	optimize= 0;

static void fdump_(FILE *stream, oop obj, int storing);

/*;
;;; errors
*/

static oop	currentPath= nil;	/* the file being read, for diagnostics */
static long	sourceLine= 1;

static void fatal(char *reason, ...)
{
  va_list ap;
  if (reason) {
    if (is(String, currentPath))	fprintf(stderr, "\n%s:%ld: ", stringBytes(currentPath), sourceLine);
    else				fprintf(stderr, "\n");
    fprintf(stderr, "error: ");
    va_start(ap, reason);
    vfprintf(stderr, reason, ap);
    va_end(ap);
    fprintf(stderr, "\n");
  }
  exit(1);
}

static void sigint(int signo)	{ fatal("Interrupt"); }

/*;
;;; reader
;;;
;;; A byte for byte port of source/evaluator/reader.l, plus the source
;;; position tracking that this host keeps on pairs for diagnostics.
 */

#include "chartab.h"

static int isAlphaChar(int c)	{ return (0 <= c && c <= 127 && (CHAR_ALPHA   & chartab[c])) || (c >= 128); }
static int isDigit8Char(int c)	{ return '0' <= c && c <= '7'; }
static int isDigit10Char(int c)	{ return (0 <= c && c <= 127 && (CHAR_DIGIT10 & chartab[c])); }
static int isDigit16Char(int c)	{ return (0 <= c && c <= 127 && (CHAR_DIGIT16 & chartab[c])); }
static int isLetterChar(int c)	{ return (0 <= c && c <= 127 && (CHAR_LETTER  & chartab[c])) || (c >= 128); }

static oop	END;			/* end of input */
static oop	END_OF_LIST;		/* the closing delimiter */

static void setCurrentSource(const char *path)
{
  currentPath= newString(path);
  sourceLine= 1;
}

static void setSource(oop obj, oop source)
{
  if (!isPair(obj)) return;
  if (nil == get(obj, Pair,source)) set(obj, Pair,source, source);
  setSource(get(obj, Pair,head), source);
  setSource(get(obj, Pair,tail), source);
}

static int nextChar(FILE *stream)
{
  int c= getc(stream);
  if ('\n' == c) ++sourceLine;
  return c;
}

static void unreadChar(int c, FILE *stream)
{
  if (EOF == c) return;
  if ('\n' == c) --sourceLine;
  ungetc(c, stream);
}

static int peekChar(FILE *stream)	{ int c= nextChar(stream);  unreadChar(c, stream);  return c; }

static int digitValue(int c)
{
  if ('0' <= c && c <= '9') return c - '0';
  if ('a' <= c && c <= 'z') return c - 'a' + 10;
  if ('A' <= c && c <= 'Z') return c - 'A' + 10;
  fatal("illegal digit in character escape: %c", c);
  return 0;
}

/* source/evaluator/reader.l: read/char */
static int readChar_(int c, FILE *stream)
{
  if ('\\' != c) return c;
  c= nextChar(stream);
  switch (c) {
    case 'a':	return '\a';
    case 'b':	return '\b';
    case 'e':	return '\e';
    case 'f':	return '\f';
    case 'n':	return '\n';
    case 'r':	return '\r';
    case 't':	return '\t';
    case 'v':	return '\v';
    case 'u': {
      int a= nextChar(stream), b= nextChar(stream), c2= nextChar(stream), d= nextChar(stream);
      if (!(isDigit16Char(a) && isDigit16Char(b) && isDigit16Char(c2) && isDigit16Char(d)))
	fatal("illegal character escape: \\u");
      return (digitValue(a) << 24) | (digitValue(b) << 16) | (digitValue(c2) << 8) | digitValue(d);
    }
    case 'x': {
      int x, n;
      if (!isDigit16Char(peekChar(stream))) fatal("illegal hexadecimal character escape");
      x= digitValue(nextChar(stream));
      if ((n= peekChar(stream)), isDigit16Char(n)) x= x * 16 + digitValue(nextChar(stream));
      return x;
    }
    default:
      if (isDigit8Char(c)) {
	int x= digitValue(c), n;
	if (((n= peekChar(stream)), isDigit8Char(n))) x= x * 8 + digitValue(nextChar(stream));
	if (((n= peekChar(stream)), isDigit8Char(n))) x= x * 8 + digitValue(nextChar(stream));
	return x;
      }
      if (isAlphaChar(c) || isDigit10Char(c)) fatal("illegal character escape: \\%c", c);
      return c;
  }
}

/* source/evaluator/reader.l: read/number */
static oop readNumber(int c, FILE *stream)
{
  static struct buffer buf= BUFFER_INITIALISER;
  int	negative= 0;
  int	base= 10;
  buffer_reset(&buf);
  if ('-' == c) negative= 1;
  else buffer_append(&buf, c);
  while (isDigit10Char(peekChar(stream))) buffer_append(&buf, nextChar(stream));
  if (('x' == peekChar(stream)) && (1 == buffer_position(&buf)) && ('0' == buf.buffer[0])) {
    nextChar(stream);
    base= 16;
    buffer_reset(&buf);
    while (isDigit16Char(peekChar(stream))) buffer_append(&buf, nextChar(stream));
  }
  {
    char *contents= buffer_contents(&buf);
    char *end= 0;
    long value= strtol(contents, &end, base);
    if (end && *end) fatal("invalid number in source code: %s", contents);
    return newLong(negative ? -value : value);
  }
}

/* source/evaluator/reader.l: read/symbol */
static oop readSymbol(int c, FILE *stream)
{
  static struct buffer buf= BUFFER_INITIALISER;
  buffer_reset(&buf);
  buffer_append(&buf, c);
  while (isLetterChar(peekChar(stream)) || isDigit10Char(peekChar(stream))) buffer_append(&buf, nextChar(stream));
  return intern(buffer_contents(&buf));
}

/* source/evaluator/reader.l: read/string-literal */
static oop readStringLiteral(FILE *stream)
{
  static struct buffer buf= BUFFER_INITIALISER;
  buffer_reset(&buf);
  for (;;) {
    int c= nextChar(stream);
    if ((EOF == c) || ('"' == c)) break;
    buffer_append(&buf, readChar_(c, stream));
  }
  return newStringN(buffer_contents(&buf), buffer_position(&buf));
}

static oop readNested(FILE *stream);
static oop readToplevel(FILE *stream);

/* source/evaluator/reader.l: read/list */
static oop readList(int delimiter, FILE *stream)
{
  oop head= newPair(nil, nil);				GC_PROTECT(head);
  oop tail= head;
  oop element= nil;					GC_PROTECT(element);
  nextChar(stream);					/* drop the opening delimiter */
  for (;;) {
    element= readNested(stream);
    if (END == element) fatal("missing closing delimiter '%c' while reading list", delimiter);
    if (END_OF_LIST == element) {
      if (delimiter != nextChar(stream)) fatal("missing closing delimiter '%c' while reading list", delimiter);
      break;
    }
    if (s_dot == element) {
      oop rest= readToplevel(stream);			GC_PROTECT(rest);
      if (delimiter != nextChar(stream)) fatal("missing closing delimiter '%c' after .", delimiter);
      set(tail, Pair,tail, rest);
      GC_UNPROTECT(rest);
      break;
    }
    {
      oop cell= newPair(element, nil);			/* element is rooted */
      set(tail, Pair,tail, cell);
      tail= cell;
    }
  }
  GC_UNPROTECT(element);  GC_UNPROTECT(head);
  return get(head, Pair,tail);
}

/* source/evaluator/reader.l: read/quote */
static oop readQuote(oop prefix, FILE *stream)
{
  oop quoted= readToplevel(stream);			GC_PROTECT(quoted);
  oop tail= newPair(quoted, nil);			GC_PROTECT(tail);
  oop result= newPair(prefix, tail);
  GC_UNPROTECT(tail);  GC_UNPROTECT(quoted);
  return result;
}

/* source/evaluator/reader.l: read-nested */
static oop readNested(FILE *stream)
{
  for (;;) {
    int c= peekChar(stream);
    if ((EOF == c) || (' ' == c) || ('\t' == c) || ('\n' == c) || ('\v' == c) || ('\f' == c) || ('\r' == c)) {
      if (EOF == c) return END;
      nextChar(stream);
      continue;
    }
    switch (c) {
      case '?':		nextChar(stream);  return newLong((unsigned char)readChar_(nextChar(stream), stream));
      case '-':		nextChar(stream);  return isDigit10Char(peekChar(stream)) ? readNumber(c, stream) : readSymbol(c, stream);
      case '\'':	nextChar(stream);  return readQuote(s_quote, stream);
      case '`':		nextChar(stream);  return readQuote(s_quasiquote, stream);
      case ',':		nextChar(stream);
			if ('@' == peekChar(stream)) { nextChar(stream);  return readQuote(s_unquote_splicing, stream); }
			return readQuote(s_unquote, stream);
      case '(':		return readList(')', stream);
      case '[':		return readList(']', stream);
      case '{':		return readList('}', stream);
      case ')': case ']': case '}':	return END_OF_LIST;
      case ';':		while ((EOF != (c= nextChar(stream))) && ('\n' != c) && ('\r' != c)) ;  continue;
      case '"':		nextChar(stream);  return readStringLiteral(stream);
      default:
	if (isLetterChar(c))	return readSymbol(nextChar(stream), stream);
	if (isDigit10Char(c))	return readNumber(nextChar(stream), stream);
	if (c < 0) return END;
	fatal("illegal character: 0x%02x '%c'", c, c);
    }
  }
}

/* source/evaluator/reader.l: read-toplevel */
static oop readToplevel(FILE *stream)
{
  int c= peekChar(stream);
  switch (c) {
    case '(':	return readList(')', stream);
    case '[':	return readList(']', stream);
    case '{':	return readList('}', stream);
    case ')': case ']': case '}':
      fatal("unexpected close paren");
  }
  return readNested(stream);
}

/*; read a single form and attach the current source position to it */
static oop readForm(FILE *stream)
{
  long	line= sourceLine;
  oop	form= readToplevel(stream);
  if (END == form) return END;
  GC_PROTECT(form);
  {
    oop source= newPair(currentPath, newLong(line));	GC_PROTECT(source);
    setSource(form, source);
    GC_UNPROTECT(source);
  }
  GC_UNPROTECT(form);
  return form;
}

/*;
;;; printer
;;;
;;; Diagnostics only. The lisp side (source/evaluator/printer.l) does
;;; the real printing once boot.l is loaded.
 */

static void fprintString(FILE *stream, oop string, int storing)
{
  char	*bytes= stringBytes(string);
  size_t length= stringLength(string);
  size_t index;
  if (!storing) {
    fwrite(bytes, 1, length, stream);
    return;
  }
  putc('"', stream);
  for (index= 0; index < length; ++index) {
    unsigned char c= bytes[index];
    if ('"' == c)	fprintf(stream, "\\\"");
    else if ('\\' == c)	fprintf(stream, "\\\\");
    else if ((c < ' ') || (c >= 127)) fprintf(stream, "\\%03o", c);
    else		putc(c, stream);
  }
  putc('"', stream);
}

static void fdump_(FILE *stream, oop obj, int storing)
{
  if (!obj) { fprintf(stream, "()");  return; }
  switch (getType(obj)) {
    case Data:		fprintf(stream, "<data[%ld]>", (long)GC_size(obj));		break;
    case Long:		fprintf(stream, "%ld", getLong(obj));				break;
    case String:	fprintString(stream, obj, storing);				break;
    case Symbol:	fprintf(stream, "%s", symbolBytes(obj));			break;
    case LowerCell:	fprintf(stream, "<lower-cell %p>", get(obj, LowerCell,word));	break;
    case Pair: {
      fprintf(stream, "(");
      while (isPair(obj)) {
	fdump_(stream, get(obj, Pair,head), storing);
	obj= get(obj, Pair,tail);
	if (isPair(obj)) putc(' ', stream);
      }
      if (obj) { fprintf(stream, " . ");  fdump_(stream, obj, storing); }
      putc(')', stream);
      break;
    }
    case Array: {
      size_t index, length= arrayLength_(obj);
      fprintf(stream, "Array<%ld>(", (long)length);
      for (index= 0; index < length; ++index) {
	if (index) putc(' ', stream);
	fdump_(stream, arrayAt_(obj, index), storing);
      }
      fprintf(stream, ")");
      break;
    }
    case Fixed:		fprintf(stream, "Fixed<");  fdump_(stream, get(obj, Fixed,function), storing);  fprintf(stream, ">");  break;
    case Form:		fprintf(stream, "Form<");  fdump_(stream, get(obj, Form,function), storing);  fprintf(stream, ">");  break;
    case Expr:		fprintf(stream, "Expr<");  fdump_(stream, get(obj, Expr,parameters), storing);  fprintf(stream, ">");  break;
    case TargetFunction: fprintf(stream, ".%s", get(obj, TargetFunction,name) ? stringBytes(get(obj, TargetFunction,name)) : "target-fn");  break;
    case Variable:	fprintf(stream, "%s", symbolBytes(get(obj, Variable,name)));  break;
    default:		fprintf(stream, "<type %i>", getType(obj));			break;
  }
}

static void dump_(FILE *stream, oop obj)	{ fdump_(stream, obj, 1);  fflush(stream); }

static void dumplno(oop obj)			{ dump_(stdout, obj);  putchar('\n');  fflush(stdout); }

/*;
;;; environments and variables
;;;
;;; source/env-lower.l, plus the environment related vm-functions of
;;; source/evaluator/eval.l.
 */

static oop	theMaru= nil;		/* *maru*: the primitive env, level 0 */
static oop	theGlobals= nil;	/* *globals*: the current global env */
static oop	theEnd= nil;		/* +end+: an uninterned symbol */

static oop	expandersVar= nil, encodersVar= nil, evaluatorsVar= nil, applicatorsVar= nil;

/* the nine fixed vm-functions, see source/evaluator/vm-functions.l */
static oop	f_define= nil, f_lambda= nil, f_let= nil, f_set= nil;
static oop	f_while= nil, f_if= nil, f_and= nil, f_or= nil, f_quote= nil;

/* the well known symbols that expand/encode dispatch on */
static oop	s_let= nil, s_define= nil, s_lambda= nil, s_set= nil;
static oop	s_if= nil, s_while= nil, s_and= nil, s_or= nil;

/* the host's stream objects are <lower-cell>s holding a FILE* */
static oop	standardInput= nil, standardOutput= nil, standardError= nil, debugOutput= nil;

static oop expand(oop exp, oop env, int oneStep);
static oop expandAll(oop list, oop env, int oneStep);
static oop encode(oop exp, oop env);
static oop encodeAll(oop list, oop env);
static oop eval(oop exp, oop ctx);
static oop apply(oop fun, oop args, oop ctx);
static oop expandEncodeEvalIn(oop form, oop env);
static oop expandEncodeEval(oop form);
static void processStream(FILE *stream, const char *path);

static oop newEnvironment(oop parent, long level, long offset)
{
  oop obj= newOops(Env);				GC_PROTECT(obj);
  set(obj, Env,parent, parent);
  set(obj, Env,level, newLong(is(Env, parent) ? getLong(get(parent, Env,level)) + level : 0));
  set(obj, Env,offset, newLong(offset));
  set(obj, Env,bindings, newArray(0));
  set(obj, Env,stable, nil);
  set(obj, Env,name, nil);
  GC_UNPROTECT(obj);
  return obj;
}

static oop findLocalVariable(oop env, oop name)
{
  oop	 bindings= get(env, Env,bindings);
  size_t index= arrayLength_(bindings);
  while (index--) {
    oop var= arrayAt_(bindings, index);
    if (get(var, Variable,name) == name) return var;
  }
  return nil;
}

static oop findVariable(oop env, oop name)
{
  while (env) {
    oop var= findLocalVariable(env, name);
    if (var) return var;
    env= get(env, Env,parent);
  }
  return nil;
}

static oop newVariable(oop env, oop name)
{
  oop offset= get(env, Env,offset);
  oop var= newOops(Variable);				GC_PROTECT(var);
  set(var, Variable,name, name);
  set(var, Variable,value, nil);
  set(var, Variable,env, env);
  set(var, Variable,index, offset);
  set(env, Env,offset, newLong(getLong(offset) + 1));
  arrayAppend_(get(env, Env,bindings), var);
  GC_UNPROTECT(var);
  return var;
}

static oop environmentDefine(oop env, oop name, oop value)
{
  oop var= findLocalVariable(env, name);
  if (!var) var= newVariable(env, name);
  set(var, Variable,value, value);
  return var;
}

static int globalVariable(oop var)	{ return 0 == getLong(get(get(var, Variable,env), Env,level)); }

static oop maybeObjectInVariable(oop var, int type)
{
  oop value;
  if (!is(Variable, var)) return nil;
  value= get(var, Variable,value);
  if (type && !is(type, value)) return nil;
  return value;
}

static oop maybeObjectInEnv(oop env, oop name, int type)
{
  if (!is(Symbol, name)) return nil;
  return maybeObjectInVariable(findVariable(env, name), type);
}

static oop maybeFormFunction(oop env, oop name)	{ oop form= maybeObjectInEnv(env, name, Form);  return form ? get(form, Form,function) : nil; }
static oop maybeFormSymbol(oop env, oop name)	{ oop form= maybeObjectInEnv(env, name, Form);  return form ? get(form, Form,symbol)   : nil; }

static oop arrayInVariable(oop var)		{ return maybeObjectInVariable(var, Array); }

/* source/evaluator/vm-late.l: capture-well-known-globals */
static void captureWellKnownGlobals(void)
{
  expandersVar=   findVariable(theGlobals, intern("*expanders*"));
  encodersVar=    findVariable(theGlobals, intern("*encoders*"));
  evaluatorsVar=  findVariable(theGlobals, intern("*evaluators*"));
  applicatorsVar= findVariable(theGlobals, intern("*applicators*"));
}

static FILE *streamFile(oop stream, const char *who)
{
  if (!is(LowerCell, stream)) fatal("%s: not a stream", who);
  return (FILE *)get(stream, LowerCell,word);
}

static oop newHostStream(FILE *file)
{
  return newLowerCell((void *)file);
}

/*;
;;; lists
*/

static int length(oop list)
{
  int len= 0;
  while (isPair(list)) { ++len;  list= cdr(list); }
  return len;
}

static void arity(oop args, const char *who, int expected)
{
  if (length(args) != expected) fatal("%s: expected %d argument(s)", who, expected);
}

static oop list2(oop a, oop b)
{
  oop tail= newPair(b, nil);				GC_PROTECT(tail);
  oop result= newPair(a, tail);
  GC_UNPROTECT(tail);
  return result;
}

static oop list3(oop a, oop b, oop c)
{
  oop tail= newPair(b, newPair(c, nil));		GC_PROTECT(tail);
  oop result= newPair(a, tail);
  GC_UNPROTECT(tail);
  return result;
}

/* copy the spine of HEAD and append TAIL, like source's CONCAT-LIST */
static oop appendList(oop head, oop tail)
{
  oop rest, result;
  if (!isPair(head)) return tail;
  rest= appendList(cdr(head), tail);			GC_PROTECT(rest);
  result= newPair(car(head), rest);
  GC_UNPROTECT(rest);
  return result;
}

static oop listReverse(oop list)
{
  oop result= nil;					GC_PROTECT(result);
  while (isPair(list)) {
    result= newPair(car(list), result);
    list= cdr(list);
  }
  GC_UNPROTECT(result);
  return result;
}

/*;
;;; expand
;;;
;;; source/evaluator/eval.l: expand, expand/pair, expand/symbol,
;;; expand-all, setter-name-for, attempt-set-convert.
 */

static oop setterNameFor(oop fnName, oop env)
{
  static struct buffer buf= BUFFER_INITIALISER;
  oop name;
  if (!is(Symbol, fnName)) return nil;
  buffer_reset(&buf);
  buffer_appendAll(&buf, "set-");
  buffer_appendAll(&buf, symbolBytes(fnName));
  name= intern(buffer_contents(&buf));
  return findVariable(env, name) ? name : nil;
}

static oop attemptSetConvert(oop place, oop value, oop env, int oneStep)
{
  oop fnName= isPair(place) ? car(place) : nil;
  oop setter= setterNameFor(fnName, env);
  oop args, result;
  if (!setter) return nil;
  args= expandAll(cdr(place), env, oneStep);		GC_PROTECT(args);
  {
    oop valueList= newPair(value, nil);			GC_PROTECT(valueList);
    result= newPair(setter, appendList(args, valueList));
    GC_UNPROTECT(valueList);
  }
  GC_UNPROTECT(args);
  return result;
}

static oop expandSymbol(oop exp, oop env, int oneStep)
{
  oop fn= maybeFormSymbol(env, exp);
  oop expansion, result;
  if (!fn) return exp;
  expansion= apply(fn, list2(env, exp), nil);		GC_PROTECT(expansion);
  result= oneStep ? expansion : expand(expansion, env, oneStep);
  GC_UNPROTECT(expansion);
  return result;
}

static oop expandPair(oop exp, oop env, int oneStep)
{
  oop head= expand(car(exp), env, oneStep);		GC_PROTECT(head);
  oop result;

  if (head == s_let) {
    /* (let ((var . init-exprs) ...) . body) */
    oop entry= car(cdr(exp));
    oop bindings= nil, bindingsTail= nil;		GC_PROTECT(bindings);  GC_PROTECT(bindingsTail);
    while (isPair(entry)) {
      oop binding= car(entry);				GC_PROTECT(binding);
      oop varName= isPair(binding) ? car(binding) : binding;
      oop initProg= isPair(binding) ? expandAll(cdr(binding), env, oneStep) : newPair(nil, nil);
      GC_PROTECT(initProg);
      {
	oop newEntry= newPair(varName, initProg);	GC_PROTECT(newEntry);
	if (bindings) { set(bindingsTail, Pair,tail, newPair(newEntry, nil));  bindingsTail= cdr(bindingsTail); }
	else	      { bindings= newPair(newEntry, nil);  bindingsTail= bindings; }
	GC_UNPROTECT(newEntry);
      }
      GC_UNPROTECT(initProg);  GC_UNPROTECT(binding);
      entry= cdr(entry);
    }
    {
      oop body= expandAll(cdr(cdr(exp)), env, oneStep);	GC_PROTECT(body);
      {
	oop tail= newPair(bindings, body);		GC_PROTECT(tail);
	result= newPair(s_let, tail);
	GC_UNPROTECT(tail);
      }
      GC_UNPROTECT(body);
    }
    GC_UNPROTECT(bindingsTail);  GC_UNPROTECT(bindings);
  }
  else if (head == s_quote) {
    result= newPair(s_quote, cdr(exp));
  }
  else if (head == s_set) {
    oop place= car(cdr(exp));
    oop valueForm= car(cdr(cdr(exp)));
    oop value, converted, expandedPlace;
    if (2 != length(cdr(exp))) fatal("expand: illegal set form");
    value= expand(valueForm, env, oneStep);		GC_PROTECT(value);
    converted= attemptSetConvert(place, value, env, oneStep);	GC_PROTECT(converted);
    if (converted) {
      result= oneStep ? converted : expand(converted, env, oneStep);
    }
    else {
      expandedPlace= expand(place, env, 1);		GC_PROTECT(expandedPlace);
      converted= attemptSetConvert(expandedPlace, value, env, oneStep);
      if (converted) {
	result= oneStep ? converted : expand(converted, env, oneStep);
      }
      else {
	oop fnName= isPair(expandedPlace) ? car(expandedPlace) : nil;
	result= list3(s_set, expandedPlace, value);
	if (!oneStep && is(Symbol, fnName)
	    && (maybeObjectInEnv(env, fnName, Form) || setterNameFor(fnName, env)))
	  result= expand(result, env, oneStep);
      }
      GC_UNPROTECT(expandedPlace);
    }
    GC_UNPROTECT(converted);  GC_UNPROTECT(value);
  }
  else if (head == s_define) {
    oop name= car(cdr(exp));
    oop value= expand(car(cdr(cdr(exp))), env, oneStep);	GC_PROTECT(value);
    result= list3(s_define, name, value);
    GC_UNPROTECT(value);
  }
  else if (head == s_lambda) {
    oop parameters= car(cdr(exp));
    oop body= expandAll(cdr(cdr(exp)), env, oneStep);		GC_PROTECT(body);
    {
      oop tail= newPair(parameters, body);		GC_PROTECT(tail);
      result= newPair(s_lambda, tail);
      GC_UNPROTECT(tail);
    }
    GC_UNPROTECT(body);
  }
  else {
    /* is the head bound to a <form> with a function in the local env? */
    oop expander= maybeFormFunction(env, head);
    if (expander) {
      oop expansion= apply(expander, newPair(env, cdr(exp)), nil);	GC_PROTECT(expansion);
      result= oneStep ? expansion : expand(expansion, env, oneStep);
      GC_UNPROTECT(expansion);
    }
    else {
      oop tail= expandAll(cdr(exp), env, oneStep);		GC_PROTECT(tail);
      result= newPair(head, tail);
      GC_UNPROTECT(tail);
    }
  }
  GC_UNPROTECT(head);
  return result;
}

static oop expand(oop exp, oop env, int oneStep)
{
  if (isPair(exp))	return expandPair(exp, env, oneStep);
  if (is(Symbol, exp))	return expandSymbol(exp, env, oneStep);
  {
    oop array= arrayInVariable(expandersVar);
    oop fn= array ? arrayAt_(array, getType(exp)) : nil;
    if (fn) {
      oop args= newPair(exp, nil);			GC_PROTECT(args);
      oop result= apply(fn, args, nil);
      GC_UNPROTECT(args);
      return result;
    }
  }
  return exp;
}

static oop expandAll(oop list, oop env, int oneStep)
{
  oop head, tail, result;
  if (!isPair(list)) return expand(list, env, oneStep);
  head= expand(car(list), env, oneStep);		GC_PROTECT(head);
  tail= expandAll(cdr(list), env, oneStep);		GC_PROTECT(tail);
  result= newPair(head, tail);
  GC_UNPROTECT(tail);  GC_UNPROTECT(head);
  return result;
}

/*;
;;; encode
;;;
;;; source/evaluator/eval.l: encode, encode/pair, encode-all,
;;; encode/symbol.
 */

static oop encodeSymbol(oop symbol, oop env)
{
  oop var= findVariable(env, symbol);
  if (!var) fatal("encode/symbol: failed for %s", symbolBytes(symbol));
  if (globalVariable(var)) {
    oop value= get(var, Variable,value);
    if (is(Form, value) || is(Fixed, value)) return value;
  }
  else {
    oop varEnv= get(var, Variable,env);
    long varLevel= getLong(get(varEnv, Env,level));
    long envLevel= getLong(get(env, Env,level));
    if (varLevel > envLevel) fatal("encode/symbol: %s is a variable of an inner scope", symbolBytes(symbol));
    if (varLevel < envLevel) set(varEnv, Env,stable, intern("true"));
  }
  return var;
}

static oop encodeLet(oop tail, oop env)
{
  oop	 bindings= car(tail);
  oop	 innerEnv;
  oop	 vars= nil, newBindings= nil;
  oop	 entry;

  if (is(Env, bindings)) return tail;		/* already encoded */
  innerEnv= newEnvironment(env, 0, getLong(get(env, Env,offset)));	GC_PROTECT(innerEnv);
  GC_PROTECT(vars);  GC_PROTECT(newBindings);

  /* phase 1: define the let variables into the inner env */
  for (entry= bindings; isPair(entry); entry= cdr(entry))
    vars= newPair(environmentDefine(innerEnv, car(car(entry)), nil), vars);
  vars= listReverse(vars);
  /* skip the indices of our let variables in the parent */
  set(env, Env,offset, get(innerEnv, Env,offset));

  /* phase 2: encode the init programs in the outer env */
  {
    oop var= vars;				GC_PROTECT(var);
    for (entry= bindings; isPair(entry); entry= cdr(entry)) {
      oop initProg= encodeAll(cdr(car(entry)), env);	GC_PROTECT(initProg);
      oop newEntry= newPair(car(var), initProg);	GC_PROTECT(newEntry);
      newBindings= newPair(newEntry, newBindings);
      GC_UNPROTECT(newEntry);  GC_UNPROTECT(initProg);
      var= cdr(var);
    }
    GC_UNPROTECT(var);
  }
  newBindings= listReverse(newBindings);
  /* in reverse, copy the offset: the init forms may have defined vars */
  set(innerEnv, Env,offset, get(env, Env,offset));
  {
    oop body= encodeAll(cdr(tail), innerEnv);		GC_PROTECT(body);
    oop tail= newPair(newBindings, body);		GC_PROTECT(tail);
    oop result= newPair(innerEnv, tail);
    GC_UNPROTECT(tail);
    GC_UNPROTECT(body);
    GC_UNPROTECT(newBindings);  GC_UNPROTECT(vars);  GC_UNPROTECT(innerEnv);
    return result;
  }
}

static oop encodePair(oop exp, oop env)
{
  oop head= encode(car(exp), env);			GC_PROTECT(head);
  oop tail= cdr(exp);					GC_PROTECT(tail);
  oop result;

  if (head == f_let) {
    tail= encodeLet(tail, env);
  }
  else if (head == f_lambda) {
    oop parameters= car(tail);
    if (!is(Env, parameters)) {
      oop innerEnv= newEnvironment(env, 1, 0);		GC_PROTECT(innerEnv);
      oop param= parameters;
      while (isPair(param)) { environmentDefine(innerEnv, car(param), nil);  param= cdr(param); }
      if (param) environmentDefine(innerEnv, param, nil);
      tail= encodeAll(tail, innerEnv);
      tail= newPair(innerEnv, tail);
      GC_UNPROTECT(innerEnv);
    }
  }
  else if (head == f_define) {
    oop name= car(tail);
    if (!is(Variable, name)) {
      oop var= environmentDefine(theGlobals, name, nil);	GC_PROTECT(var);
      oop encoded= encodeAll(cdr(tail), env);		GC_PROTECT(encoded);
      tail= newPair(var, encoded);
      GC_UNPROTECT(encoded);  GC_UNPROTECT(var);
    }
  }
  else if (head == f_set) {
    oop place= car(tail);
    if (is(Symbol, place)) {
      oop var= findVariable(env, place);
      if (!var) fatal("encode/set: undefined variable: %s", symbolBytes(place));
      if (2 != length(tail)) fatal("encode/set: malformed set: expected one value form");
      {
	oop encoded= encodeAll(cdr(tail), env);		GC_PROTECT(encoded);
	tail= newPair(var, encoded);
	GC_UNPROTECT(encoded);
      }
    }
    else if (!is(Variable, place))
      fatal("encode/set: unexpected set form");
  }
  else if (head != f_quote) {
    tail= encodeAll(tail, env);
  }
  result= newPair(head, tail);
  GC_UNPROTECT(tail);  GC_UNPROTECT(head);
  return result;
}

static oop encode(oop exp, oop env)
{
  if (isPair(exp))	return encodePair(exp, env);
  if (is(Symbol, exp))	return encodeSymbol(exp, env);
  {
    oop array= arrayInVariable(encodersVar);
    oop fn= array ? arrayAt_(array, getType(exp)) : nil;
    if (fn) {
      oop args= list2(exp, env);			GC_PROTECT(args);
      oop result= apply(fn, args, nil);
      GC_UNPROTECT(args);
      return result;
    }
  }
  return exp;
}

static oop encodeAll(oop list, oop env)
{
  oop head, tail, result;
  if (!isPair(list)) return encode(list, env);
  head= encode(car(list), env);				GC_PROTECT(head);
  tail= encodeAll(cdr(list), env);			GC_PROTECT(tail);
  result= newPair(head, tail);
  GC_UNPROTECT(tail);  GC_UNPROTECT(head);
  return result;
}

/*;
;;; eval and apply
;;;
;;; source/evaluator/eval.l: eval, eval-all, apply, apply/expr.
 */

static oop baseContext(oop home, oop env)
{
  oop obj= newOops(Context);				GC_PROTECT(obj);
  set(obj, Context,home, home);
  set(obj, Context,env, env);
  set(obj, Context,bindings, newArray(0));
  set(obj, Context,callee, nil);
  GC_UNPROTECT(obj);
  return obj;
}

static oop context(oop home, oop caller, oop env)
{
  oop obj= baseContext(home, env);
  if (caller) set(caller, Context,callee, obj);
  return obj;
}

static oop applyExpr(oop fun, oop arguments, oop parentCtx)
{
  oop	env= get(fun, Expr,env);
  oop	params= get(fun, Expr,parameters);
  oop	args= arguments;
  oop	innerCtx= context(get(fun, Expr,ctx), parentCtx, env);	GC_PROTECT(innerCtx);
  oop	locals= get(innerCtx, Context,bindings);
  oop	body, result= nil;

  while (isPair(params)) {
    if (!isPair(args)) fatal("too few arguments for %s", "an expression");
    arraySetAt_(locals, getLong(get(car(params), Variable,index)), car(args));
    params= cdr(params);
    args= cdr(args);
  }
  if (is(Variable, params)) {
    arraySetAt_(locals, getLong(get(params, Variable,index)), args);
    args= nil;
  }
  if (args) fatal("too many arguments for an expression");
  for (body= get(fun, Expr,body); isPair(body); body= cdr(body)) {
    result= eval(car(body), innerCtx);
  }
  if (get(env, Env,stable)) set(innerCtx, Context,callee, nil);
  GC_UNPROTECT(innerCtx);
  return result;
}

static oop evalVariable(oop var, oop ctx)
{
  if (globalVariable(var)) return get(var, Variable,value);
  {
    long delta= getLong(get(get(ctx, Context,env), Env,level))
	      - getLong(get(get(var, Variable,env), Env,level));
    while (0 < delta) { ctx= get(ctx, Context,home);  --delta; }
    return arrayAt_(get(ctx, Context,bindings), getLong(get(var, Variable,index)));
  }
}

static oop evalAll(oop list, oop ctx)
{
  oop head, tail, result;
  if (!isPair(list)) return eval(list, ctx);
  head= eval(car(list), ctx);				GC_PROTECT(head);
  tail= evalAll(cdr(list), ctx);			GC_PROTECT(tail);
  result= newPair(head, tail);
  GC_UNPROTECT(tail);  GC_UNPROTECT(head);
  return result;
}

static oop evalPair(oop exp, oop ctx)
{
  oop head= eval(car(exp), ctx);			GC_PROTECT(head);
  oop result;
  if (is(Fixed, head))
    result= apply(get(head, Fixed,function), cdr(exp), ctx);
  else {
    oop args= evalAll(cdr(exp), ctx);			GC_PROTECT(args);
    result= apply(head, args, ctx);
    GC_UNPROTECT(args);
  }
  GC_UNPROTECT(head);
  return result;
}

static oop eval(oop exp, oop ctx)
{
  switch (getType(exp)) {
    case Undefined:
    case Long:
    case String:	return exp;
    case Variable:	return evalVariable(exp, ctx);
    case Symbol:	fatal("eval: encountered a <symbol> in encoded code: %s", symbolBytes(exp));
    case Pair:		return evalPair(exp, ctx);
    default: {
      oop array= arrayInVariable(evaluatorsVar);
      oop fn= array ? arrayAt_(array, getType(exp)) : nil;
      if (fn) {
	oop args= newPair(exp, nil);			GC_PROTECT(args);
	oop result= apply(fn, args, ctx);
	GC_UNPROTECT(args);
	return result;
      }
      return exp;
    }
  }
}

static oop apply(oop fun, oop args, oop ctx)
{
  if (is(Expr, fun))		return applyExpr(fun, args, ctx);
  if (is(TargetFunction, fun)) {
    oop cell= get(fun, TargetFunction,program_code);
    imp_t imp= (imp_t)get(cell, LowerCell,word);
    return imp(args, ctx);
  }
  {
    oop array= arrayInVariable(applicatorsVar);
    oop fn= array ? arrayAt_(array, getType(fun)) : nil;
    if (fn) {
      oop full= newPair(fun, args);			GC_PROTECT(full);
      oop result= apply(fn, full, ctx);
      GC_UNPROTECT(full);
      return result;
    }
  }
  fatal("cannot apply: %p of type %i", (void *)fun, getType(fun));
  return nil;
}

static oop expandEncodeEvalIn(oop form, oop env)
{
  oop ctx, result;
  form= expand(form, env, 0);				GC_PROTECT(form);
  form= encode(form, env);
  ctx= baseContext(nil, env);				GC_PROTECT(ctx);
  result= eval(form, ctx);
  GC_UNPROTECT(ctx);  GC_UNPROTECT(form);
  return result;
}

/* source/evaluator/eval.l: expand-encode-eval */
static oop expandEncodeEval(oop form)
{
  oop env= newEnvironment(theGlobals, 1, 0);		GC_PROTECT(env);
  oop result= expandEncodeEvalIn(form, env);
  GC_UNPROTECT(env);
  return result;
}

/*;
;;; the fixed vm-functions
;;;
;;; source/evaluator/vm-functions.l
 */

static oop prim_define(oop args, oop ctx)
{
  oop variable= car(args);
  oop valueForm= car(cdr(args));
  oop value= eval(valueForm, ctx);
  oop named;
  set(variable, Variable,value, value);
  named= value;
  if (is(Form, named)) named= get(named, Form,function);
  if (is(Expr, named) && !get(named, Expr,name))
    set(named, Expr,name, get(variable, Variable,name));
  return value;
}

static oop prim_lambda(oop args, oop ctx)
{
  oop env= car(args);
  oop parameters= car(cdr(args));
  oop body= cdr(cdr(args));
  oop obj= newOops(Expr);				GC_PROTECT(obj);
  if (!(is(Env, env) && (is(Variable, parameters) || isPair(parameters) || !parameters)))
    fatal("lambda: unexpected argument list");
  set(obj, Expr,parameters, parameters);
  set(obj, Expr,body, body);
  set(obj, Expr,env, env);
  set(obj, Expr,ctx, ctx);
  set(obj, Expr,name, nil);
  GC_UNPROTECT(obj);
  return obj;
}

static oop prim_let(oop args, oop ctx)
{
  oop env= car(args);
  oop bindings= car(cdr(args));
  oop body= cdr(cdr(args));
  oop locals= get(ctx, Context,bindings);
  oop result= nil;
  (void)env;
  for (; isPair(bindings); bindings= cdr(bindings)) {
    oop binding= car(bindings);
    if (isPair(binding)) {
      oop var= car(binding);
      oop prog= cdr(binding);
      oop value= nil;					GC_PROTECT(value);
      while (isPair(prog)) { value= eval(car(prog), ctx);  prog= cdr(prog); }
      arraySetAt_(locals, getLong(get(var, Variable,index)), value);
      GC_UNPROTECT(value);
    }
  }
  for (; isPair(body); body= cdr(body)) result= eval(car(body), ctx);
  return result;
}

static oop prim_set(oop args, oop ctx)
{
  oop var= car(args);
  oop valueForm= car(cdr(args));
  oop value= eval(valueForm, ctx);			GC_PROTECT(value);
  if (globalVariable(var)) set(var, Variable,value, value);
  else {
    long delta= getLong(get(get(ctx, Context,env), Env,level))
	      - getLong(get(get(var, Variable,env), Env,level));
    while (0 < delta) { ctx= get(ctx, Context,home);  --delta; }
    arraySetAt_(get(ctx, Context,bindings), getLong(get(var, Variable,index)), value);
  }
  GC_UNPROTECT(value);
  return value;
}

static oop prim_while(oop args, oop ctx)
{
  oop test= car(args);
  oop prog= cdr(args);
  while (eval(test, ctx)) {
    oop body;
    for (body= prog; isPair(body); body= cdr(body)) eval(car(body), ctx);
  }
  return nil;
}

static oop prim_if(oop args, oop ctx)
{
  oop test= car(args);
  oop then= car(cdr(args));
  oop otherwise= cdr(cdr(args));
  if (eval(test, ctx)) return eval(then, ctx);
  {
    oop result= nil;
    for (; isPair(otherwise); otherwise= cdr(otherwise)) result= eval(car(otherwise), ctx);
    return result;
  }
}

static oop prim_or(oop args, oop ctx)
{
  while (isPair(args)) {
    oop value= eval(car(args), ctx);
    if (value) return value;
    args= cdr(args);
  }
  return nil;
}

static oop prim_and(oop args, oop ctx)
{
  oop result= intern("true");
  while (isPair(args)) {
    result= eval(car(args), ctx);
    if (!result) return nil;
    args= cdr(args);
  }
  return result;
}

static oop prim_quote(oop args, oop ctx)
{
  (void)ctx;
  return car(args);
}

/*;
;;; the ordinary vm-functions
;;;
;;; source/evaluator/vm-functions.l and source/evaluator/arrays.l
 */

static oop prim_eval(oop args, oop ctx)
{
  oop form= car(args);
  oop env= isPair(cdr(args)) ? car(cdr(args)) : theGlobals;
  oop result;
  if (isPair(cdr(args)) && !is(Env, env)) fatal("eval: the second argument is not an environment");
  {
    int toplevel= (0 == getLong(get(env, Env,level)));
    oop prevGlobals= theGlobals;
    if (toplevel) { theGlobals= env;  captureWellKnownGlobals(); }
    {
      oop child= newEnvironment(env, 1, 0);		GC_PROTECT(child);
      result= expandEncodeEvalIn(form, child);
      GC_UNPROTECT(child);
    }
    if (toplevel) { theGlobals= prevGlobals;  captureWellKnownGlobals(); }
  }
  (void)ctx;
  return result;
}

static oop prim_apply(oop args, oop ctx)
{
  oop fn= car(args);
  oop arguments= car(cdr(args));
  return apply(fn, arguments, ctx);
}

static oop prim_expand(oop args, oop ctx)
{
  oop env= isPair(cdr(args)) ? car(cdr(args)) : get(ctx, Context,env);
  oop oneStep= isPair(cdr(cdr(args))) ? car(cdr(cdr(args))) : nil;
  return expand(car(args), env, oneStep ? 1 : 0);
}

static oop prim_encode(oop args, oop ctx)
{
  oop env= isPair(cdr(args)) ? car(cdr(args)) : get(ctx, Context,env);
  return encode(car(args), env);
}

static oop prim_environment(oop args, oop ctx)
{
  oop parent= car(args);
  oop level= isPair(cdr(args)) ? car(cdr(args)) : nil;
  oop offset= isPair(cdr(cdr(args))) ? car(cdr(cdr(args)))
	    : (is(Env, parent) ? get(parent, Env,offset) : newLong(0));
  (void)ctx;
  if (parent && !is(Env, parent)) fatal("environment: parent is not an environment");
  return newEnvironment(parent, level ? getLong(level) : 0, getLong(offset));
}

static oop prim_environment_define(oop args, oop ctx)
{
  (void)ctx;
  arity(args, "environment-define", 3);
  return environmentDefine(car(args), car(cdr(args)), car(cdr(cdr(args))));
}

static oop prim_defined(oop args, oop ctx)
{
  oop name= car(args);
  oop env= isPair(cdr(args)) ? car(cdr(args)) : theGlobals;
  (void)ctx;
  if (!is(Symbol, name)) fatal("defined?: not a symbol");
  return findVariable(env, name);
}

static oop prim_variable(oop args, oop ctx)
{
  oop name= car(args), value= car(cdr(args)), env= car(cdr(cdr(args)));
  oop index= car(cdr(cdr(cdr(args))));
  oop obj= newOops(Variable);
  (void)ctx;
  set(obj, Variable,name, name);
  set(obj, Variable,value, value);
  set(obj, Variable,env, env);
  set(obj, Variable,index, index);
  return obj;
}

static oop prim_form(oop args, oop ctx)
{
  oop obj= newOops(Form);
  (void)ctx;
  set(obj, Form,function, car(args));
  set(obj, Form,symbol, isPair(cdr(args)) ? car(cdr(args)) : nil);
  return obj;
}

static oop newFixed(oop function)
{
  oop obj= newOops(Fixed);
  set(obj, Fixed,function, function);
  return obj;
}

static oop prim_fixed(oop args, oop ctx)
{
  (void)ctx;
  return newFixed(car(args));
}

static oop prim_current_globals(oop args, oop ctx)
{
  (void)args;  (void)ctx;
  return theGlobals;
}

static oop prim_set_current_globals(oop args, oop ctx)
{
  oop env= car(args);
  (void)ctx;
  theGlobals= env;
  captureWellKnownGlobals();
  return env;
}

static oop prim_global_variable(oop args, oop ctx)
{
  (void)ctx;
  return globalVariable(car(args)) ? intern("true") : nil;
}

static oop prim_type_of(oop args, oop ctx)
{
  (void)ctx;
  arity(args, "type-of", 1);
  return newLong(getType(car(args)));
}

static oop prim_allocate(oop args, oop ctx)
{
  oop type= car(args);
  oop slots= car(cdr(args));
  (void)ctx;
  return _newOops((int)getLong(type), getLong(slots) * sizeof(oop), __FILE__, __LINE__);
}

static oop prim_allocate_data(oop args, oop ctx)
{
  (void)ctx;
  return newDataSized(getLong(car(args)));
}

static oop prim_oop_at(oop args, oop ctx)
{
  (void)ctx;
  return oopAt(car(args), getLong(car(cdr(args))));
}

static oop prim_set_oop_at(oop args, oop ctx)
{
  (void)ctx;
  return oopAtPut(car(args), getLong(car(cdr(args))), car(cdr(cdr(args))));
}

static oop prim_copy_oops(oop args, oop ctx)
{
  oop from= car(args), to= car(cdr(args));
  oop count= car(cdr(cdr(args)));
  (void)ctx;
  memmove((oop *)to, (oop *)from, getLong(count) * sizeof(oop));
  return nil;
}

/*; strings */
static oop prim_string(oop args, oop ctx)
{
  oop capacity= isPair(args) ? car(args) : newLong(0);
  oop obj;
  (void)ctx;
  obj= newStringN("", 0);				GC_PROTECT(obj);
  if (getLong(capacity) > 0) {
    oop elements= newDataSized(getLong(capacity) + 1);
    set(obj, String,elements, elements);
  }
  GC_UNPROTECT(obj);
  return obj;
}

static oop prim_string_length(oop args, oop ctx)
{
  (void)ctx;
  return get(car(args), String,size);
}

/* the string setter of arrays.l: it grows, and extends the size when
 * writing past the end */
static oop stringSetAt(oop string, size_t index, int byte)
{
  oop	 elements= get(string, String,elements);
  size_t capacity= elements ? GC_size(elements) - 1 : 0;
  size_t size= stringLength(string);
  if (index >= capacity) {
    size_t newCapacity= capacity ? capacity : 4;
    while (index >= newCapacity) newCapacity*= 2;
    elements= newDataSized(newCapacity + 1);		GC_PROTECT(elements);
    if (capacity) memcpy(elements, get(string, String,elements), size);
    set(string, String,elements, elements);
    GC_UNPROTECT(elements);
  }
  stringBytes(string)[index]= (char)byte;
  if (size <= index) set(string, String,size, newLong(index + 1));
  return string;
}

static oop prim_string_at(oop args, oop ctx)
{
  oop string= car(args);
  size_t index= getLong(car(cdr(args)));
  (void)ctx;
  if (index >= stringLength(string)) return nil;
  return newLong((unsigned char)stringBytes(string)[index]);
}

static oop prim_set_string_at(oop args, oop ctx)
{
  oop string= car(args);
  size_t index= getLong(car(cdr(args)));
  oop value= car(cdr(cdr(args)));
  (void)ctx;
  stringSetAt(string, index, (int)getLong(value));
  return value;
}

static oop prim_set_string_length(oop args, oop ctx)
{
  oop string= car(args);
  set(string, String,size, car(cdr(args)));
  (void)ctx;
  return string;
}

static oop prim_string_append(oop args, oop ctx)
{
  oop string= car(args);
  oop value= car(cdr(args));
  (void)ctx;
  stringSetAt(string, stringLength(string), (int)getLong(value));
  return string;
}

static oop prim_string_insert(oop args, oop ctx)
{
  oop	 string= car(args);
  size_t index= getLong(car(cdr(args)));
  oop	 value= car(cdr(cdr(args)));
  size_t size= stringLength(string);
  (void)ctx;
  if (index < size) {
    stringSetAt(string, size, 0);			/* make room */
    memmove(stringBytes(string) + index + 1,
	    stringBytes(string) + index,
	    size - index);
  }
  stringSetAt(string, index, (int)getLong(value));
  return string;
}

static oop prim_string_insert_all(oop args, oop ctx)
{
  oop	 string= car(args);
  size_t index= getLong(car(cdr(args)));
  oop	 insertion= car(cdr(cdr(args)));
  size_t i;
  for (i= 0; i < stringLength(insertion); ++i)
    stringSetAt(string, index++, (unsigned char)stringBytes(insertion)[i]);
  (void)ctx;
  return string;
}

static oop prim_string_compare(oop args, oop ctx)
{
  oop	 a= car(args), b= car(cdr(args));
  size_t lenA= stringLength(a), lenB= stringLength(b);
  size_t limit= lenA < lenB ? lenA : lenB;
  int	 diff= memcmp(stringBytes(a), stringBytes(b), limit);
  (void)ctx;
  if (diff) return newLong(diff);
  if (lenA == lenB) return newLong(0);
  if (lenA < lenB) return newLong(-(unsigned char)stringBytes(b)[lenA]);
  return newLong((unsigned char)stringBytes(a)[lenB]);
}

static oop prim_string_to_symbol(oop args, oop ctx)
{
  oop string= car(args);
  (void)ctx;
  return internN(stringBytes(string), stringLength(string));
}

static oop prim_symbol_to_string(oop args, oop ctx)
{
  oop obj= car(args);
  (void)ctx;
  if (is(String, obj)) return obj;
  if (!is(Symbol, obj)) fatal("symbol->string: not a symbol");
  return symbolName(obj);
}

static oop prim_lower_cell_to_long(oop args, oop ctx)
{
  (void)ctx;
  /* lossy by design, see vm-functions.l */
  return (oop)((((uintptr_t)get(car(args), LowerCell,word)) << longTagBits) | longTagMask);
}

static oop prim_long_to_lower_cell(oop args, oop ctx)
{
  (void)ctx;
  return newLowerCell((void *)(uintptr_t)((long)car(args) >> longTagBits));
}

/* source/conversion-min.l: long->string/emit, but in C */
static oop longToString(long number, long radix)
{
  char	buffer[80];
  int	index= sizeof(buffer) - 1;
  int	negative= (number < 0);
  unsigned long magnitude= negative ? -(unsigned long)number : (unsigned long)number;
  buffer[index]= 0;
  if (radix < 2 || radix > 35) fatal("long->string: unsupported radix: %ld", radix);
  do {
    int digit= (int)(magnitude % radix);
    buffer[--index]= (char)(digit <= 9 ? '0' + digit : 'a' + digit - 10);
    magnitude/= radix;
  } while (magnitude);
  if (negative) buffer[--index]= '-';
  return newStringN(buffer + index, strlen(buffer + index));
}

/* source/evaluator/arrays.l: string-ensure-zero-terminated */
static char *stringCString(oop string)
{
  size_t len= stringLength(string);
  stringSetAt(string, len, 0);
  set(string, String,size, newLong(len));
  return stringBytes(string);
}

static oop prim_number_to_string(oop args, oop ctx)
{
  long number= getLong(car(args));
  long radix= isPair(cdr(args)) ? getLong(car(cdr(args))) : 10;
  (void)ctx;
  return longToString(number, radix);
}

static oop prim_string_to_number(oop args, oop ctx)
{
  oop	 string= car(args);
  long	 radix= isPair(cdr(args)) ? getLong(car(cdr(args))) : 10;
  size_t index= 0, len= stringLength(string);
  int	 negative= 0;
  long	 number= 0;
  (void)ctx;
  if (radix < 2 || radix > 35) fatal("string->number: unsupported radix: %ld", radix);
  if (index < len && '-' == stringBytes(string)[0]) { negative= 1;  ++index; }
  if (index == len) return nil;
  for (; index < len; ++index) {
    int c= (unsigned char)stringBytes(string)[index];
    int digit= (c >= '0' && c <= '9') ? c - '0'
	     : (c >= 'a' && c <= 'z') ? c - 'a' + 10
	     : (c >= 'A' && c <= 'Z') ? c - 'A' + 10
	     : 99;
    if (digit >= radix) return nil;
    number= number * radix + digit;
  }
  return newLong(negative ? -number : number);
}

/*; arrays */
static oop prim_array(oop args, oop ctx)
{
  oop capacity= isPair(args) ? car(args) : newLong(0);
  (void)ctx;
  return newArray(getLong(capacity));
}

static oop prim_array_length(oop args, oop ctx)
{
  (void)ctx;
  return get(car(args), Array,size);
}

static oop prim_array_at(oop args, oop ctx)
{
  (void)ctx;
  return arrayAt_(car(args), getLong(car(cdr(args))));
}

static oop prim_set_array_at(oop args, oop ctx)
{
  (void)ctx;
  return arraySetAt_(car(args), getLong(car(cdr(args))), car(cdr(cdr(args))));
}

static oop prim_array_append(oop args, oop ctx)
{
  oop array= car(args);
  (void)ctx;
  arraySetAt_(array, arrayLength_(array), car(cdr(args)));
  return array;
}

static oop prim_array_insert(oop args, oop ctx)
{
  oop	 array= car(args);
  size_t index= getLong(car(cdr(args)));
  oop	 value= car(cdr(cdr(args)));
  size_t size= arrayLength_(array);
  (void)ctx;
  if (index < size) {
    arraySetAt_(array, size, nil);			/* make room */
    memmove(((oop *)get(array, Array,elements)) + index + 1,
	    ((oop *)get(array, Array,elements)) + index,
	    (size - index) * sizeof(oop));
  }
  arraySetAt_(array, index, value);
  return array;
}

/*; arithmetic, see vm-functions.l */
static oop prim_add(oop args, oop ctx)
{
  long value= 0;
  (void)ctx;
  for (; isPair(args); args= cdr(args)) value+= getLong(car(args));
  return newLong(value);
}

static oop prim_sub(oop args, oop ctx)
{
  long value;
  (void)ctx;
  if (!isPair(args)) return newLong(0);
  if (!isPair(cdr(args)))		return newLong(-getLong(car(args)));
  value= getLong(car(args));
  for (args= cdr(args); isPair(args); args= cdr(args)) value-= getLong(car(args));
  return newLong(value);
}

static oop prim_mul(oop args, oop ctx)
{
  long value= 1;
  (void)ctx;
  for (; isPair(args); args= cdr(args)) value*= getLong(car(args));
  return newLong(value);
}

static oop prim_div(oop args, oop ctx)
{
  long value;
  (void)ctx;
  if (!isPair(args)) fatal("operator '/': at least one argument is needed");
  value= getLong(car(args));
  for (args= cdr(args); isPair(args); args= cdr(args)) value/= getLong(car(args));
  return newLong(value);
}

static oop prim_eq(oop args, oop ctx)
{
  oop lhs= car(args), rhs= car(cdr(args));
  (void)ctx;
  switch (getType(lhs)) {
    case Long:		return (isLong(rhs) && (getLong(lhs) == getLong(rhs))) ? intern("true") : nil;
    case Undefined:	return (rhs == nil) ? intern("true") : nil;
    case String:
      return (is(String, rhs) && (stringLength(lhs) == stringLength(rhs))
	      && !memcmp(stringBytes(lhs), stringBytes(rhs), stringLength(lhs))) ? intern("true") : nil;
    default:		return (lhs == rhs) ? intern("true") : nil;
  }
}

static oop prim_not(oop args, oop ctx)
{
  (void)ctx;
  return car(args) ? nil : intern("true");
}

#define relation(NAME, OP)						\
  static oop NAME(oop args, oop ctx)					\
  {									\
    long current;							\
    (void)ctx;								\
    if (!isPair(args)) return intern("true");				\
    current= getLong(car(args));					\
    for (args= cdr(args); isPair(args); args= cdr(args)) {		\
      long next= getLong(car(args));					\
      if (!(current OP next)) return nil;				\
      current= next;							\
    }									\
    return intern("true");						\
  }

relation(prim_lt, <)
relation(prim_le, <=)
relation(prim_gt, >)
relation(prim_ge, >=)

#define binary(NAME, OP)						\
  static oop NAME(oop args, oop ctx)					\
  {									\
    oop result= nil;							\
    (void)ctx;								\
    if (!isPair(args)) fatal("operator: at least one argument is needed"); \
    result= car(args);							\
    for (args= cdr(args); isPair(args); args= cdr(args))		\
      result= newLong(getLong(result) OP getLong(car(args)));		\
    return result;							\
  }

binary(prim_bitand, &)
binary(prim_bitor, |)
binary(prim_bitxor, ^)

static oop prim_bitnot(oop args, oop ctx)
{
  (void)ctx;
  return newLong(~getLong(car(args)));
}

static oop prim_shift(oop args, oop ctx)
{
  long value= getLong(car(args));
  long shift= getLong(car(cdr(args)));
  (void)ctx;
  if (shift < 0) {
    if (-shift >= 63) return newLong(value < 0 ? -1 : 0);
    return newLong(value >> -shift);
  }
  if (shift >= 63) return newLong(0);
  return newLong(value << shift);
}

/*; the rest of the evaluator interface */
static oop prim_car(oop args, oop ctx)
{
  oop obj= car(args);
  (void)ctx;
  if (!isPair(obj) && obj) fatal("car: not a pair");
  return car(obj);
}

static oop prim_cdr(oop args, oop ctx)
{
  oop obj= car(args);
  (void)ctx;
  if (!isPair(obj) && obj) fatal("cdr: not a pair");
  return cdr(obj);
}

static oop prim_cons(oop args, oop ctx)
{
  (void)ctx;
  return newPair(car(args), car(cdr(args)));
}

static oop prim_set_car(oop args, oop ctx)
{
  (void)ctx;
  return set(car(args), Pair,head, car(cdr(args)));
}

static oop prim_set_cdr(oop args, oop ctx)
{
  (void)ctx;
  return set(car(args), Pair,tail, car(cdr(args)));
}

#define predicate(NAME, TYPE, PRINTNAME)				\
  static oop NAME(oop args, oop ctx)					\
  {									\
    (void)ctx;								\
    arity(args, PRINTNAME, 1);						\
    return is(TYPE, car(args)) ? intern("true") : nil;			\
  }

predicate(prim_pairP, Pair, "pair?")
predicate(prim_symbolP, Symbol, "symbol?")
predicate(prim_stringP, String, "string?")
predicate(prim_arrayP, Array, "array?")
predicate(prim_formP, Form, "form?")
predicate(prim_fixedP, Fixed, "fixed?")
predicate(prim_envP, Env, "env?")

/*; I/O */
static oop printObject(oop stream, oop obj, int storing)
{
  fdump_(streamFile(stream, "print"), obj, storing);
  return obj;
}

static oop prim_print(oop args, oop ctx)
{
  oop result= nil;
  (void)ctx;
  for (; isPair(args); args= cdr(args)) result= printObject(standardOutput, car(args), 0);
  return result;
}

static oop prim_print_all(oop args, oop ctx)
{
  oop stream= car(args);
  oop result= nil;
  (void)ctx;
  for (args= cdr(args); isPair(args); args= cdr(args)) result= printObject(stream, car(args), 0);
  return result;
}

static oop prim_dump(oop args, oop ctx)
{
  oop result= nil;
  (void)ctx;
  for (; isPair(args); args= cdr(args)) result= printObject(debugOutput, car(args), 1);
  return result;
}

static oop prim_dump_all(oop args, oop ctx)
{
  oop stream= car(args);
  oop result= nil;
  (void)ctx;
  for (args= cdr(args); isPair(args); args= cdr(args)) result= printObject(stream, car(args), 1);
  return result;
}

static oop prim_warn(oop args, oop ctx)
{
  oop result= nil;
  (void)ctx;
  fprintf(streamFile(standardError, "warn"), "\nWARNING: ");
  for (; isPair(args); args= cdr(args)) result= printObject(standardError, car(args), 0);
  return result;
}

static oop prim_read(oop args, oop ctx)
{
  FILE *stream;
  (void)ctx;
  arity(args, "read", 1);
  stream= streamFile(car(args), "read");
  {
    oop form= readToplevel(stream);
    return END == form ? theEnd : form;
  }
}

static oop prim_load(oop args, oop ctx)
{
  oop	 path= car(args);
  FILE	*stream;
  oop	 prevPath= currentPath;			GC_PROTECT(prevPath);
  long	 prevLine= sourceLine;
  char	*cpath= stringCString(path);
  (void)ctx;
  if (!is(String, path)) fatal("load: not a string");
  stream= fopen(cpath, "r");
  if (!stream) fatal("load: cannot open %s", cpath);
  processStream(stream, cpath);
  fclose(stream);
  currentPath= prevPath;
  sourceLine= prevLine;
  GC_UNPROTECT(prevPath);
  return theEnd;
}

static oop prim_exit(oop args, oop ctx)
{
  (void)ctx;
  exit(isPair(args) ? (int)getLong(car(args)) : 0);
  return nil;
}

static oop prim_abort(oop args, oop ctx)
{
  (void)args;  (void)ctx;
  exit(1);
  return nil;
}

/* source/platforms/libc/streams.l, but the host keeps its own FILE*s */
static oop prim_file_open(oop args, oop ctx)
{
  FILE *file= fopen(stringCString(car(args)), stringCString(car(cdr(args))));
  (void)ctx;
  return file ? newLowerCell((void *)file) : nil;
}

static oop prim_file_close(oop args, oop ctx)
{
  oop handle= car(args);
  (void)ctx;
  if (!is(LowerCell, handle)) fatal("file-close: not a file handle");
  if (fclose((FILE *)get(handle, LowerCell,word))) return nil;
  set(handle, LowerCell,word, 0);
  return intern("true");
}

static oop prim_file_read_byte(oop args, oop ctx)
{
  oop handle= car(args);
  int c;
  (void)ctx;
  if (!is(LowerCell, handle)) fatal("file-read-byte: not a file handle");
  c= getc((FILE *)get(handle, LowerCell,word));
  return (EOF == c) ? nil : newLong(c);
}

static oop prim_file_write_byte(oop args, oop ctx)
{
  oop character= car(args);
  oop handle= car(cdr(args));
  (void)ctx;
  if (!is(LowerCell, handle)) fatal("file-write-byte: not a file handle");
  if (EOF == putc((int)getLong(character), (FILE *)get(handle, LowerCell,word))) return nil;
  return intern("true");
}

static oop prim_file_stream(oop args, oop ctx)
{
  (void)ctx;
  return car(args);		/* the host's streams are the handles */
}

static oop prim_file_modification_time(oop args, oop ctx)
{
  struct stat st;
  (void)ctx;
  if (stat(stringCString(car(args)), &st)) return nil;
  return newLong((long)st.st_mtime);
}

static oop prim_char_at(oop args, oop ctx)
{
  oop string= car(args);
  size_t index= getLong(car(cdr(args)));
  (void)ctx;
  if (!is(String, string)) fatal("char-at: not a string");
  if (index >= stringLength(string)) return newLong(0);
  return newLong((unsigned char)stringBytes(string)[index]);
}

static oop prim_set_char_at(oop args, oop ctx)
{
  oop string= car(args);
  size_t index= getLong(car(cdr(args)));
  oop value= car(cdr(cdr(args)));
  (void)ctx;
  stringSetAt(string, index, (int)getLong(value));
  return value;
}

static oop prim_working_directory(oop args, oop ctx)
{
  char buffer[4096];
  (void)args;  (void)ctx;
  if (!getcwd(buffer, sizeof(buffer))) fatal("working-directory: getcwd failed");
  return newString(buffer);
}

static oop prim_set_working_directory(oop args, oop ctx)
{
  oop path= car(args);
  (void)ctx;
  if (chdir(stringCString(path))) fatal("set-working-directory: chdir failed for %s", stringCString(path));
  return nil;
}

/*;
;;; the primitive environment
;;;
;;; source/evaluator/vm-late.l: populate-env-with-maru-primitives
 */

typedef struct {
  const char	*name;
  imp_t		imp;
  int		fixed;
} primitive_t;

static primitive_t primitives[]= {
  { "define",			prim_define,			1 },
  { "lambda",			prim_lambda,			1 },
  { "let",			prim_let,			1 },
  { "set",			prim_set,			1 },
  { "while",			prim_while,			1 },
  { "if",			prim_if,			1 },
  { "or",			prim_or,			1 },
  { "and",			prim_and,			1 },
  { "quote",			prim_quote,			1 },

  { "eval",			prim_eval,			0 },
  { "apply",			prim_apply,			0 },
  { "expand",			prim_expand,			0 },
  { "encode",			prim_encode,			0 },
  { "environment",		prim_environment,		0 },
  { "environment-define",	prim_environment_define,	0 },
  { "defined?",			prim_defined,			0 },
  { "variable",			prim_variable,			0 },
  { "form",			prim_form,			0 },
  { "fixed",			prim_fixed,			0 },
  { "current-globals",		prim_current_globals,		0 },
  { "set-current-globals",	prim_set_current_globals,	0 },
  { "global-variable?",		prim_global_variable,		0 },
  { "type-of",			prim_type_of,			0 },
  { "allocate",			prim_allocate,			0 },
  { "allocate-data",		prim_allocate_data,		0 },
  { "oop-at",			prim_oop_at,			0 },
  { "set-oop-at",		prim_set_oop_at,		0 },
  { "copy-oops",		prim_copy_oops,			0 },

  { "string",			prim_string,			0 },
  { "string-length",		prim_string_length,		0 },
  { "string-at",		prim_string_at,			0 },
  { "set-string-at",		prim_set_string_at,		0 },
  { "set-string-length",	prim_set_string_length,		0 },
  { "string-append",		prim_string_append,		0 },
  { "string-insert",		prim_string_insert,		0 },
  { "string-insert-all",	prim_string_insert_all,		0 },
  { "string-compare",		prim_string_compare,		0 },
  { "lower-cell->long",		prim_lower_cell_to_long,	0 },
  { "long->lower-cell",		prim_long_to_lower_cell,	0 },
  { "number->string",		prim_number_to_string,		0 },
  { "integer->string",		prim_number_to_string,		0 },
  { "string->number",		prim_string_to_number,		0 },
  { "string->integer",		prim_string_to_number,		0 },
  { "string->symbol",		prim_string_to_symbol,		0 },
  { "symbol->string",		prim_symbol_to_string,		0 },
  { "char-at",			prim_char_at,			0 },
  { "set-char-at",		prim_set_char_at,		0 },

  { "array",			prim_array,			0 },
  { "array-length",		prim_array_length,		0 },
  { "array-at",			prim_array_at,			0 },
  { "set-array-at",		prim_set_array_at,		0 },
  { "array-append",		prim_array_append,		0 },
  { "array-insert",		prim_array_insert,		0 },

  { "+",			prim_add,			0 },
  { "-",			prim_sub,			0 },
  { "*",			prim_mul,			0 },
  { "/",			prim_div,			0 },
  { "=",			prim_eq,			0 },
  { "not",			prim_not,			0 },
  { "<",			prim_lt,			0 },
  { "<=",			prim_le,			0 },
  { ">",			prim_gt,			0 },
  { ">=",			prim_ge,			0 },
  { "bitwise-and",		prim_bitand,			0 },
  { "bitwise-or",		prim_bitor,			0 },
  { "bitwise-xor",		prim_bitxor,			0 },
  { "bitwise-not",		prim_bitnot,			0 },
  { "bitwise-shift",		prim_shift,			0 },

  { "car",			prim_car,			0 },
  { "cdr",			prim_cdr,			0 },
  { "cons",			prim_cons,			0 },
  { "set-car",			prim_set_car,			0 },
  { "set-cdr",			prim_set_cdr,			0 },
  { "pair?",			prim_pairP,			0 },
  { "symbol?",			prim_symbolP,			0 },
  { "string?",			prim_stringP,			0 },
  { "array?",			prim_arrayP,			0 },
  { "form?",			prim_formP,			0 },
  { "fixed?",			prim_fixedP,			0 },
  { "env?",			prim_envP,			0 },

  { "print",			prim_print,			0 },
  { "print-all",		prim_print_all,			0 },
  { "dump",			prim_dump,			0 },
  { "dump-all",			prim_dump_all,			0 },
  { "warn",			prim_warn,			0 },
  { "read",			prim_read,			0 },
  { "load",			prim_load,			0 },
  { "exit",			prim_exit,			0 },
  { "abort",			prim_abort,			0 },

  { "file-open",		prim_file_open,			0 },
  { "file-close",		prim_file_close,		0 },
  { "file-read-byte",		prim_file_read_byte,		0 },
  { "file-write-byte",		prim_file_write_byte,		0 },
  { "file-stream",		prim_file_stream,		0 },
  { "file-modification-time",	prim_file_modification_time,	0 },
  { "working-directory",	prim_working_directory,		0 },
  { "set-working-directory",	prim_set_working_directory,	0 },

  { 0,				0,				0 }
};

static oop newTargetFunction(const char *name, imp_t imp)
{
  oop cell= newLowerCell((void *)imp);			GC_PROTECT(cell);
  oop fn= newOops(TargetFunction);			GC_PROTECT(fn);
  set(fn, TargetFunction,program_code, cell);
  set(fn, TargetFunction,name, newString(name));
  GC_UNPROTECT(fn);  GC_UNPROTECT(cell);
  return fn;
}

static void instantiatePrimitives(void)
{
  primitive_t *primitive;
  for (primitive= primitives; primitive->name; ++primitive) {
    oop fn= newTargetFunction(primitive->name, primitive->imp);	GC_PROTECT(fn);
    oop value= primitive->fixed ? newFixed(fn) : fn;		GC_PROTECT(value);
    environmentDefine(theMaru, intern(primitive->name), value);
    GC_UNPROTECT(value);  GC_UNPROTECT(fn);
  }
}

/*;
;;; main
*/

static void processStream(FILE *stream, const char *path)
{
  setCurrentSource(path);
  for (;;) {
    oop form= readForm(stream);
    if (END == form) break;
    GC_PROTECT(form);
    if (verbosity) { dumplno(form);  fflush(stdout); }
    {
      oop result= expandEncodeEval(form);		GC_PROTECT(result);
      if (verbosity) { printf(" => ");  dumplno(result); }
      GC_UNPROTECT(result);
    }
    GC_UNPROTECT(form);
  }
}

static void processFile(const char *path)
{
  FILE *stream= fopen(path, "r");
  if (!stream) {
    int error= errno;
    fprintf(stderr, "\nerror: ");
    errno= error;
    perror(path);
    exit(1);
  }
  processStream(stream, path);
  fclose(stream);
}

static void defineCLArgument(const char *name, const char *value)
{
  oop converted= newString(value);
  if (!strcmp(value, "true"))		converted= intern("true");
  else if (!strcmp(value, "false"))	converted= nil;
  else {
    char *end= 0;
    long number= strtol(value, &end, 10);
    if (end && !*end && (end != value)) converted= newLong(number);
  }
  environmentDefine(theGlobals, intern(name), converted);
}

static void initialize(void)
{
  GC_init();
  GC_add_root(&allSymbols);
  GC_add_root(&currentPath);
  GC_add_root(&theMaru);
  GC_add_root(&theGlobals);
  GC_add_root(&theEnd);

  END= _newBits(Data, 8, __FILE__, __LINE__);
  END_OF_LIST= _newBits(Data, 8, __FILE__, __LINE__);
  GC_add_root(&END);
  GC_add_root(&END_OF_LIST);

  allSymbols= newArray(256);
  symbolBuckets= calloc(symbolTableSize, sizeof(int));
  if (!symbolBuckets) fatal("out of memory");

  s_quote= intern("quote");
  s_quasiquote= intern("quasiquote");
  s_unquote= intern("unquote");
  s_unquote_splicing= intern("unquote-splicing");
  s_dot= intern(".");
  s_let= intern("let");
  s_define= intern("define");
  s_lambda= intern("lambda");
  s_set= intern("set");
  s_if= intern("if");
  s_while= intern("while");
  s_and= intern("and");
  s_or= intern("or");

  /* *maru*: the primitive env, and maru-user: the global env */
  theMaru= newEnvironment(nil, 0, 0);
  set(theMaru, Env,name, newString("maru"));
  theGlobals= newEnvironment(theMaru, 0, 0);
  set(theGlobals, Env,name, newString("maru-user"));

  {
    oop name= newString("+end+");			GC_PROTECT(name);
    theEnd= newSymbol(name);
    GC_UNPROTECT(name);
  }
  environmentDefine(theMaru, intern("+end+"), theEnd);
  environmentDefine(theMaru, intern("true"), intern("true"));
  environmentDefine(theMaru, intern("*verbosity*"), newLong(verbosity));
  environmentDefine(theMaru, intern("*optimised*"), newLong(optimize));

  /* the *expanders* etc. arrays, as in populate-env-with-maru-primitives */
  environmentDefine(theMaru, intern("*expanders*"), newArray(0));
  environmentDefine(theMaru, intern("*encoders*"), newArray(0));
  environmentDefine(theMaru, intern("*evaluators*"), newArray(0));
  environmentDefine(theMaru, intern("*applicators*"), newArray(0));

  instantiatePrimitives();

  /* the standard streams; see source/evaluator/vm-with-file-support.l */
  standardInput= newHostStream(stdin);
  standardOutput= newHostStream(stdout);
  standardError= newHostStream(stderr);
  debugOutput= newHostStream(stderr);
  environmentDefine(theMaru, intern("*standard-input*"), standardInput);
  environmentDefine(theMaru, intern("*standard-output*"), standardOutput);
  environmentDefine(theMaru, intern("*error-output*"), standardError);
  environmentDefine(theMaru, intern("*debug-output*"), debugOutput);

  captureWellKnownGlobals();

  f_define= maybeObjectInEnv(theMaru, s_define, Fixed);
  f_lambda= maybeObjectInEnv(theMaru, s_lambda, Fixed);
  f_let=    maybeObjectInEnv(theMaru, s_let,    Fixed);
  f_set=    maybeObjectInEnv(theMaru, s_set,    Fixed);
  f_while=  maybeObjectInEnv(theMaru, s_while,  Fixed);
  f_if=     maybeObjectInEnv(theMaru, s_if,     Fixed);
  f_and=    maybeObjectInEnv(theMaru, s_and,    Fixed);
  f_or=     maybeObjectInEnv(theMaru, s_or,     Fixed);
  f_quote=  maybeObjectInEnv(theMaru, s_quote,  Fixed);
  if (!(f_define && f_lambda && f_let && f_set && f_quote))
    fatal("initialize: failed to instantiate the fixed vm-functions");
}

int main(int argc, char **argv)
{
  GC_set_stack_bottom(&argc);
  initialize();
  signal(SIGINT, sigint);

  while (--argc) {
    char *arg= *++argv;
    if      (!strcmp(arg, "-v"))	{ ++verbosity;  set(environmentDefine(theMaru, intern("*verbosity*"), nil), Variable,value, newLong(verbosity)); }
    else if (!strcmp(arg, "-O"))	{ ++optimize;   set(environmentDefine(theMaru, intern("*optimised*"), nil), Variable,value, newLong(optimize)); }
    else if (!strcmp(arg, "-g"))	optimize= 0;
    else if (!strcmp(arg, "-d"))	;
    else if (!strcmp(arg, "-p"))	;
    else if (!strcmp(arg, "--define")) {
      if (argc < 3) fatal("--define requires two arguments");
      defineCLArgument(argv[1], argv[2]);
      argv+= 2;  argc-= 2;
    }
    else if (!strcmp(arg, "--call")) {
      if (argc < 2) fatal("--call requires an argument");
      {
	oop form= newPair(intern(*++argv), nil);	GC_PROTECT(form);
	expandEncodeEval(form);
	GC_UNPROTECT(form);
      }
      --argc;
    }
    else if (!strcmp(arg, "-")) {
      if (isatty(0)) printf("maru> ");
      processStream(stdin, "<stdin>");
    }
    else processFile(arg);
  }
  return 0;
}
