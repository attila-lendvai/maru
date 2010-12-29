#include <stdio.h>
#include <string.h>
#include <signal.h>
#include <stdarg.h>

extern int isatty(int);

#define GC_APP_HEADER	int type;

#include "gc.c"
#include "buffer.c"

union Object;

typedef union Object *oop;

typedef oop (*imp_t)(oop args, oop env);

#define nil ((oop)0)

enum { Undefined, Long, String, Symbol, Pair, _Array, Array, Expr, Form, Fixed, Subr };

struct Long	{ long  bits; };
struct String	{ oop   size;  char *bits; };
struct Symbol	{ char *bits; };
struct Pair	{ oop 	head, tail; };
struct Array	{ oop   size, _array; };
struct Expr	{ oop 	defn, env; };
struct Form	{ oop 	function; };
struct Fixed	{ oop   function; };
struct Subr	{ imp_t imp;  char *name; };

union Object {
  struct Long	Long;
  struct String	String;
  struct Symbol	Symbol;
  struct Pair	Pair;
  struct Array	Array;
  struct Expr	Expr;
  struct Form	Form;
  struct Fixed	Fixed;
  struct Subr	Subr;
};

static void fatal(char *reason, ...);

#define setType(OBJ, TYPE)		(ptr2hdr(OBJ)->type= (TYPE))

static inline int getType(oop obj)	{ return obj ? ptr2hdr(obj)->type : Undefined; }

#define is(TYPE, OBJ)			((OBJ) && (TYPE == getType(OBJ)))

#if defined(NDEBUG)
# define checkType(OBJ, TYPE) OBJ
#else
# define checkType(OBJ, TYPE) _checkType(OBJ, TYPE, #TYPE, __FILE__, __LINE__)
  static inline oop _checkType(oop obj, int type, char *name, char *file, int line)
  {
    if (obj && !ptr2hdr(obj)->used)	fatal("%s:%i: attempt to access dead object %s\n", file, line, name);
    if (!is(type, obj))			fatal("%s:%i: typecheck failed for %s (%i != %i)\n", file, line, name, type, getType(obj));
    return obj;
  }
#endif

#define get(OBJ, TYPE, FIELD)		(checkType(OBJ, TYPE)->TYPE.FIELD)
#define set(OBJ, TYPE, FIELD, VALUE)	(checkType(OBJ, TYPE)->TYPE.FIELD= (VALUE))

#define getHead(OBJ)	get(OBJ, Pair,head)
#define getTail(OBJ)	get(OBJ, Pair,tail)

#define setHead(OBJ, VAL)	set(OBJ, Pair,head, VAL)
#define setTail(OBJ, VAL)	set(OBJ, Pair,tail, VAL)

#define getLong(X)	get((X), Long,bits)

static oop car(oop obj)			{ return is(Pair, obj) ? getHead(obj) : nil; }
static oop cdr(oop obj)			{ return is(Pair, obj) ? getTail(obj) : nil; }

static oop caar(oop obj)		{ return car(car(obj)); }
static oop cadr(oop obj)		{ return car(cdr(obj)); }
static oop cddr(oop obj)		{ return cdr(cdr(obj)); }
//static oop caaar(oop obj)		{ return car(car(car(obj))); }
//static oop cadar(oop obj)		{ return car(cdr(car(obj))); }
//static oop caddr(oop obj)		{ return car(cdr(cdr(obj))); }
//static oop cadddr(oop obj)		{ return car(cdr(cdr(cdr(obj)))); }

#define newBits(TYPE)	_newBits(TYPE, sizeof(struct TYPE))
#define newOops(TYPE)	_newOops(TYPE, sizeof(struct TYPE))

static oop _newBits(int type, size_t size)	{ oop obj= GC_malloc_atomic(size);	setType(obj, type);  return obj; }
static oop _newOops(int type, size_t size)	{ oop obj= GC_malloc(size);		setType(obj, type);  return obj; }

static oop symbols= nil;
static oop s_set= nil, s_quote= nil, s_lambda= nil, s_let= nil, s_quasiquote= nil, s_unquote= nil, s_unquote_splicing= nil, s_t= nil, s_dot= nil;
static oop f_lambda= nil, f_let= nil, f_quote= nil, f_set= nil;
static oop globals= nil, expanders= nil, encoders= nil, evaluators= nil, applicators= nil;
static oop backtrace= nil;

static int opt_b= 0, opt_v= 0;

static oop newLong(long bits)		{ oop obj= newBits(Long);	set(obj, Long,bits, bits);				return obj; }

static oop _newString(size_t len)
{
  char *gstr= GC_malloc_atomic(len + 1);	GC_PROTECT(gstr);	/* + 1 to ensure null terminator */
  oop   obj=  newOops(String);			GC_PROTECT(obj);
  set(obj, String,size, newLong(len));		GC_UNPROTECT(obj);
  set(obj, String,bits, gstr);			GC_UNPROTECT(gstr);
  return obj;
}

static oop newString(char *cstr)
{
  size_t len= strlen(cstr);
  oop obj= _newString(len);
  memcpy(get(obj, String,bits), cstr, len);
  return obj;
}

static int stringLength(oop string)
{
  return getLong(get(string, String,size));
}

static oop newSymbol(char *cstr)	{ oop obj= newBits(Symbol);	set(obj, Symbol,bits, strdup(cstr));			return obj; }
static oop newPair(oop head, oop tail)	{ oop obj= newOops(Pair);	set(obj, Pair,head, head);  set(obj, Pair,tail, tail);	return obj; }

static oop newArray(int size)
{
  int cap=  size ? size : 1;
  oop elts= _newOops(_Array, sizeof(oop) * cap);	GC_PROTECT(elts);
  oop obj=   newOops( Array);				GC_PROTECT(obj);
  set(obj, Array,_array, elts);
  set(obj, Array,size, newLong(size));			GC_UNPROTECT(obj);  GC_UNPROTECT(elts);
  return obj;
}

static int arrayLength(oop obj)
{
  return is(Array, obj) ? getLong(get(obj, Array,size)) : 0;
}

static oop arrayAt(oop array, int index)
{
  if (is(Array, array)) {
    oop elts= get(array, Array,_array);
    int size= arrayLength(array);
    if ((unsigned)index < (unsigned)size)
      return ((oop *)elts)[index];
  }
  return nil;
}

