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
  Data			= 3,
  Undefined		= 4,
  Long			= 5,
  Fixed			= 6,
  Symbol		= 7,
  Array			= 8,
  MemoryBlock		= 9,
  String		= 10,
  Expr			= 11,
  Form			= 12,
  Variable		= 13,
  Env			= 14,
  Context		= 15,
  Pair			= 16,
  TargetFunction	= 17,
  LowerCell		= 18,

  Subr			= 19	/* host only: a primitive function */
};

struct Data		{ };			/* raw bytes, never traced */
struct Long		{ long bits; };		/* unused: longs are immediate */
struct String		{ oop size, elements; };	/* elements: <data> */
struct Symbol		{ oop name; };			/* name: <string> */
struct Pair		{ oop head, tail, source; };	/* +host source */
struct Array		{ oop size, elements; };	/* elements: <data> */
struct MemoryBlock	{ oop size, elements; };
struct Expr		{ oop parameters, body, env, ctx; };
struct Form		{ oop function, symbol; };
struct Fixed		{ oop function; };
struct Subr		{ oop name;  imp_t imp; };
struct Variable		{ oop name, value, env, index; };
struct Env		{ oop parent, level, offset, bindings, stable, name; };
struct Context		{ oop home, env, bindings, callee; };
struct TargetFunction	{ oop program_code; };
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
  struct Subr		Subr;
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
    if (obj && !((uintptr_t)obj & 1) && !ptr2hdr(obj)->used)	fatal("%s:%i: attempt to access dead object %s\n", file, line, name);
    if (!is(type, obj))						fatal("%s:%i: typecheck failed for %s (%i != %i)\n", file, line, name, type, getType(obj));
    return obj;
  }
#endif

#define get(OBJ, TYPE, FIELD)		(checkType(OBJ, TYPE)->TYPE.FIELD)
#define set(OBJ, TYPE, FIELD, VALUE)	(checkType(OBJ, TYPE)->TYPE.FIELD= (VALUE))

/*;
;;; heap
*/

static oop _newBits(int type, size_t size)	{ oop obj= GC_malloc_atomic(size);	setType(obj, type);  return obj; }
static oop _newOops(int type, size_t size)	{ oop obj= GC_malloc(size);		setType(obj, type);  return obj; }

#define	newDataSized(SIZE)	_newBits(Data, (SIZE))
#define	newOops(TYPE)		_newOops(TYPE, sizeof(struct TYPE))

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

static oop cadr(oop obj)	{ return car(cdr(obj)); }

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

/* a NUL terminated view of the string bytes; see newStringN */
static char *stringCString(oop string)	{ return stringBytes(string); }

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
  elements= _newOops(Data, capacity * sizeof(oop));	GC_PROTECT(elements);
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
  oop obj= _newBits(LowerCell, sizeof(void *));
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

static oop	currentPath= nil;
static oop	currentLine= nil;
static oop	currentSource= nil;

static oop	s_quote, s_quasiquote, s_unquote, s_unquote_splicing, s_dot;

static int	verbosity= 0;
static int	optimize= 0;

static void fdump_(FILE *stream, oop obj, int storing);

/*;
;;; errors
*/

/* the source position for diagnostics; see fatal */
static oop	fatalPath= nil;
static oop	fatalLine= nil;

