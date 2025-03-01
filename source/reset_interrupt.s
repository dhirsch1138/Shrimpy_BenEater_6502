;PURPOSE - Writes the reset pointer (and future interrupts?) at segment "VECTORS"
;

.include "main.inc"

;The reset references the segment "VECTORS" is defined in linker.cfg
;see how we can define addresses in the linker.cfg and cc65 just knows where to put stuff? Neat!
.segment "VECTORS"
  .addr interrupt
  .addr reset
  .addr interrupt