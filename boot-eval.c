#include <stdio.h>
#include <string.h>
#include <signal.h>
#include <stdarg.h>
#include <stdlib.h>
#include <sys/types.h>
#include <assert.h>

extern int isatty(int);

#define GC_APP_HEADER	int type;

struct GC_StackRoot
{
  void **root;
  struct GC_StackRoot *next;
#if !defined(NDEBUG)
  int	      live;
  const char *name;
  const char *file;
        long  line;
#endif
};

#if defined(NDEBUG)
# define GC_PROTECT(V)		struct GC_StackRoot _sr_##V;  _sr_##V.root= (void *)&V;  GC_push_root(&_sr_##V)
# define GC_UNPROTECT(V)								 GC_pop_root(&_sr_##V)
#else
# define GC_PROTECT(V)		struct GC_StackRoot _sr_##V;  _sr_##V.root= (void *)&V;	 GC_push_root(&_sr_##V, #V, __FILE__, __LINE__)
# define GC_UNPROTECT(V)								 GC_pop_root(&_sr_##V,  #V, __FILE__, __LINE__)
#endif


#define GC_INIT()
#define GC_init()

#if !defined(GC_API)
# define GC_API
#endif

GC_API	void   *GC_malloc(size_t nbytes);
GC_API	void   *GC_malloc_atomic(size_t nbytes);
GC_API	void   *GC_realloc(void *ptr, size_t lbs);
GC_API	void   	GC_free(void *ptr);
GC_API	size_t 	GC_size(void *ptr);
GC_API	void   	GC_add_root(void *root);
GC_API	void   	GC_delete_root(void *root);
GC_API	void   	GC_mark(void *ptr);
GC_API	void   	GC_mark_leaf(void *ptr);
GC_API	void   	GC_sweep(void);
GC_API	void   	GC_gcollect(void);
GC_API	size_t 	GC_count_objects(void);
GC_API	size_t 	GC_count_bytes(void);
GC_API	double 	GC_count_fragments(void);

GC_API	int 	GC_atomic(void *ptr);

#ifndef NDEBUG
GC_API	void	   *GC_check(void *ptr);
GC_API	void	   *GC_stamp(void *ptr, const char *file, long line, const char *func);
GC_API	const char *GC_file(void *ptr);
GC_API	long	    GC_line(void *ptr);
GC_API	const char *GC_function(void *ptr);
#else
# define GC_check(PTR)				(PTR)
# define GC_stamp(PTR, FILE, LINE, FUNC)	(PTR)
# define GC_file(PTR)				"?"
# define GC_line(PTR)				0
# define GC_function(PTR)			"?"
#endif

typedef void (*GC_finaliser_t)(void *ptr, void *data);

GC_API	void GC_register_finaliser(void *ptr, GC_finaliser_t finaliser, void *data);

extern struct GC_StackRoot *GC_stack_roots;

#if defined(NDEBUG)

  GC_API inline void GC_push_root(struct GC_StackRoot *sr)
  {
    sr->next= GC_stack_roots;
    GC_stack_roots= sr;
  }

  GC_API inline void GC_pop_root(struct GC_StackRoot *sr)
  {
#  if 0
    GC_stack_roots= sr->next;
#  else /* paranoid version for broken code warns of mismatched pops with a SEGV */
    struct GC_StackRoot *nr= sr->next;
    while (nr != GC_stack_roots) GC_stack_roots= GC_stack_roots->next;
#  endif
  }

#else

  GC_API inline void GC_push_root(struct GC_StackRoot *sr, const char *name, const char *file, int line)
  {
    sr->next= GC_stack_roots;
    sr->name= name;
    sr->file= file;
    sr->line= line;
    sr->live= 1;
    GC_stack_roots= sr;
  }

  static int GC_roots_include(struct GC_StackRoot *roots, struct GC_StackRoot *root)
  {
    while (roots) {
      if (roots == root) return 1;
      roots= roots->next;
    }
    return 0;
  }

  GC_API inline void GC_pop_root(struct GC_StackRoot *sr, const char *name, const char *file, int line)
  {
    struct GC_StackRoot *nr= sr->next;
    struct GC_StackRoot *gr= GC_stack_roots;
    if (!sr->live)			{ fprintf(stderr, "*** %s %d %s: STALE POP IN GC_pop_root\n", file, line, name);  goto die; }
    sr->live= 0;
    if (GC_roots_include(nr, sr))	{ fprintf(stderr, "*** %s %d %s: CYCLE IN GC_pop_root\n", file, line, name);  goto die; }
    int n= 0;
    while (nr != gr) {
      if (n++ > 10) { fprintf(stderr, "*** %s %d %s: LOOP IN GC_pop_root\n", file, line, name);  goto die; }
      gr= gr->next;
    }
    GC_stack_roots= gr;
    return;
  die:
    fprintf(stderr, "* gc stack roots = %p %s %ld %s\n", gr, gr->file, gr->line, gr->name);
    fprintf(stderr, "* popped root    = %p %s %ld %s\n", sr, sr->file, sr->line, sr->name);
    while (nr) {
      fprintf(stderr, "* next root      = %p %s %ld %s\n", nr, nr ? nr->file : 0, nr ? nr->line : 0, nr ? nr->name : 0);
      nr= nr->next;
    }
    abort();
  }