static oop arrayAtPut(oop array, int index, oop val)
{
  if (is(Array, array)) {
    oop elts= get(array, Array,_array);
    int size= arrayLength(array);
    if ((unsigned)index >= (unsigned)size) {
      GC_PROTECT(array);
      int cap= GC_size(elts) / sizeof(oop);
      if (index >= cap) {
	while (cap <= index) cap *= 2;
	oop oops= _newOops(_Array, sizeof(oop) * cap);
	memcpy((oop *)oops, (oop *)elts, size * sizeof(oop));
	elts= set(array, Array,_array, oops);
      }
      set(get(array, Array,size), Long,bits, index + 1);
      GC_UNPROTECT(array);
    }
    return ((oop *)elts)[index]= val;
  }
  return nil;
}

static oop arrayAppend(oop array, oop val)
{
  return arrayAtPut(array, arrayLength(array), val);
}

static oop oopAt(oop obj, int index)
{
  if (obj) {
    if (!GC_atomic(obj)) {
      int size= GC_size(obj) / sizeof(oop);
      if ((unsigned)index < (unsigned)size) return ((oop *)obj)[index];
    }
  }
  return nil;
}

static oop oopAtPut(oop obj, int index, oop value)
{
  if (!GC_atomic(obj)) {
    int size= GC_size(obj) / sizeof(oop);
    if ((unsigned)index < (unsigned)size) return ((oop *)obj)[index]= value;
  }
  return nil;
}

static oop newExpr(oop defn, oop env)	{ oop obj= newOops(Expr);	set(obj, Expr,defn, defn);  set(obj, Expr,env, env);	return obj; }
static oop newForm(oop function)	{ oop obj= newOops(Form);	set(obj, Form,function, function);			return obj; }
static oop newFixed(oop function)	{ oop obj= newOops(Fixed);	set(obj, Fixed,function, function);			return obj; }

static oop newSubr(imp_t imp, char *name)
{
  oop obj= newBits(Subr);
  set(obj, Subr,imp,  imp);
  set(obj, Subr,name, name);
  return obj;
}

static oop newBool(int b)		{ return b ? s_t : nil; }

static oop intern(char *cstr)
{
  oop list= nil;
  for (list= symbols;  is(Pair, list);  list= getTail(list)) {
    oop sym= getHead(list);
    if (!strcmp(cstr, get(sym, Symbol,bits))) return sym;
  }
  oop sym= nil;
  GC_PROTECT(sym);
  sym= newSymbol(cstr);
  symbols= newPair(sym, symbols);
  GC_UNPROTECT(sym);
  return sym;
}

#include "chartab.h"

static int isPrint(int c)	{ return 0 <= c && c <= 127 && (CHAR_PRINT    & chartab[c]); }
static int isAlpha(int c)	{ return 0 <= c && c <= 127 && (CHAR_ALPHA    & chartab[c]); }
static int isDigit10(int c)	{ return 0 <= c && c <= 127 && (CHAR_DIGIT10  & chartab[c]); }
static int isDigit16(int c)	{ return 0 <= c && c <= 127 && (CHAR_DIGIT16  & chartab[c]); }
static int isLetter(int c)	{ return 0 <= c && c <= 127 && (CHAR_LETTER   & chartab[c]); }

static oop read(FILE *fp);

static oop readList(FILE *fp, int delim)
{
  oop head= nil, tail= head, obj= nil;
  GC_PROTECT(head);
  GC_PROTECT(obj);
  obj= read(fp);
  if (obj == (oop)EOF) goto eof;
  head= tail= newPair(obj, nil);
  for (;;) {
    obj= read(fp);
    if (obj == (oop)EOF) goto eof;
    if (obj == s_dot) {
      obj= read(fp);
      if (obj == (oop)EOF)		fatal("missing item after .");
      tail= set(tail, Pair,tail, obj);
      obj= read(fp);
      if (obj != (oop)EOF)		fatal("extra item after .");
      goto eof;
    }
    obj= newPair(obj, nil);
    tail= set(tail, Pair,tail, obj);
  }
eof:;
  int c= getc(fp);
  if (c != delim)			fatal("EOF while reading list");
  GC_UNPROTECT(obj);
  GC_UNPROTECT(head);
  return head;
}

static int digitValue(int c)
{
  switch (c) {
    case '0' ... '9':  return c - '0';
    case 'A' ... 'Z':  return c - 'A' + 10;
    case 'a' ... 'z':  return c - 'a' + 10;
  }
  fatal("illegal digit in character escape");
  return 0;
}

static int isHexadecimal(int c)
{
  switch (c) {
    case '0' ... '9':
    case 'A' ... 'F':
    case 'a' ... 'f':
      return 1;
  }
  return 0;
}

static int isOctal(int c)
{
  return '0' <= c && c <= '7';
}

static int readChar(int c, FILE *fp)
{
  if ('\\' == c) {
    c= getc(fp);
    switch (c) {
      case 'a':   return '\a';
      case 'b':   return '\b';
      case 'f':   return '\f';
      case 'n':   return '\n';
      case 'r':   return '\r';
      case 't':   return '\t';
      case 'v':   return '\v';
      case '\'':  return '\'';
      case 'u': {
	int a= getc(fp), b= getc(fp), c= getc(fp), d= getc(fp);
	return (digitValue(a) << 24) + (digitValue(b) << 16) + (digitValue(c) << 8) + digitValue(d);
      }
      case 'x': {
	int x= 0;
	if (isHexadecimal(c= getc(fp))) {
	  x= digitValue(c);
	  if (isHexadecimal(c= getc(fp))) {
	    x= x * 16 + digitValue(c);
	    c= getc(fp);
	  }
	}
	ungetc(c, fp);
	return x;
      }
      case '0' ... '7': {
	int x= digitValue(c);
	if (isOctal(c= getc(fp))) {
	  x= x * 8 + digitValue(c);
	  if (isOctal(c= getc(fp))) {
	    x= x * 8 + digitValue(c);
	    c= getc(fp);
	  }
	}
	ungetc(c, fp);
	return x;
      }
      default:
	if (isAlpha(c) || isDigit10(c)) fatal("illegal character escape: \\%c", c);
	return c;
    }
  }
  return c;
}