static void fatal(char *reason, ...)
{
  va_list ap;
  if (reason) {
    if (is(String, fatalPath)) fprintf(stderr, "\n%s:%ld: ", stringBytes(fatalPath), getLong(fatalLine));
    else		       fprintf(stderr, "\n");
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
static int isDigit10Char(int c)	{ return (0 <= c && c <= 127 && (CHAR_DIGIT10 & chartab[c])); }
static int isDigit16Char(int c)	{ return (0 <= c && c <= 127 && (CHAR_DIGIT16 & chartab[c])); }
static int isLetterChar(int c)	{ return (0 <= c && c <= 127 && (CHAR_LETTER  & chartab[c])) || (c >= 128); }

static oop	END;			/* end of input */
static oop	END_OF_LIST;		/* the closing delimiter */

static FILE	*sourceStream;
static long	sourceLine;

static void setCurrentSource(const char *path, long line)
{
  currentPath= newString(path);
  currentLine= newLong(line);
  currentSource= newPair(currentPath, currentLine);
  fatalPath= currentPath;
  fatalLine= currentLine;
}

static void setSource(oop obj, oop source)
{
  if (!isPair(obj)) return;
  if (nil == get(obj, Pair,source)) set(obj, Pair,source, source);
  setSource(get(obj, Pair,head), source);
  setSource(get(obj, Pair,tail), source);
}

static int nextChar(void)
{
  int c= getc(sourceStream);
  if ('\n' == c) {
    ++sourceLine;
    fatalLine= newLong(sourceLine);
  }
  return c;
}

static void unreadChar(int c, FILE *stream)
{
  if (EOF == c) return;
  if ('\n' == c) --sourceLine;
  ungetc(c, stream);
}

static int peekChar(void)	{ int c= nextChar();  unreadChar(c, sourceStream);  return c; }

static int digitValue(int c)
{
  if ('0' <= c && c <= '9') return c - '0';
  if ('a' <= c && c <= 'z') return c - 'a' + 10;
  if ('A' <= c && c <= 'Z') return c - 'A' + 10;
  fatal("illegal digit in character escape: %c", c);
  return 0;
}

static int isDigit8Char(int c)	{ return '0' <= c && c <= '7'; }

/* source/evaluator/reader.l: read/char */
static int readChar_(int c)
{
  if ('\\' != c) return c;
  c= nextChar();
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
      int a= nextChar(), b= nextChar(), c2= nextChar(), d= nextChar();
      if (!(isDigit16Char(a) && isDigit16Char(b) && isDigit16Char(c2) && isDigit16Char(d)))
	fatal("illegal character escape: \\u");
      return (digitValue(a) << 24) | (digitValue(b) << 16) | (digitValue(c2) << 8) | digitValue(d);
    }
    case 'x': {
      int x, n;
      if (!isDigit16Char(peekChar())) fatal("illegal hexadecimal character escape");
      x= digitValue(nextChar());
      if ((n= peekChar()), isDigit16Char(n)) x= x * 16 + digitValue(nextChar());
      return x;
    }
    default:
      if ('0' <= c && c <= '7') {
	int x= digitValue(c), n;
	if (((n= peekChar()), isDigit8Char(n))) x= x * 8 + digitValue(nextChar());
	if (((n= peekChar()), isDigit8Char(n))) x= x * 8 + digitValue(nextChar());
	return x;
      }
      if (isAlphaChar(c) || isDigit10Char(c)) fatal("illegal character escape: \\%c", c);
      return c;
  }
}

/* source/evaluator/reader.l: read/number */
static oop readNumber(int c)
{
  static struct buffer buf= BUFFER_INITIALISER;
  int	negative= 0;
  int	base= 10;
  buffer_reset(&buf);
  if ('-' == c) negative= 1;
  else if ('+' == c) ;
  else buffer_append(&buf, c);
  while (isDigit10Char(peekChar())) buffer_append(&buf, nextChar());
  if (('x' == peekChar()) && (1 == buffer_position(&buf)) && ('0' == buffer_contents(&buf)[0])) {
    nextChar();
    base= 16;
    buffer_reset(&buf);
    while (isDigit16Char(peekChar())) buffer_append(&buf, nextChar());
  }
  {
    char *end= 0;
    long value= strtol(buffer_contents(&buf), &end, base);
    if (end && *end) fatal("invalid number in source code: %s", buffer_contents(&buf));
    return newLong(negative ? -value : value);
  }
}

/* source/evaluator/reader.l: read/symbol */
static oop readSymbol(int c)
{
  static struct buffer buf= BUFFER_INITIALISER;
  buffer_reset(&buf);
  buffer_append(&buf, c);
  while (isLetterChar(peekChar()) || isDigit10Char(peekChar())) buffer_append(&buf, nextChar());
  return intern(buffer_contents(&buf));
}

/* source/evaluator/reader.l: read/string-literal */
static oop readStringLiteral(void)
{
  static struct buffer buf= BUFFER_INITIALISER;
  buffer_reset(&buf);
  for (;;) {
    int c= nextChar();
    if ((EOF == c) || ('"' == c)) break;
    buffer_append(&buf, readChar_(c));
  }
  return newStringN(buffer_contents(&buf), buffer_position(&buf));
}

static oop readNested(void);
static oop readToplevel(void);