#endif

typedef void (*GC_pre_mark_function_t)(void);
extern GC_pre_mark_function_t GC_pre_mark_function;

typedef void (*GC_mark_function_t)(void *ptr);
extern GC_mark_function_t GC_mark_function;

typedef void (*GC_free_function_t)(void *ptr);
extern GC_free_function_t GC_free_function;

#define GC_ALIGN	sizeof(long)
#define GC_MEMORY	0x7fffffff
#define GC_QUANTUM	50*1024
#if defined(DEBUGGC)
# define ALLOCS_PER_GC	1
#else
# define ALLOCS_PER_GC	32768
#endif

#define VERBOSE		0

#define BITS_PER_WORD	(sizeof(long) * 8)

typedef struct _gcheader
{
  unsigned long		size  : BITS_PER_WORD - 8	__attribute__((__packed__));
  union {
    unsigned int	flags : 3;
    struct {
      unsigned int	used  : 1;
      unsigned int	atom  : 1;
      unsigned int	mark  : 1;
    }							__attribute__((__packed__));
  }							__attribute__((__packed__));
  struct _gcheader *next;
  struct _gcfinaliser	*finalisers;
#ifndef NDEBUG
  const char	*file;
  long		 line;
  const char	*func;
#endif
#if defined(GC_APP_HEADER)
  GC_APP_HEADER
#endif
} gcheader;

static inline void *hdr2ptr(gcheader *hdr)	{ return (void *)(hdr + 1); }
static inline gcheader *ptr2hdr(void *ptr)	{ return (gcheader *)ptr - 1; }

#ifndef NDEBUG

GC_API void *GC_stamp(void *ptr, const char *file, long line, const char *func)
{
  gcheader *hdr= ptr2hdr(ptr);
  hdr->file= file;
  hdr->line= line;
  hdr->func= func;
  return ptr;
}

GC_API const char *GC_file(void *ptr)		{ return ptr2hdr(ptr)->file; }
GC_API long	   GC_line(void *ptr)		{ return ptr2hdr(ptr)->line; }
GC_API const char *GC_function(void *ptr)	{ return ptr2hdr(ptr)->func; }

#endif

typedef struct _gcfinaliser
{
  void			*ptr;
  GC_finaliser_t	 finaliser;
  void			*data;
  struct _gcfinaliser	*next;
} gcfinaliser;

static gcheader  gcbase= { 0, { -1 }, &gcbase };
static gcheader *gcnext= &gcbase;

static size_t	gcQuantum= GC_QUANTUM;
static int	gcCount=   ALLOCS_PER_GC;
static int	gcAllocs=  ALLOCS_PER_GC;
static size_t	gcMemory=  GC_MEMORY;

static gcfinaliser *finalisable= 0;