static oop read(FILE *fp)
{
  for (;;) {
    int c= getc(fp);
    switch (c) {
      case EOF: {
	return (oop)EOF;
      }
      case '\t':  case '\n':  case '\r':  case ' ' : {
	continue;
      }
      case ';': {
	for (;;) {
	  c= getc(fp);
	  if ('\n' == c || '\r' == c || EOF == c) break;
	}
	continue;
      }
      case '"': {
	static struct buffer buf= BUFFER_INITIALISER;
	buffer_reset(&buf);
	for (;;) {
	  c= getc(fp);
	  if ('"' == c) break;
	  c= readChar(c, fp);
	  if (EOF == c)			fatal("EOF in string literal");
	  buffer_append(&buf, c);
	}
	oop obj= newString(buffer_contents(&buf));
	//buffer_free(&buf);
	return obj;
      }
      case '?': {
	return newLong(readChar(getc(fp), fp));
      }
      case '\'': {
	oop obj= read(fp);
	GC_PROTECT(obj);
	obj= newPair(obj, nil);
	obj= newPair(s_quote, obj);
	GC_UNPROTECT(obj);
	return obj;
      }
      case '`': {
	oop obj= read(fp);
	GC_PROTECT(obj);
	obj= newPair(obj, nil);
	obj= newPair(s_quasiquote, obj);
	GC_UNPROTECT(obj);
	return obj;
      }
      case ',': {
	oop sym= s_unquote;
	c= getc(fp);
	if ('@' == c)	sym= s_unquote_splicing;
	else		ungetc(c, fp);
	oop obj= read(fp);
	GC_PROTECT(obj);
	obj= newPair(obj, nil);
	obj= newPair(sym, obj);
	GC_UNPROTECT(obj);
	return obj;
      }
      case '0' ... '9':
      doDigits:	{
	static struct buffer buf= BUFFER_INITIALISER;
	buffer_reset(&buf);
	do {
	  buffer_append(&buf, c);
	  c= getc(fp);
	} while (isDigit10(c));
	if (('x' == c) && (1 == buf.position))
	  do {
	    buffer_append(&buf, c);
	    c= getc(fp);
	  } while (isDigit16(c));
	ungetc(c, fp);
	oop obj= newLong(strtoul(buffer_contents(&buf), 0, 0));
	//buffer_free(&buf);
	return obj;
      }
      case '(': return readList(fp, ')');      case ')': ungetc(c, fp);  return (oop)EOF;
      case '[': return readList(fp, ']');      case ']': ungetc(c, fp);  return (oop)EOF;
      case '{': return readList(fp, '}');      case '}': ungetc(c, fp);  return (oop)EOF;
      case '-': {
	int d= getc(fp);
	ungetc(d, fp);
	if (isDigit10(d)) goto doDigits;
	/* fall through... */
      }
      default: {
	if (isLetter(c)) {
	  static struct buffer buf= BUFFER_INITIALISER;
	  buffer_reset(&buf);
	  while (isLetter(c) || isDigit10(c)) {
	    buffer_append(&buf, c);
	    c= getc(fp);
	  }
	  ungetc(c, fp);
	  oop obj= intern(buffer_contents(&buf));
	  //buffer_free(&buf);
	  return obj;
	}
	fatal(isPrint(c) ? "illegal character: 0x%02x '%c'" : "illegal character: 0x%02x", c, c);
      }
    }
  }
}
    
static void doprint(FILE *stream, oop obj, int storing)
{
  if (!obj) {
    fprintf(stream, "()");
    return;
  }
  if (obj == globals) {
    fprintf(stream, "<globals>");
    return;
  }
  switch (getType(obj)) {
    case Undefined:	fprintf(stream, "UNDEFINED");			break;
    case Long:		fprintf(stream, "%ld", get(obj, Long,bits));	break;
    case String: {
      if (!storing)
	fprintf(stream, "%s", get(obj, String,bits));
      else {
	char *p= get(obj, String,bits);
	int c;
	putc('"', stream);
	while ((c= *p++)) {
	  if (c >= ' ' && c < 127)
	    switch (c) {
	      case '"':  printf("\\\"");  break;
	      case '\\': printf("\\\\");  break;
	      default:	 putc(c, stream);  break;
	    }
	  else fprintf(stream, "\\%03o", c);
	}
	putc('"', stream);
      }
      break;
    }
    case Symbol:	fprintf(stream, "%s", get(obj, Symbol,bits));	break;
    case Pair: {
      fprintf(stream, "(");
      for (;;) {
	if (obj == globals) {
	  fprintf(stream, "<globals>");
	  break;
	}
	doprint(stream, getHead(obj), storing);
	obj= getTail(obj);
	if (!is(Pair, obj)) break;
	fprintf(stream, " ");
      }
      if (nil != obj) {
	fprintf(stream, " . ");
	doprint(stream, obj, storing);
      }
      fprintf(stream, ")");
      break;
    }
    case Array: {
      int i, len= arrayLength(obj);
      fprintf(stream, "Array(");
      for (i= 0;  i < len;  ++i) {
	if (i) fprintf(stream, " ");
	doprint(stream, arrayAt(obj, i), storing);
      }
      fprintf(stream, ")");
      break;
    }
    case Expr: {
      fprintf(stream, "Expr(");
      doprint(stream, car(get(obj, Expr,defn)), storing);
      fprintf(stream, ")");
      break;
    }
    case Form: {
      fprintf(stream, "Form(");
      doprint(stream, get(obj, Form,function), storing);
      fprintf(stream, ")");
      break;
    }
    case Fixed: {
      if (isatty(1)) {
	fprintf(stream, "[1m");
	doprint(stream, get(obj, Fixed,function), storing);
	fprintf(stream, "[m");
      }
      else {
	fprintf(stream, "Fixed<");
	doprint(stream, get(obj, Fixed,function), storing);
	fprintf(stream, ">");
      }
      break;
    }
    case Subr: {
      if (get(obj, Subr,name))
	fprintf(stream, "%s", get(obj, Subr,name));
      else
	fprintf(stream, "Subr<%p>", get(obj, Subr,imp));
      break;
    }
    default: {
      fprintf(stream, "<type=%i>", getType(obj));
      break;
    }
  }
}

static void print(oop obj)			{ doprint(stdout, obj, 0); }

static void fdump(FILE *stream, oop obj)	{ doprint(stream, obj, 1); }
static void dump(oop obj)			{ fdump(stdout, obj); }

static void fdumpln(FILE *stream, oop obj)
{
  fdump(stream, obj);
  fprintf(stream, "\n");
}

