;Purpose: defines utility macros
;As this could be included anywhere, wrap all macros in .definedmacro
;.if    .definedmacro(<macroname>)
;.else
;.macro  <macroname> <macroargs>
;  <macro stuff>
;.endmacro
;.endif


.if    .definedmacro(load_addr_to_zp_macro)
.else
.macro  load_addr_to_zp_macro source_addr, zp_addr
;Description
;  loads the address into the specified zp
;Arguments
;  addr - static addr (like a symbol)
;  zp - zero page address
;Preconditions
;  none
;Side Effects
;  addr -> zp
;Note
;  The macro is overengineering, but I am using this to play with macros. "I'm learnding!"
  pha
  lda #<source_addr ; The low byte of the 16 bit address pointer is loaded into A
  sta zp_addr
  lda #>source_addr ; the high byte of the pointer
  sta zp_addr+1
  pla
.endmacro
.endif

.if    .definedmacro(delay_macro)
.else
.macro delay_macro acount, ycount
;Description
;  delays for a calculable amount of cycles
;Arguments
;  None
;Preconditions
;  non
;Side Effects
;  nop
;Note
;  formula
;    The delay is 9*(256*A+Y)+8 cycles
;
;    For example, to get approx 500k cyles
;          acount - #$d9
;          ycount - #$01
;     9*($100*$d9+$01)+8 = $7A111 = 499985 
;     499985 + JSR(6) + RTS(6) = 499997
;TODO: pha phy pla ply
  .local delay
  pha
  phy
  lda acount
  ldy ycount
delay:
  cpy #1
  dey
  sbc #0
  bcs delay
  ply
  pla
.endmacro
.endif