GC_API void *GC_malloc(size_t lbs)
{
  gcheader *hdr, *org;
  size_t split;
  if ((!--gcAllocs) || (gcMemory < lbs)) {
    //fprintf(stderr, "%i %lu %ld\t", gcAllocs, gcMemory, lbs);
#  if VERBOSE >= 1
    if (gcAllocs > 0) fprintf(stderr, "GC: heap full after %i allocations\n", gcCount - gcAllocs);
#  endif
    gcAllocs= gcCount;
    GC_gcollect();
    //fprintf(stderr, "GC %i %lu %ld\n", gcAllocs, gcMemory, lbs);
    if (gcMemory < lbs) goto full;
  }
  org= hdr= gcnext;
  lbs= (lbs + GC_ALIGN-1) & ~(GC_ALIGN-1);
#if VERBOSE > 1
  fprintf(stderr, "malloc %i\n", (int)lbs);
#endif
 again:
#if VERBOSE > 4
  {
    gcheader *h= gcnext;
    do { 
      fprintf(stderr, "  %2d %p -> %p = %i\n", h->flags, h, h->next, (int)h->size);
      h= h->next;
    } while (h != gcnext);
  }
#endif
  split= lbs + sizeof(gcheader) + GC_ALIGN;
  do {
#  if VERBOSE > 3
    fprintf(stderr, "? %2d %p -> %p = %i\n", hdr->flags, hdr, hdr->next, (int)hdr->size);
#  endif
    if (!hdr->used) {
      while ((!hdr->next->used) && (hdr2ptr(hdr) + hdr->size == hdr->next)) {
	hdr->size += sizeof(gcheader) + hdr->next->size;
	hdr->next= hdr->next->next;
      }
      if ((hdr->size >= split) || (hdr->size == lbs))
	{
	  void *mem;
	  if (hdr->size >= split)
	    {
	      gcheader *ins= (gcheader *)(hdr2ptr(hdr) + lbs);
	      ins->flags= 0;
	      ins->next= hdr->next;
	      ins->size= hdr->size - lbs - sizeof(gcheader);
	      hdr->next= ins;
	      hdr->size= lbs;
	    }
	  hdr->used= 1;
	  hdr->finalisers= 0;
	  gcnext= hdr->next;
	  mem= hdr2ptr(hdr);
#      if VERBOSE > 2
	  //if ((long)hdr == 0x800248) abort();
	  fprintf(stderr, "MALLOC %p -> %p + %i\n", mem, hdr, (int)GC_size(mem));
#      endif
	  memset(mem, 0, hdr->size);
	  gcMemory -= hdr->size;
	  //if (mem == (void *)0x617190) { fprintf(stderr, "ALLOCATING %p\n", mem);  bkpt(); }
	  return mem;
	}
    }
    hdr= hdr->next;
  } while (hdr != org);
  {
    size_t incr= gcQuantum;
    size_t req= sizeof(gcheader) + lbs;
    while (incr <= req) incr *= 2;
    //fprintf(stderr, "extending by %ld => %ld @ %d\n", req, incr, (int)(gcCount - gcAllocs));
    hdr= (gcheader *)malloc(incr);
    //fprintf(stderr, "buffer at %x\n", (int)hdr);
    if (hdr != (gcheader *)-1)
      {
	hdr->flags= 0;
	hdr->next= gcbase.next;
	gcbase.next= hdr;
	hdr->size= incr - sizeof(gcheader);
#if VERBOSE
	fprintf(stderr, "extend by %i at %p\n", (int)hdr->size, hdr);
#endif
	goto again;
      }
    fprintf(stderr, "GC: sbrk failed\n");
  }
 full:
  fprintf(stderr, "GC: out of memory\n");
  abort();
  return 0;
}

GC_API void *GC_malloc_atomic(size_t lbs)
{
  void *mem= GC_malloc(lbs);
  ptr2hdr(mem)->atom= 1;
  return mem;
}

GC_API void *GC_realloc(void *ptr, size_t lbs)
{
  gcheader *hdr= ptr2hdr(ptr);
  void *mem;
  if (lbs <= hdr->size) return ptr;
  mem= GC_malloc(lbs);
  memcpy(mem, ptr, hdr->size);
  ptr2hdr(mem)->atom= hdr->atom;
  GC_free(ptr);
  return mem;
}

static gcheader *GC_freeHeader(gcheader *hdr)
{
#if VERBOSE > 2
  fprintf(stderr, "FREE %p -> %p %s:%ld %s\n", hdr2ptr(hdr), hdr, hdr->file, hdr->line, hdr->func);
  if (hdr->line == 0) {
    fflush(stdout);
    abort();
  }
#endif
  hdr->flags= 0;
  gcMemory += hdr->size;
  return hdr;
}

GC_API void GC_free(void *ptr)
{
  gcnext= GC_freeHeader(ptr2hdr(ptr));
}

GC_API size_t GC_size(void *ptr)
{
  return ptr2hdr(ptr)->size;
}

GC_API void GC_default_pre_mark_function(void) {}

GC_pre_mark_function_t GC_pre_mark_function= GC_default_pre_mark_function;

GC_API void GC_default_mark_function(void *ptr)
{
  gcheader *hdr= ptr2hdr(ptr);
  void	  **pos= ptr;
  void	  **lim= hdr2ptr(hdr) + hdr->size - sizeof(void *);
  while (pos <= lim)
    {
      void *field= *pos;
      if (field && !((long)field & 1))
	GC_mark(field);
      ++pos;
    }
}

GC_mark_function_t GC_mark_function= GC_default_mark_function;

GC_API void GC_mark(void *ptr)
{
  if ((long)ptr & 1) return;
  gcheader *hdr= ptr2hdr(ptr);
#if VERBOSE > 3
  fprintf(stderr, "mark? %p -> %p used %d atom %d mark %d\n", ptr, hdr, hdr->used, hdr->atom, hdr->mark);
#endif
  if (!hdr->mark) {
    hdr->mark= 1;
    if (!hdr->atom)
      GC_mark_function(ptr);
  }
}

GC_API void GC_mark_leaf(void *ptr)
{
  ptr2hdr(ptr)->mark= 1;
}

GC_free_function_t GC_free_function= 0;