static void dumpln(oop obj)			{ fdumpln(stdout, obj); }

static oop assq(oop key, oop alist)
{
  while (is(Pair, alist)) {
    oop head= getHead(alist);
    if (is(Pair, head) && getHead(head) == key)
      return head;
    alist= getTail(alist);
  }
  return nil;
}

static oop define(oop name, oop value, oop env)
{
  oop ass;
#if 0
  ass= assq(name, env);
  if (nil != ass)
    setTail(ass, value);
  else
#endif
    {
      ass= newPair(name, value);		GC_PROTECT(ass);
      oop ent= newPair(ass, getTail(env));	GC_UNPROTECT(ass);
      setTail(env, ent);
    }
  return ass;
}

static oop apply(oop fun, oop args, oop env);

static oop concat(oop head, oop tail)
{
  if (!is(Pair, head)) return tail;
  tail= concat(getTail(head), tail);	GC_PROTECT(tail);
  head= newPair(getHead(head), tail);	GC_UNPROTECT(tail);
  return head;
}

static oop exlist(oop obj, oop env);

static oop expand(oop expr, oop env)
{
  if (opt_v > 1) { printf("EXPAND ");  dumpln(expr); }
  if (is(Pair, expr)) {
    oop head= expand(getHead(expr), env);	GC_PROTECT(head);
    if (is(Symbol, head)) {
      oop val= cdr(assq(head, env));
      if (is(Form, val)) {
	head= apply(get(val, Form,function), getTail(expr), env);
	head= expand(head, env);		GC_UNPROTECT(head);
	return head;
      }
    }
    oop tail= getTail(expr);					GC_PROTECT(tail);
    if (s_quote != head) tail= exlist(tail, env);
    if (s_set == head && is(Pair, car(tail)) && is(Symbol, caar(tail))) {
      static struct buffer buf= BUFFER_INITIALISER;
      buffer_reset(&buf);
      buffer_appendAll(&buf, "set-");
      buffer_appendAll(&buf, get(getHead(getHead(tail)), Symbol,bits));
      head= intern(buffer_contents(&buf));
      tail= concat(getTail(getHead(tail)), getTail(tail));
    }
    expr= newPair(head, tail);					GC_UNPROTECT(tail);  GC_UNPROTECT(head);
  }
  else {
    oop fn= arrayAt(getTail(expanders), getType(expr));
    if (nil != fn) {
      oop args= newPair(expr, nil);		GC_PROTECT(args);
      expr= apply(fn, args, env);		GC_UNPROTECT(args);
    }
  }
  return expr;
}

static oop exlist(oop list, oop env)
{
  if (!is(Pair, list)) return list;
  oop head= expand(getHead(list), env);		GC_PROTECT(head);
  oop tail= exlist(getTail(list), env);		GC_PROTECT(tail);
  head= newPair(head, tail);			GC_UNPROTECT(tail);  GC_UNPROTECT(head);
  return head;
}

static oop enlist(oop obj, oop env);

static oop encode(oop expr, oop env)
{
  if (opt_v > 1) { printf("ENCODE ");  dumpln(expr); }
  if (is(Pair, expr)) {
    oop head= encode(getHead(expr), env);	GC_PROTECT(head);
    if (is(Symbol, head)) {
      oop val= cdr(assq(head, env));
      if (is(Fixed, val) || is(Subr, val))
	head= val;
    }
    oop tail= getTail(expr);					GC_PROTECT(tail);
    if (f_let == head) {
      oop args= cadr(expr);					GC_PROTECT(env);
      oop tmp= nil;						GC_PROTECT(tmp);
      while (is(Pair, args)) {
	oop var= getHead(args);
	if (is(Pair, var)) var= getHead(var);
	tmp= newPair(var, nil);
	env= newPair(tmp, env);
	args= getTail(args);
      }
      tail= enlist(tail, env);					GC_UNPROTECT(tmp);  GC_UNPROTECT(env);
    }
    else if (f_lambda == head) {
      oop args= cadr(expr);					GC_PROTECT(env);
      oop tmp= nil;						GC_PROTECT(tmp);
      while (is(Pair, args)) {
	tmp= newPair(getHead(args), nil);
	env= newPair(tmp, env);
	args= getTail(args);
      }
      if (nil != args) {
	tmp= newPair(args, nil);
	env= newPair(tmp, env);
      }
      tail= enlist(tail, env);					GC_UNPROTECT(tmp);  GC_UNPROTECT(env);
    }
    else if (f_quote != head)
      tail= enlist(tail, env);
    expr= newPair(head, tail);					GC_UNPROTECT(tail);  GC_UNPROTECT(head);
  }
  else {
    oop fn= arrayAt(getTail(encoders), getType(expr));
    if (nil != fn) {
      oop args= newPair(env, nil);		GC_PROTECT(args);
      args= newPair(expr, args);
      expr= apply(fn, args, env);		GC_UNPROTECT(args);
    }
  }
  return expr;
}

static oop enlist(oop list, oop env)
{
  if (!is(Pair, list)) return list;
  oop head= encode(getHead(list), env);		GC_PROTECT(head);
  oop tail= enlist(getTail(list), env);		GC_PROTECT(tail);
  head= newPair(head, tail);			GC_UNPROTECT(tail);  GC_UNPROTECT(head);
  return head;
}

static oop evlist(oop obj, oop env);

static oop traceStack= nil;
static int traceDepth= 0;

static void fatal(char *reason, ...)
{
  if (reason) {
    va_list ap;
    va_start(ap, reason);
    fprintf(stderr, "\nerror: ");
    vfprintf(stderr, reason, ap);
    fprintf(stderr, "\n");
    va_end(ap);
  }

  if (nil != cdr(backtrace)) {
    oop args= newLong(traceDepth);		GC_PROTECT(args);
    args= newPair(args, nil);
    args= newPair(traceStack, args);
    apply(cdr(backtrace), args, globals);	GC_UNPROTECT(args);
  }
  else {
    int i= traceDepth;
    while (i--) {
      printf("%3d: ", i);
      dumpln(arrayAt(traceStack, i));
    }
  }
  exit(1);
}

