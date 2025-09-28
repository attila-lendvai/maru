/* This is only needed to make .text writable, so that relocation can
   happen on some hardened kernels that enforce ASLR even on non-PIC
   binaries. It's typically not needed in containers, and once we
   generate position independent code (PIC) we can get rid of this
   altogether. */

ENTRY(_start)

SECTIONS
{
  . = 0x08048000;

  .text   : { *(.text) }       :text
  .rodata : { *(.rodata) }     :text
  .data   : { *(.data) }       :data
  .bss    : { *(.bss COMMON) } :data
}

PHDRS
{
  text PT_LOAD FLAGS(0x7); /* 0x7 = RWX */
  data PT_LOAD FLAGS(0x6); /* 0x6 = RW- */
}
