/* This is only needed to make .text writable, so that relocation can
   happen. Once we generate position independent code (PIC) we can get
   rid of this. */

ENTRY(_start)

SECTIONS
{
  . = 0x08048000;

  .text :
  {
    *(.text)
  } :text

  .data : { *(.data) }
  .bss  : { *(.bss COMMON) }
}

PHDRS
{
  text PT_LOAD FLAGS(0x7); /* 0x7 = RWX */
}