GC_API void GC_sweep(void)
{
  gcheader *hdr= gcbase.next;
  do {
#if VERBOSE > 3
    fprintf(stderr, "sweep? %p %d\n", hdr, hdr->flags);
#endif
    if (hdr->flags)
      {
	if (hdr->mark)
	  hdr->mark= 0;
	else {
	  if (hdr->finalisers) {
	    while (hdr->finalisers) {
	      gcfinaliser *gcf= hdr->finalisers;
	      hdr->finalisers= gcf->next;
	      gcf->next= finalisable;
	      finalisable= gcf;
	    }
	  }
	  else {
	    if (GC_free_function) GC_free_function(hdr2ptr(hdr));
	    hdr= GC_freeHeader(hdr);
	  }
	}
      }
    hdr= hdr->next;
  } while (hdr != &gcbase);
  gcnext= gcbase.next;
  while (finalisable)
    {
      gcfinaliser *gcf= finalisable;
      gcf->finaliser(gcf->ptr, gcf->data);
      finalisable= gcf->next;
      free(gcf);
    }
}

static void ***roots= 0;
static size_t numRoots= 0;
static size_t maxRoots= 0;

struct GC_StackRoot *GC_stack_roots= 0;

GC_API void GC_add_root(void *root)
{
  if (numRoots == maxRoots)
    roots= maxRoots
      ? realloc(roots, sizeof(roots[0]) * (maxRoots *= 2))
      : malloc (       sizeof(roots[0]) * (maxRoots= 128));
  roots[numRoots++]= (void **)root;
  assert(root);
}

GC_API void GC_delete_root(void *root)
{
  int i;
  for (i= 0;  i < numRoots;  ++i)
    if (roots[i] == (void **)root)
      break;
  if (i < numRoots)
    {
      memmove(roots + i, roots + i + 1, sizeof(roots[0]) * (numRoots - i));
      --numRoots;
    }
}

GC_API long GC_collections= 0;

GC_API void GC_gcollect(void)
{
  int i;
  struct GC_StackRoot *sr;
  ++GC_collections;
#if !defined(NDEBUG)
  {
#  undef static
    static char *cursors= "-/|\\";
    static int cursor= 0;
    if (GC_collections % 100 == 0) {
      if (0 == cursors[cursor]) cursor= 0;
      fprintf(stderr, "%c\010", cursors[cursor]);
      ++cursor;
    }
#  if (NONSTATIC)
#    define static
#  endif
  }
#endif
  GC_pre_mark_function();
#if VERBOSE >= 1
  fprintf(stderr, "*** GC: mark roots\n");
#endif
  for (i= 0;  i < numRoots;  ++i)
    if (*roots[i]) {
#    if VERBOSE >= 2
      fprintf(stderr, "*** GC: root %i *%p -> %p\n", i, roots[i], *roots[i]);
#    endif
      GC_mark(*roots[i]);
    }
#if VERBOSE > 0
  fprintf(stderr, "*** GC: mark stack\n");
#endif
  for (sr= GC_stack_roots;  sr;  sr= sr->next)	{
#if VERBOSE > 2 && defined(DEBUGGC)
    fprintf(stderr, "*** GC: stack root %p %s %s:%ld\n", *sr->root, sr->name, sr->file, sr->line);
#endif
    if (*(sr->root)) GC_mark(*(sr->root));
  }
#if VERBOSE > 0
  fprintf(stderr, "*** GC: sweep\n");
#endif
  GC_sweep();
#if VERBOSE > 0
  fprintf(stderr, "*** GC: done\n");
#endif
}

GC_API size_t GC_count_objects(void)
{
  gcheader *hdr= gcbase.next;
  size_t count= 0;
  do {
    if (hdr->used)
      ++count;
    hdr= hdr->next;
  } while (hdr != &gcbase);
  return count;
}

GC_API size_t GC_count_bytes(void)
{
  gcheader *hdr= gcbase.next;
  size_t count= 0;
  do {
    if (hdr->used)
      count += hdr->size;
    hdr= hdr->next;
  } while (hdr != &gcbase);
  return count;
}

GC_API double GC_count_fragments(void)
{
  gcheader *hdr= gcbase.next;
  size_t used= 0;
  size_t free= 0;
  do {
    if (hdr->used) {
      ++used;
      //printf("%p\t%7d\n",   hdr, (int)hdr->size);
    }
    else {
      while ((!hdr->next->used) && (hdr2ptr(hdr) + hdr->size == hdr->next)) {
	hdr->size += sizeof(gcheader) + hdr->next->size;
	hdr->next= hdr->next->next;
      }
      ++free;
      //printf("%p\t\t%7d\n", hdr, (int)hdr->size); 
    }
    hdr= hdr->next;
  } while (hdr != &gcbase);
  return (double)free / (double)used;
}

