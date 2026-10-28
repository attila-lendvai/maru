/* A growable byte buffer. Used by the reader for symbols, numbers and
 * string literals. The contents are NUL terminated.
 */

struct buffer
{
  char	*buffer;
  int	 size;
  int	 position;
};

#define BUFFER_INITIALISER { 0, 0, 0 }

static void buffer_reset(struct buffer *b)		{ b->position= 0; }
static int  buffer_position(struct buffer *b)		{ return b->position; }

static void buffer_append(struct buffer *b, int c)
{
  if (b->position == b->size)
    b->buffer= b->buffer
	? realloc(b->buffer, (b->size *= 2) + 1)
	: malloc((b->size= 32) + 1);
  b->buffer[b->position++]= c;
  b->buffer[b->position]= 0;
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