static oop eval(oop obj, oop env)
{
  if (opt_v > 1) { printf("EVAL ");  dumpln(obj); }
  switch (getType(obj)) {
    case Undefined:
    case Long:
    case String: {
      return obj;
    }
    case Symbol: {
      oop val= assq(obj, env);
      if (!is(Pair, val))		fatal("undefined variable: %s", get(obj, Symbol,bits));
      return getTail(val);
    }
    case Pair: {
      arrayAtPut(traceStack, traceDepth++, obj);
      oop head= eval(getHead(obj), env);	GC_PROTECT(head);
      if (is(Fixed, head))
	head= apply(get(head, Fixed,function), getTail(obj), env);
      else  {
	oop args= evlist(getTail(obj), env);		GC_PROTECT(args);
	head= apply(head, args, env);			GC_UNPROTECT(args);
      }						GC_UNPROTECT(head);
      --traceDepth;
      return head;
    }
    default: {
      arrayAtPut(traceStack, traceDepth++, obj);
      oop ev= arrayAt(getTail(evaluators), getType(obj));
      if (nil != ev) {
	oop args= newPair(obj, nil);			GC_PROTECT(args);
	obj= apply(ev, obj, env);			GC_UNPROTECT(args);
      }
      --traceDepth;
      return obj;
    }
  }
  return nil;
}

static oop evlist(oop obj, oop env)
{
  if (!is(Pair, obj)) return obj;
  oop head= eval(getHead(obj), env);		GC_PROTECT(head);
  oop tail= evlist(getTail(obj), env);		GC_PROTECT(tail);
  head= newPair(head, tail);			GC_UNPROTECT(tail);  GC_UNPROTECT(head);
  return head;
}

static oop apply(oop fun, oop arguments, oop env)
{
  if (opt_v > 1) { printf("APPLY ");  dump(fun);  printf(" TO ");  dump(arguments);  printf(" IN ");  dumpln(env); }
  switch (getType(fun)) {
    case Expr: {
      oop args= arguments;
      oop defn= get(fun, Expr,defn);	GC_PROTECT(defn);
      oop formals= car(defn);
      env= get(fun, Expr,env);		GC_PROTECT(env);
      oop tmp= nil;			GC_PROTECT(tmp);
      while (is(Pair, formals)) {
	if (!is(Pair, args)) {
	  fprintf(stderr, "\nerror: too few arguments applying ");
	  fdump(stderr, fun);
	  fprintf(stderr, " to ");
	  fdumpln(stderr, arguments);
	  fatal(0);
	}
	tmp= newPair(getHead(formals), getHead(args));
	env= newPair(tmp, env);
	formals= getTail(formals);
	args= getTail(args);
      }
      if (is(Symbol, formals)) {
	tmp= newPair(formals, args);
	env= newPair(tmp, env);
	args= nil;
      }
      if (nil != args) {
	fprintf(stderr, "\nerror: too many arguments applying ");
	fdump(stderr, fun);
	fprintf(stderr, " to ");
	fdumpln(stderr, arguments);
	fatal(0);
      }
      oop ans= nil;
      oop body= getTail(defn);
      while (is(Pair, body)) {
	ans= eval(getHead(body), env);
	body= getTail(body);
      }
      GC_UNPROTECT(tmp);
      GC_UNPROTECT(env);
      GC_UNPROTECT(defn);
      return ans;
    }
    case Fixed: {
      return apply(get(fun, Fixed,function), arguments, env);
    }
    case Subr: {
      return get(fun, Subr,imp)(arguments, env);
    }
    default: {
      oop args= arguments;
      oop ap= arrayAt(getTail(applicators), getType(fun));
      if (nil != ap) {						GC_PROTECT(args);
	args= newPair(fun, args);
	args= apply(ap, args, env);				GC_UNPROTECT(args);
	return args;
      }
      fprintf(stderr, "\nerror: cannot apply: ");
      fdumpln(stderr, fun);
      fatal(0);
    }
  }
  return nil;
}

static int length(oop list)
{
  if (!is(Pair, list)) return 0;
  return 1 + length(getTail(list));
}

static void arity(oop args, char *name)
{
  fatal("wrong number of arguments (%i) in: %s\n", length(args), name);
}

static void arity1(oop args, char *name)
{
  if (!is(Pair, args) || is(Pair, getTail(args))) arity(args, name);
}

static void arity2(oop args, char *name)
{
  if (!is(Pair, args) || !is(Pair, getTail(args)) || is(Pair, getTail(getTail(args)))) arity(args, name);
}

static void arity3(oop args, char *name)
{
  if (!is(Pair, args) || !is(Pair, getTail(args)) || !is(Pair, getTail(getTail(args))) || is(Pair, getTail(getTail(getTail(args))))) arity(args, name);
}

#define subr(NAME)	oop subr_##NAME(oop args, oop env)

static subr(if)
{
  if (nil != eval(car(args), env))
    return eval(cadr(args), env);
  oop ans= nil;
  args= cddr(args);
  while (is(Pair, args)) {
    ans= eval(getHead(args), env);
    args= cdr(args);
  }
  return ans;
}

static subr(and)
{
  oop ans= s_t;
  for (;  is(Pair, args);  args= getTail(args))
    if (nil == (ans= eval(getHead(args), env)))
      break;
  return ans;
}

static subr(or)
{
  oop ans= nil;
  for (;  is(Pair, args);  args= getTail(args))
    if (nil != (ans= eval(getHead(args), env)))
      break;
  return ans;
}

static subr(set)
{
  oop var= assq(car(args), env);
  if (!is(Pair,var)) {
    fprintf(stderr, "\nerror: cannot set undefined variable: ");
    fdumpln(stderr, car(args));
    fatal(0);
  }
  return setTail(var, eval(cadr(args), env));
}

static subr(let)
{
  oop env2= env;		GC_PROTECT(env2);
  oop tmp=  nil;		GC_PROTECT(tmp);
  oop bindings= car(args);
  oop body= cdr(args);
  while (is(Pair, bindings)) {
    oop binding= getHead(bindings);
    if (is(Pair, binding)) {
      oop symbol= getHead(binding);
      oop prog=   getTail(binding);
      while (is(Pair, prog)) {
	oop value= getHead(prog);
	tmp= eval(value, env);
	prog= getTail(prog);
      }
      tmp= newPair(symbol, tmp);
      env2= newPair(tmp, env2);
    }
    bindings= getTail(bindings);
  }
  oop ans= nil;			GC_UNPROTECT(tmp);
  while (is(Pair, body)) {
    ans= eval(getHead(body), env2);
    body= getTail(body);
  }				GC_UNPROTECT(env2);
  return ans;
}

