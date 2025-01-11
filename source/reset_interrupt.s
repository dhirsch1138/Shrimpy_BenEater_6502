;PURPOSE - Writes the reset pointer (and future interrupts?) at segment "VECTORS"
;

;We defined the 'code' segment in the configuration, so we can import the symbol for where the
;'code' segment is loaded.
.import __CODE_LOAD__

;The reset references the segment "VECTORS" is defined in linker.cfg
;see how we can define addresses in the linker.cfg and cc65 just knows where to put stuff? Neat!
.segment "VECTORS"
  .word $0000
  .word __CODE_LOAD__
  .word $0000