/* source/evaluator/reader.l: read/list */
static oop readList(int delimiter)
{
  oop head= newPair(nil, nil);				GC_PROTECT(head);
  oop tail= head;
  oop element= nil;					GC_PROTECT(element);
  nextChar();						/* drop the opening delimiter */
  for (;;) {
    element= readNested();
    if (END == element) fatal("missing closing delimiter '%c' while reading list", delimiter);
    if (END_OF_LIST == element) {
      if (delimiter != nextChar()) fatal("missing closing delimiter '%c' while reading list", delimiter);
      break;
    }
    if (s_dot == element) {
      oop rest= readToplevel();				GC_PROTECT(rest);
      if (delimiter != nextChar()) fatal("missing closing delimiter '%c' after .", delimiter);
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
static oop readQuote(oop prefix)
{
  oop quoted= readToplevel();				GC_PROTECT(quoted);
  oop result= newPair(prefix, newPair(quoted, nil));
  GC_UNPROTECT(quoted);
  return result;
}

/* source/evaluator/reader.l: read-nested */
static oop readNested(void)
{
  for (;;) {
    int c= peekChar();
    if ((EOF == c) || (' ' == c) || ('\t' == c) || ('\n' == c) || ('\v' == c) || ('\f' == c) || ('\r' == c)) {
      if (EOF == c) return END;
      nextChar();
      continue;
    }
    switch (c) {
      case '?':		nextChar();  return newLong((unsigned char)readChar_(nextChar()));
      case '-':		nextChar();  return isDigit10Char(peekChar()) ? readNumber(c) : readSymbol(c);
      case '\'':	nextChar();  return readQuote(s_quote);
      case '`':		nextChar();  return readQuote(s_quasiquote);
      case ',':		nextChar();
			if ('@' == peekChar()) { nextChar();  return readQuote(s_unquote_splicing); }
			return readQuote(s_unquote);
      case '(':		return readList(')');
      case '[':		return readList(']');
      case '{':		return readList('}');
      case ')': case ']': case '}':	return END_OF_LIST;
      case ';':		while ((EOF != (c= nextChar())) && ('\n' != c) && ('\r' != c)) ;  continue;
      case '"':		nextChar();  return readStringLiteral();
      default:
	if (isLetterChar(c))	return readSymbol(nextChar());
	if (isDigit10Char(c))	return readNumber(nextChar());
	if (c < 0) return END;
	fatal("illegal character: 0x%02x '%c'", c, c);
    }
  }
}

/* source/evaluator/reader.l: read-toplevel */
static oop readToplevel(void)
{
  int c= peekChar();
  switch (c) {
    case '(':	return readList(')');
    case '[':	return readList(']');
    case '{':	return readList('}');
    case ')': case ']': case '}':
      fatal("unexpected close paren");
  }
  return readNested();
}

/*; read a single form and attach the current source position to it */
static oop readForm(void)
{
  long	line= sourceLine;
  oop	form= readToplevel();
  if (END == form) return END;
  {
    oop path= currentPath;
    oop source= newPair(path, newLong(line));
    setSource(form, source);
  }
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
    case Subr:		fprintf(stream, "%s", symbolBytes(get(obj, Subr,name)));		break;
    case Fixed:		fprintf(stream, "Fixed<");  fdump_(stream, get(obj, Fixed,function), storing);  fprintf(stream, ">");  break;
    case Form:		fprintf(stream, "Form<");  fdump_(stream, get(obj, Form,function), storing);  fprintf(stream, ">");  break;
    case Expr:		fprintf(stream, "Expr<");  fdump_(stream, get(obj, Expr,parameters), storing);  fprintf(stream, ">");  break;
    case Variable:	fprintf(stream, "%s", symbolBytes(get(obj, Variable,name)));  break;
    default:		fprintf(stream, "<type %i>", getType(obj));			break;
  }
}

static void dump_(FILE *stream, oop obj)	{ fdump_(stream, obj, 1);  fflush(stream); }

static void dumplno(oop obj)			{ dump_(stdout, obj);  putchar('\n');  fflush(stdout); }

/*;
;;; eval and bootstrapping
*/

static oop expandEncodeEval(oop form)	{ return form; }

/*;
;;; main
*/

static void processStream(FILE *stream, const char *path)
{
  sourceStream= stream;
  sourceLine= 1;
  setCurrentSource(path, 1);
  for (;;) {
    oop form= readForm();
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

static void initialize(void)
{
  GC_init();
  GC_add_root(&allSymbols);
  GC_add_root(&currentPath);
  GC_add_root(&currentLine);
  GC_add_root(&currentSource);

  END= _newBits(Data, 8);
  END_OF_LIST= _newBits(Data, 8);
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
}

int main(int argc, char **argv)
{
  initialize();
  signal(SIGINT, sigint);

  while (--argc) {
    char *arg= *++argv;
    if      (!strcmp(arg, "-v"))	++verbosity;
    else if (!strcmp(arg, "-O"))	++optimize;
    else if (!strcmp(arg, "-g"))	optimize= 0;
    else if (!strcmp(arg, "--define")) {
      if (argc < 3) fatal("--define requires two arguments");
      /* TODO: pass it to the lisp side once the primitive env exists */
      ++argv;  --argc;
      ++argv;  --argc;
    }
    else if (!strcmp(arg, "-"))		processStream(stdin, "<stdin>");
    else				processFile(arg);
  }
  return 0;
}