static subr(while)
{
  oop tst= car(args);
  while (nil != eval(tst, env)) {
    oop body= cdr(args);
    while (is(Pair, body)) {
      eval(getHead(body), env);
      body= getTail(body);
    }
  }
  return nil;
}

static subr(quote)
{
  return car(args);
}

static subr(lambda)
{
  return newExpr(args, env);
}

static subr(define)
{
  oop symbol= car(args);
  if (!is(Symbol, symbol)) {
    fprintf(stderr, "\nerror: non-symbol identifier in define: ");
    fdumpln(stderr, symbol);
    fatal(0);
  }
  oop value= eval(cadr(args), env);		GC_PROTECT(value);
  define(symbol, value, globals);		GC_UNPROTECT(value);
  return value;
}

#define _do_unary()				\
  _do(com, ~)

#define _do(NAME, OP)								\
  static subr(NAME)								\
  {										\
    arity1(args, #OP);								\
    oop rhs= getHead(args);							\
    return newLong(OP getLong(rhs));						\
  }

_do_unary()

#undef _do

#define _do_binary()									\
  _do(add,     +)  _do(mul,     *)  _do(div,     /)  _do(mod,  %)			\
  _do(bitand,  &)  _do(bitor,   |)  _do(bitxor,  ^)  _do(shl, <<)  _do(shr, >>)

#define _do(NAME, OP)								\
  static subr(NAME)								\
  {										\
    arity2(args, #OP);								\
    oop lhs= getHead(args);							\
    oop rhs= getHead(getTail(args));						\
    if (is(Long, lhs) && is(Long, rhs))						\
      return newLong(getLong(lhs) OP getLong(rhs));				\
    fprintf(stderr, "%s: non-numeric argument: ", #OP);				\
    if (!is(Long, lhs))	fdumpln(stderr, lhs);					\
    else		fdumpln(stderr, rhs);					\
    fatal(0);									\
    return nil;									\
    }

_do_binary()

#undef _do

static subr(sub)
{
  if (!is(Pair, args)) arity(args, "-");
  oop lhs= getHead(args);  args= getTail(args);
  if (!is(Pair, args)) return newLong(- getLong(lhs));
  oop rhs= getHead(args);  args= getTail(args);
  if (is(Pair, args)) arity(args, "-");
  return newLong(getLong(lhs) - getLong(rhs));
}

#define _do_relation()									\
  _do(lt,   <)  _do(le,  <=)  _do(ge,  >=)  _do(gt,   >)

#define _do(NAME, OP)								\
  static subr(NAME)								\
  {										\
    arity2(args, #OP);								\
    oop lhs= getHead(args);							\
    oop rhs= getHead(getTail(args));						\
    if (is(Long, lhs) && is(Long, rhs))						\
      return newBool(getLong(lhs) OP getLong(rhs));				\
    fprintf(stderr, "%s: non-numeric argument: ", #OP);				\
    if (!is(Long, lhs))	fdumpln(stderr, lhs);					\
    else		fdumpln(stderr, rhs);					\
    fatal(0);									\
    return nil;									\
  }

_do_relation()

#undef _do

static subr(eq)
{
  arity2(args, "=");
  oop lhs= getHead(args);							\
  oop rhs= getHead(getTail(args));						\
  int ans= 0;
  switch (getType(lhs)) {
    case Long:		ans= (is(Long, rhs)	&& (getLong(lhs) == getLong(rhs)));				break;
    case String:	ans= (is(String, rhs) 	&& !strcmp(get(lhs, String,bits), get(rhs, String,bits)));	break;
    default:		ans= (lhs == rhs);									break;
  }
  return newBool(ans);
}

static subr(ne)
{
  arity2(args, "!=");
  oop lhs= getHead(args);							\
  oop rhs= getHead(getTail(args));						\
  int ans= 0;
  switch (getType(lhs)) {
    case Long:		ans= (is(Long, rhs)	&& (getLong(lhs) == getLong(rhs)));				break;
    case String:	ans= (is(String, rhs) 	&& !strcmp(get(lhs, String,bits), get(rhs, String,bits)));	break;
    default:		ans= (lhs == rhs);									break;
  }
  return newBool(!ans);
}

static subr(exit)
{
  oop n= car(args);
  exit(is(Long, n) ? getLong(n) : 0);
}

static subr(abort)
{
  fatal("aborted");
  return nil;
}

static subr(current_environment)
{
  return env;
}

static subr(read)
{
  FILE *stream= stdin;
  if (nil == args) return read(stdin);
  oop arg= car(args);			if (!is(String, arg)) { fprintf(stderr, "read: non-String argument: ");  fdumpln(stderr, arg);  fatal(0); }
  stream= fopen(get(arg, String,bits), "r");
  if (!stream) return nil;
  oop head= newPair(nil, nil), tail= head;	GC_PROTECT(head);
  oop obj= nil;					GC_PROTECT(obj);
  for (;;) {
    obj= read(stream);
    if (obj == (oop)EOF) break;
    tail= setTail(tail, newPair(obj, nil));
    if (stdin == stream) break;
  }
  head= getTail(head);				GC_UNPROTECT(obj);
  fclose(stream);				GC_UNPROTECT(head);
  return head;
}

static subr(eval)
{
  oop x= car(args);  args= cdr(args);		GC_PROTECT(x);
  oop e= car(args);  if (nil == e) e= env;
  x= expand(x, e);
  x= encode(x, e);
  x= eval  (x, e);				GC_UNPROTECT(x);
  return x;
}

static subr(apply)
{
  oop f= car(args);  args= cdr(args);
  oop a= car(args);  args= cdr(args);
  oop e= car(args);  if (nil == e) e= env;
  return apply(f, a, e);
}

static subr(type_of)
{
  arity1(args, "type-of");
  return newLong(getType(getHead(args)));
}

static subr(warn)
{
  while (is(Pair, args)) {
    doprint(stderr, getHead(args), 0);
    args= getTail(args);
  }
  return nil;
}

static subr(print)
{
  while (is(Pair, args)) {
    print(getHead(args));
    args= getTail(args);
  }
  return nil;
}

static subr(dump)
{
  while (is(Pair, args)) {
    dump(getHead(args));
    args= getTail(args);
  }
  return nil;
}

static subr(form)
{
  arity1(args, "form");
  return newForm(getHead(args));
}

static subr(fixedP)
{
  arity1(args, "fixed?");
  return newBool(is(Fixed, getHead(args)));
}

static subr(cons)
{
  arity2(args, "cons");
  oop lhs= getHead(args);
  oop rhs= getHead(getTail(args));
  return newPair(lhs, rhs);
}

static subr(pairP)
{
  arity1(args, "pair?");
  return newBool(is(Pair, getHead(args)));
}

static subr(car)
{
  arity1(args, "car");
  return car(getHead(args));
}

static subr(set_car)
{
  arity2(args, "set-car");
  oop arg= getHead(args);				if (!is(Pair, arg)) return nil;
  return setHead(arg, getHead(getTail(args)));
}

static subr(cdr)
{
  arity1(args, "cdr");
  return cdr(getHead(args));
}

static subr(set_cdr)
{
  arity2(args, "set-cdr");
  oop arg= getHead(args);				if (!is(Pair, arg)) return nil;
  return setTail(arg, getHead(getTail(args)));
}

static subr(formP)
{
  arity1(args, "form?");
  return newBool(is(Form, getHead(args)));
}

static subr(symbolP)
{
  arity1(args, "symbol?");
  return newBool(is(Symbol, getHead(args)));
}

static subr(stringP)
{
  arity1(args, "string?");
  return newBool(is(String, getHead(args)));
}

static subr(string)
{
  oop arg= car(args);
  int num= is(Long, arg) ? getLong(arg) : 0;
  return _newString(num);
}

static subr(string_length)
{
  arity1(args, "string-length");
  oop arg= getHead(args);		if (!is(String, arg)) { fprintf(stderr, "string-length: non-String argument: ");  fdumpln(stderr, arg);  fatal(0); }
  return newLong(stringLength(arg));
}

static subr(string_at)
{
  arity2(args, "string-at");
  oop arr= getHead(args);		if (!is(String, arr)) { fprintf(stderr, "string-at: non-String argument: ");  fdumpln(stderr, arr);  fatal(0); }
  oop arg= getHead(getTail(args));	if (!is(Long, arg)) return nil;
  int idx= getLong(arg);
  if (0 <= idx && idx < stringLength(arr)) return newLong(get(arr, String,bits)[idx]);
  return nil;
}

static subr(set_string_at)
{
  arity3(args, "set-string-at");
  oop arr= getHead(args);			if (!is(String, arr)) { fprintf(stderr, "set-string-at: non-string argument: ");  fdumpln(stderr, arr);  fatal(0); }
  oop arg= getHead(getTail(args));		if (!is(Long, arg)) { fprintf(stderr, "set-string-at: non-integer index: ");  fdumpln(stderr, arg);  fatal(0); }
  oop val= getHead(getTail(getTail(args)));	if (!is(Long, val)) { fprintf(stderr, "set-string-at: non-integer value: ");  fdumpln(stderr, val);  fatal(0); }
  int idx= getLong(arg);
  if (0 <= idx && idx < stringLength(arr)) {
    get(arr, String,bits)[idx]= getLong(val);
    return val;
  }
  return nil;
}

static subr(string_symbol)
{
  oop arg= car(args);				if (is(Symbol, arg)) return arg;  if (!is(String, arg)) return nil;
  return intern(get(arg, String,bits));
}

static subr(symbol_string)
{
  oop arg= car(args);				if (is(String, arg)) return arg;  if (!is(Symbol, arg)) return nil;
  return newString(get(arg, Symbol,bits));
}

static subr(long_string)
{
  oop arg= car(args);				if (is(String, arg)) return arg;  if (!is(Long, arg)) return nil;
  char buf[32];
  sprintf(buf, "%ld", getLong(arg));
  return newString(buf);
}

static subr(array)
{
  oop arg= car(args);
  int num= is(Long, arg) ? getLong(arg) : 0;
  return newArray(num);
}

static subr(arrayP)
{
  return is(Array, car(args)) ? s_t : nil;
}

static subr(array_length)
{
  arity1(args, "array-length");
  oop arg= getHead(args);		if (!is(Array, arg)) { fprintf(stderr, "array-length: non-Array argument: ");  fdumpln(stderr, arg);  fatal(0); }
  return newLong(arrayLength(arg));
}

static subr(array_at)
{
  arity2(args, "array-at");
  oop arr= getHead(args);
  oop arg= getHead(getTail(args));	if (!is(Long, arg)) return nil;
  return arrayAt(arr, getLong(arg));
}

static subr(set_array_at)
{
  arity3(args, "set-array-at");
  oop arr= getHead(args);
  oop arg= getHead(getTail(args));		if (!is(Long, arg)) return nil;
  oop val= getHead(getTail(getTail(args)));
  return arrayAtPut(arr, getLong(arg), val);
}

static subr(allocate)
{
  arity2(args, "allocate");
  oop type= getHead(args);			if (!is(Long, type)) return nil;
  oop size= getHead(getTail(args));		if (!is(Long, size)) return nil;
  return _newOops(getLong(type), sizeof(oop) * getLong(size));
}

static subr(oop_at)
{
  arity2(args, "oop-at");
  oop obj= getHead(args);
  oop arg= getHead(getTail(args));	if (!is(Long, arg)) return nil;
  return oopAt(obj, getLong(arg));
}

static subr(set_oop_at)
{
  arity3(args, "set-oop-at");
  oop obj= getHead(args);
  oop arg= getHead(getTail(args));		if (!is(Long, arg)) return nil;
  oop val= getHead(getTail(getTail(args)));
  return oopAtPut(obj, getLong(arg), val);
}

static subr(not)
{
  arity1(args, "not");
  oop obj= getHead(args);
  return (nil == obj) ? s_t : nil;
}

#undef subr

static void replFile(FILE *stream)
{
  for (;;) {
    if (stream == stdin) {
      printf(".");
      fflush(stdout);
    }
    oop obj= read(stream);
    if (obj == (oop)EOF) break;
    GC_PROTECT(obj);
    if (opt_v) {
      dumpln(obj);
      fflush(stdout);
    }
    obj= expand(obj, globals);
    obj= encode(obj, globals);
    obj= eval(obj, globals);
    if (stream == stdin) {
      printf(" => ");
      fflush(stdout);
      dumpln(obj);
      fflush(stdout);
    }
    GC_UNPROTECT(obj);
    if (opt_v) {
      GC_gcollect();
      printf("%ld collections, %ld objects, %ld bytes, %4.1f%% fragmentation\n",
	     (long)GC_collections, (long)GC_count_objects(), (long)GC_count_bytes(),
	     GC_count_fragments() * 100.0);
    }
  }
  int c= getc(stream);
  if (EOF != c)				fatal("unexpected character 0x%02x '%c'\n", c, c);
}

static void replPath(char *path)
{
  FILE *stream= fopen(path, "r");
  if (!stream) {
    fprintf(stderr, "\nerror: ");
    perror(path);
    fatal(0);
  }
  fscanf(stream, "#!%*[^\012\015]");
  replFile(stream);
  fclose(stream);
}

static void sigint(int signo)
{
  fatal("\nInterrupt");
}

int main(int argc, char **argv)
{
  GC_add_root(&symbols);
  GC_add_root(&globals);
  GC_add_root(&expanders);
  GC_add_root(&encoders);
  GC_add_root(&evaluators);
  GC_add_root(&applicators);
  GC_add_root(&backtrace);

  s_set			= intern("set");
  s_let			= intern("let");
  s_lambda		= intern("lambda");
  s_quote		= intern("quote");
  s_quasiquote		= intern("quasiquote");
  s_unquote		= intern("unquote");
  s_unquote_splicing	= intern("unquote-splicing");
  s_t			= intern("t");
  s_dot			= intern(".");

  oop tmp= nil;		GC_PROTECT(tmp);

  tmp= newPair(intern("*globals*"), globals);
  globals= newPair(tmp, globals);
  set(tmp, Pair,tail, globals);

  expanders=   define(intern("*expanders*"),   nil, globals);
  encoders=    define(intern("*encoders*"),    nil, globals);
  evaluators=  define(intern("*evaluators*"),  nil, globals);
  applicators= define(intern("*applicators*"), nil, globals);

  traceStack=  newArray(32);	GC_add_root(&traceStack);

  backtrace=   define(intern("*backtrace*"), nil, globals);

#define _do(NAME, OP)	tmp= newSubr(subr_##NAME, #OP);  define(intern(#OP), tmp, globals);
  _do_unary();  _do_binary();  _do(sub, -);  _do_relation();
#undef _do

  {
    struct { char *name;  imp_t imp; } *ptr, subrs[]= {
      { ".if",		   subr_if },
      { ".and",		   subr_and },
      { ".or",		   subr_or },
      { ".set",		   subr_set },
      { ".let",		   subr_let },
      { ".while",	   subr_while },
      { ".quote",	   subr_quote },
      { ".lambda",	   subr_lambda },
      { ".define",	   subr_define },
      { " exit",	   subr_exit },
      { " abort",	   subr_abort },
      { " current-environment",	   subr_current_environment },
      { " read",	   subr_read },
      { " eval",	   subr_eval },
      { " apply",	   subr_apply },
      { " type-of",	   subr_type_of },
      { " warn",	   subr_warn },
      { " print",	   subr_print },
      { " dump",	   subr_dump },
      { " form",	   subr_form },
      { " fixed?",	   subr_fixedP },
      { " cons",	   subr_cons },
      { " pair?",	   subr_pairP },
      { " car",		   subr_car },
      { " set-car",	   subr_set_car },
      { " cdr",		   subr_cdr },
      { " set-cdr",	   subr_set_cdr },
      { " form?",	   subr_formP },
      { " symbol?",	   subr_symbolP },
      { " string?",	   subr_stringP },
      { " string", 	   subr_string },
      { " string-length",  subr_string_length },
      { " string-at",	   subr_string_at },
      { " set-string-at",  subr_set_string_at },
      { " symbol->string", subr_symbol_string },
      { " string->symbol", subr_string_symbol },
      { " long->string",   subr_long_string },
      { " array",	   subr_array },
      { " array?",	   subr_arrayP },
      { " array-length",   subr_array_length },
      { " array-at",	   subr_array_at },
      { " set-array-at",   subr_set_array_at },
      { " allocate",	   subr_allocate },
      { " oop-at",	   subr_oop_at },
      { " set-oop-at",	   subr_set_oop_at },
      { " not",		   subr_not },
      { " ~",		   subr_com },
      { " +",		   subr_add },
      { " -",		   subr_sub },
      { " *",		   subr_mul },
      { " /",		   subr_div },
      { " %",		   subr_mod },
      { " &",		   subr_bitand },
      { " |",		   subr_bitor },
      { " ^",		   subr_bitxor },
      { " <<",		   subr_shl },
      { " >>",		   subr_shr },
      { " <",		   subr_lt },
      { " <=",		   subr_le },
      { " =",		   subr_eq },
      { " !=",		   subr_ne },
      { " >=",		   subr_ge },
      { " >",		   subr_gt },
      { 0,		   0 }
    };
    for (ptr= subrs;  ptr->name;  ++ptr) {
      tmp= newSubr(ptr->imp, ptr->name + 1);
      if ('.' == ptr->name[0]) tmp= newFixed(tmp);
      define(intern(ptr->name + 1), tmp, globals);
    }
  }

  tmp= nil;		GC_UNPROTECT(tmp);

  f_set=    cdr(assq(s_set,    globals));		GC_add_root(&f_set);
  f_quote=  cdr(assq(s_quote,  globals));		GC_add_root(&f_quote);
  f_lambda= cdr(assq(s_lambda, globals));		GC_add_root(&f_lambda);
  f_let=    cdr(assq(s_let,    globals));		GC_add_root(&f_let);

  int repled= 0;

  signal(SIGINT, sigint);

  while (argc-- > 1) {
    ++argv;
    if 	    (!strcmp(*argv, "-v"))	++opt_v;
    else if (!strcmp(*argv, "-b"))	++opt_b;
    else {
      if (!opt_b) {
	replPath("boot.l");
	opt_b= 1;
      }
      replPath(*argv);
      repled= 1;
    }
  }

  if (opt_v) {
    GC_gcollect();
    printf("%ld collections, %ld objects, %ld bytes, %4.1f%% fragmentation\n",
	   (long)GC_collections, (long)GC_count_objects(), (long)GC_count_bytes(),
	   GC_count_fragments() * 100.0);
  }

  if (!repled) {
    if (!opt_b) replPath("boot.l");
    replFile(stdin);
    printf("\nmorituri te salutant\n");
  }

  return 0;
}