GC_API int GC_atomic(void *ptr)
{
  return ptr2hdr(ptr)->atom;
}

#ifndef NDEBUG

GC_API void *GC_check(void *ptr)
{
  gcheader *hdr= ptr2hdr(ptr);
  if (!hdr->used) {
    hdr->used= 1;
    printf("accessible dead object %p %s:%ld %s\n", ptr, hdr->file, hdr->line, hdr->func);
  }
  return ptr;
}

#endif

GC_API void GC_register_finaliser(void *ptr, GC_finaliser_t finaliser, void *data)
{
  gcheader    *gch = ptr2hdr(ptr);
  gcfinaliser *gcf = (struct _gcfinaliser *)malloc(sizeof(struct _gcfinaliser));
  gcf->ptr         = ptr;
  gcf->finaliser   = finaliser;
  gcf->data        = data;
  gcf->next        = gch->finalisers;
  gch->finalisers  = gcf;
}

struct buffer
{
  char	*buffer;
  int	 size;
  int	 position;
};

#define BUFFER_INITIALISER { 0, 0, 0 }

static void buffer_reset(struct buffer *b)		{ b->position= 0; }

static void buffer_append(struct buffer *b, int c)
{
  if (b->position == b->size)
    b->buffer= b->buffer
      ? realloc(b->buffer, b->size *= 2)
      : malloc(b->size= 32);
  b->buffer[b->position++]= c;
}

static void buffer_appendAll(struct buffer *b, const char *s)
{
  while (*s) buffer_append(b, *s++);
}

static char *buffer_contents(struct buffer *b)
{
  buffer_append(b, 0);
  b->position--;
  return b->buffer;
}

union Object;

typedef union Object *oop;

typedef oop (*imp_t)(oop args, oop env);

#define nil ((oop)0)

enum { Undefined, Long, String, Symbol, Pair, _Array, Array, Expr, Form, Fixed, Subr };

struct Long	{ long  bits; };
struct String	{ oop   size;  char *bits; };
struct Symbol	{ char *bits; };
struct Pair	{ oop 	head, tail; };
struct Array	{ oop  _array; };
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

static int opt_v= 0;

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

static oop newArray(int tally)
{
  oop elts= _newOops(_Array, sizeof(oop) * tally);	GC_PROTECT(elts);
  oop obj=   newOops( Array);				GC_UNPROTECT(elts);
  set(obj, Array,_array, elts);
  return obj;
}

