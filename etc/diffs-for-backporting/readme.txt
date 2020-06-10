diff --unified --ignore-all-space minimal.edited latest >the-diff.diff

minimal.edited:
  a slightly edited version of minimal eval.l (and co.) to reduce diff noise.
  e.g. definitions are reordered and systemic differences (like is_long)
  are "backported" into it.

the-diff.diff:
  the stuff that was successfully backported will gradually
  be deleted from this file.

strategy:
 - i won't port the tagged long stuff, i'll do it differently, on the meta level.

list of search/replace stuff when backporting:
 - is_long -> is/long