static int arrayLength(oop obj)
{
  if (is(Array, obj))
    return GC_size(get(obj, Array,_array)) / sizeof(oop);
  return 0;
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

static oop arrayAt(oop array, int index)
{
  if (is(Array, array)) {
    oop elts= get(array, Array,_array);
    int size= GC_size(elts) / sizeof(oop);
    if ((unsigned)index < (unsigned)size)
      return ((oop *)elts)[index];
  }
  return nil;
}

static oop arrayAtPut(oop array, int index, oop val)
{
  if (is(Array, array)) {
    oop elts= get(array, Array,_array);
    int size= GC_size(elts) / sizeof(oop);
    if ((unsigned)index >= (unsigned)size) {
      oop oops= _newOops(_Array, sizeof(oop) * (index + 1));
      memcpy((oop *)oops, (oop *)elts, size * sizeof(oop));
      elts= set(array, Array,_array, oops);
    }
    return ((oop *)elts)[index]= val;
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

#define CHAR_PRINT	(1<<0)
#define CHAR_BLANK	(1<<1)
#define CHAR_ALPHA	(1<<2)
#define CHAR_DIGIT10	(1<<3)
#define CHAR_DIGIT16	(1<<4)
#define CHAR_LETTER	(1<<5)

static char chartab[]= {
  /*  00 nul */	0,
  /*  01 soh */	0,
  /*  02 stx */	0,
  /*  03 etx */	0,
  /*  04 eot */	0,
  /*  05 enq */	0,
  /*  06 ack */	0,
  /*  07 bel */	0,
  /*  08 bs  */	0,
  /*  09 ht  */	0,
  /*  0a nl  */	CHAR_PRINT | CHAR_BLANK,
  /*  0b vt  */	0,
  /*  0c np  */	CHAR_PRINT | CHAR_BLANK,
  /*  0d cr  */	CHAR_PRINT | CHAR_BLANK,
  /*  0e so  */	0,
  /*  0f si  */	0,
  /*  10 dle */	0,
  /*  11 dc1 */	0,
  /*  12 dc2 */	0,
  /*  13 dc3 */	0,
  /*  14 dc4 */	0,
  /*  15 nak */	0,
  /*  16 syn */	0,
  /*  17 etb */	0,
  /*  18 can */	0,
  /*  19 em  */	0,
  /*  1a sub */	0,
  /*  1b esc */	0,
  /*  1c fs  */	0,
  /*  1d gs  */	0,
  /*  1e rs  */	0,
  /*  1f us  */	0,
  /*  20 sp  */	CHAR_PRINT | CHAR_BLANK,
  /*  21  !  */	CHAR_PRINT | CHAR_LETTER,
  /*  22  "  */	CHAR_PRINT | CHAR_PRINT,
  /*  23  #  */	CHAR_PRINT | CHAR_LETTER,
  /*  24  $  */	CHAR_PRINT | CHAR_LETTER,
  /*  25  %  */	CHAR_PRINT | CHAR_LETTER,
  /*  26  &  */	CHAR_PRINT | CHAR_LETTER,
  /*  27  '  */	CHAR_PRINT,
  /*  28  (  */	CHAR_PRINT,
  /*  29  )  */	CHAR_PRINT,
  /*  2a  *  */	CHAR_PRINT | CHAR_LETTER,
  /*  2b  +  */	CHAR_PRINT | CHAR_LETTER,
  /*  2c  ,  */	CHAR_PRINT | CHAR_LETTER,
  /*  2d  -  */	CHAR_PRINT | CHAR_LETTER,
  /*  2e  .  */	CHAR_PRINT | CHAR_LETTER,
  /*  2f  /  */	CHAR_PRINT | CHAR_LETTER,
  /*  30  0  */	CHAR_PRINT | CHAR_DIGIT10 | CHAR_DIGIT16,
  /*  31  1  */	CHAR_PRINT | CHAR_DIGIT10 | CHAR_DIGIT16,
  /*  32  2  */	CHAR_PRINT | CHAR_DIGIT10 | CHAR_DIGIT16,
  /*  33  3  */	CHAR_PRINT | CHAR_DIGIT10 | CHAR_DIGIT16,
  /*  34  4  */	CHAR_PRINT | CHAR_DIGIT10 | CHAR_DIGIT16,
  /*  35  5  */	CHAR_PRINT | CHAR_DIGIT10 | CHAR_DIGIT16,
  /*  36  6  */	CHAR_PRINT | CHAR_DIGIT10 | CHAR_DIGIT16,
  /*  37  7  */	CHAR_PRINT | CHAR_DIGIT10 | CHAR_DIGIT16,
  /*  38  8  */	CHAR_PRINT | CHAR_DIGIT10 | CHAR_DIGIT16,
  /*  39  9  */	CHAR_PRINT | CHAR_DIGIT10 | CHAR_DIGIT16,
  /*  3a  :  */	CHAR_PRINT | CHAR_LETTER,
  /*  3b  ;  */	CHAR_PRINT,
  /*  3c  <  */	CHAR_PRINT | CHAR_LETTER,
  /*  3d  =  */	CHAR_PRINT | CHAR_LETTER,
  /*  3e  >  */	CHAR_PRINT | CHAR_LETTER,
  /*  3f  ?  */	CHAR_PRINT | CHAR_LETTER,
  /*  40  @  */	CHAR_PRINT | CHAR_LETTER,
  /*  41  A  */	CHAR_PRINT | CHAR_LETTER | CHAR_ALPHA | CHAR_DIGIT16,
  /*  42  B  */	CHAR_PRINT | CHAR_LETTER | CHAR_ALPHA | CHAR_DIGIT16,
  /*  43  C  */	CHAR_PRINT | CHAR_LETTER | CHAR_ALPHA | CHAR_DIGIT16,
  /*  44  D  */	CHAR_PRINT | CHAR_LETTER | CHAR_ALPHA | CHAR_DIGIT16,
  /*  45  E  */	CHAR_PRINT | CHAR_LETTER | CHAR_ALPHA | CHAR_DIGIT16,
  /*  46  F  */	CHAR_PRINT | CHAR_LETTER | CHAR_ALPHA | CHAR_DIGIT16,
  /*  47  G  */	CHAR_PRINT | CHAR_LETTER | CHAR_ALPHA,
  /*  48  H  */	CHAR_PRINT | CHAR_LETTER | CHAR_ALPHA,
  /*  49  I  */	CHAR_PRINT | CHAR_LETTER | CHAR_ALPHA,
  /*  4a  J  */	CHAR_PRINT | CHAR_LETTER | CHAR_ALPHA,
  /*  4b  K  */	CHAR_PRINT | CHAR_LETTER | CHAR_ALPHA,
  /*  4c  L  */	CHAR_PRINT | CHAR_LETTER | CHAR_ALPHA,
  /*  4d  M  */	CHAR_PRINT | CHAR_LETTER | CHAR_ALPHA,
  /*  4e  N  */	CHAR_PRINT | CHAR_LETTER | CHAR_ALPHA,
  /*  4f  O  */	CHAR_PRINT | CHAR_LETTER | CHAR_ALPHA,
  /*  50  P  */	CHAR_PRINT | CHAR_LETTER | CHAR_ALPHA,
  /*  51  Q  */	CHAR_PRINT | CHAR_LETTER | CHAR_ALPHA,
  /*  52  R  */	CHAR_PRINT | CHAR_LETTER | CHAR_ALPHA,
  /*  53  S  */	CHAR_PRINT | CHAR_LETTER | CHAR_ALPHA,
  /*  54  T  */	CHAR_PRINT | CHAR_LETTER | CHAR_ALPHA,
  /*  55  U  */	CHAR_PRINT | CHAR_LETTER | CHAR_ALPHA,
  /*  56  V  */	CHAR_PRINT | CHAR_LETTER | CHAR_ALPHA,
  /*  57  W  */	CHAR_PRINT | CHAR_LETTER | CHAR_ALPHA,
  /*  58  X  */	CHAR_PRINT | CHAR_LETTER | CHAR_ALPHA,
  /*  59  Y  */	CHAR_PRINT | CHAR_LETTER | CHAR_ALPHA,
  /*  5a  Z  */	CHAR_PRINT | CHAR_LETTER | CHAR_ALPHA,
  /*  5b  [  */	CHAR_PRINT,
  /*  5c  \  */	CHAR_PRINT | CHAR_LETTER,
  /*  5d  ]  */	CHAR_PRINT,
  /*  5e  ^  */	CHAR_PRINT | CHAR_LETTER,
  /*  5f  _  */	CHAR_PRINT | CHAR_LETTER,
  /*  60  `  */	CHAR_PRINT,
  /*  61  a  */	CHAR_PRINT | CHAR_LETTER | CHAR_ALPHA | CHAR_DIGIT16,
  /*  62  b  */	CHAR_PRINT | CHAR_LETTER | CHAR_ALPHA | CHAR_DIGIT16,
  /*  63  c  */	CHAR_PRINT | CHAR_LETTER | CHAR_ALPHA | CHAR_DIGIT16,
  /*  64  d  */	CHAR_PRINT | CHAR_LETTER | CHAR_ALPHA | CHAR_DIGIT16,
  /*  65  e  */	CHAR_PRINT | CHAR_LETTER | CHAR_ALPHA | CHAR_DIGIT16,
  /*  66  f  */	CHAR_PRINT | CHAR_LETTER | CHAR_ALPHA | CHAR_DIGIT16,
  /*  67  g  */	CHAR_PRINT | CHAR_LETTER | CHAR_ALPHA,
  /*  68  h  */	CHAR_PRINT | CHAR_LETTER | CHAR_ALPHA,
  /*  69  i  */	CHAR_PRINT | CHAR_LETTER | CHAR_ALPHA,
  /*  6a  j  */	CHAR_PRINT | CHAR_LETTER | CHAR_ALPHA,
  /*  6b  k  */	CHAR_PRINT | CHAR_LETTER | CHAR_ALPHA,
  /*  6c  l  */	CHAR_PRINT | CHAR_LETTER | CHAR_ALPHA,
  /*  6d  m  */	CHAR_PRINT | CHAR_LETTER | CHAR_ALPHA,
  /*  6e  n  */	CHAR_PRINT | CHAR_LETTER | CHAR_ALPHA,
  /*  6f  o  */	CHAR_PRINT | CHAR_LETTER | CHAR_ALPHA,
  /*  70  p  */	CHAR_PRINT | CHAR_LETTER | CHAR_ALPHA,
  /*  71  q  */	CHAR_PRINT | CHAR_LETTER | CHAR_ALPHA,
  /*  72  r  */	CHAR_PRINT | CHAR_LETTER | CHAR_ALPHA,
  /*  73  s  */	CHAR_PRINT | CHAR_LETTER | CHAR_ALPHA,
  /*  74  t  */	CHAR_PRINT | CHAR_LETTER | CHAR_ALPHA,
  /*  75  u  */	CHAR_PRINT | CHAR_LETTER | CHAR_ALPHA,
  /*  76  v  */	CHAR_PRINT | CHAR_LETTER | CHAR_ALPHA,
  /*  77  w  */	CHAR_PRINT | CHAR_LETTER | CHAR_ALPHA,
  /*  78  x  */	CHAR_PRINT | CHAR_LETTER | CHAR_ALPHA,
  /*  79  y  */	CHAR_PRINT | CHAR_LETTER | CHAR_ALPHA,
  /*  7a  z  */	CHAR_PRINT | CHAR_LETTER | CHAR_ALPHA,
  /*  7b  {  */	CHAR_PRINT,
  /*  7c  | */	CHAR_PRINT | CHAR_LETTER,
  /*  7d  }  */	CHAR_PRINT,
  /*  7e  ~  */	CHAR_PRINT | CHAR_LETTER,
  /*  7f del */	0,
};

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
  ass= newPair(name, value);		GC_PROTECT(ass);
  oop ent= newPair(ass, getTail(env));	GC_UNPROTECT(ass);
  setTail(env, ent);
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
  arrayAtPut(traceStack, traceDepth++, obj);
  oop ev= arrayAt(getTail(evaluators), getType(obj));
  if (nil != ev) {
    oop args= newPair(obj, nil);		GC_PROTECT(args);
    obj= apply(ev, args, env);			GC_UNPROTECT(args);
  }
  --traceDepth;
  return obj;
}

static oop apply(oop fun, oop arguments, oop env)
{
  if (opt_v > 1) { printf("APPLY ");  dump(fun);  printf(" TO ");  dump(arguments);  printf(" IN ");  dumpln(env); }
  if (Subr == getType(fun)) return get(fun, Subr,imp)(arguments, env);
  oop ap= arrayAt(getTail(applicators), getType(fun));
  if (nil != ap) {
    oop args= newPair(fun, arguments);		GC_PROTECT(args);
    args= apply(ap, args, env);			GC_UNPROTECT(args);
    return args;
  }
  fprintf(stderr, "\nerror: cannot apply: ");
  fdumpln(stderr, fun);
  fatal(0);
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

static subr(eval_symbol)
{
  oop obj= car(args);
  oop val= assq(obj, env);
  if (!is(Pair, val))		fatal("undefined variable: %s", is(Symbol, obj) ? get(obj, Symbol,bits) : "<non-symbol>");
  return getTail(val);
}

static oop evlist(oop obj, oop env)
{
  if (!is(Pair, obj)) return obj;
  oop head= eval(getHead(obj), env);		GC_PROTECT(head);
  oop tail= evlist(getTail(obj), env);		GC_PROTECT(tail);
  head= newPair(head, tail);			GC_UNPROTECT(tail);  GC_UNPROTECT(head);
  return head;
}

static subr(eval_pair)
{
  oop obj= car(args);
  arrayAtPut(traceStack, traceDepth++, obj);
  oop head= eval(getHead(obj), env);			GC_PROTECT(head);
  if (is(Fixed, head))
    head= apply(get(head, Fixed,function), getTail(obj), env);
  else  {
    oop argl= evlist(getTail(obj), env);		GC_PROTECT(argl);
    head= apply(head, argl, env);			GC_UNPROTECT(argl);
  }							GC_UNPROTECT(head);
  --traceDepth;
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

static subr(apply_expr)
{
  oop fun= car(args);
  oop arguments= cdr(args);
  oop argl= arguments;
  oop defn= get(fun, Expr,defn);	GC_PROTECT(defn);
  oop formals= car(defn);
  env= get(fun, Expr,env);		GC_PROTECT(env);
  oop tmp= nil;				GC_PROTECT(tmp);
  while (is(Pair, formals)) {
    if (!is(Pair, argl)) {
      fprintf(stderr, "\nerror: too few arguments applying ");
      fdump(stderr, fun);
      fprintf(stderr, " to ");
      fdumpln(stderr, arguments);
      fatal(0);
    }
    tmp= newPair(getHead(formals), getHead(argl));
    env= newPair(tmp, env);
    formals= getTail(formals);
    argl= getTail(argl);
  }
  if (is(Symbol, formals)) {
    tmp= newPair(formals, argl);
    env= newPair(tmp, env);
    argl= nil;
  }
  if (nil != argl) {
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

static subr(apply_fixed)
{
  oop fun= car(args);
  oop arguments= cadr(args);
  return apply(get(fun, Fixed,function), arguments, env);
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

  tmp= newArray(32);  expanders=   define(intern("*expanders*"),   tmp, globals);
  tmp= newArray(32);  encoders=    define(intern("*encoders*"),    tmp, globals);
  tmp= newArray(32);  evaluators=  define(intern("*evaluators*"),  tmp, globals);
  tmp= newArray(32);  applicators= define(intern("*applicators*"), tmp, globals);

  arrayAtPut(getTail(evaluators),  Symbol, newSubr(subr_eval_symbol, "eval-symbol"));
  arrayAtPut(getTail(evaluators),  Pair,   newSubr(subr_eval_pair,   "eval-pair"  ));

  arrayAtPut(getTail(applicators), Fixed,  newSubr(subr_apply_fixed, "apply-fixed"));
  arrayAtPut(getTail(applicators), Expr,   newSubr(subr_apply_expr,  "apply-expr" ));

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
    else {
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
    replFile(stdin);
    printf("\nmorituri te salutant\n");
  }

  return 0;
}
