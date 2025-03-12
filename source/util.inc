;PURPOSE - Imports needed symbols defined in util.s
; No adjustable defines in this file.

.global delay_ms_1000
.global delay_ms_500
.global delay_ms_100
.global delay_ms_50
.global delay_ms_10
.global util_joinnibbles

;Utilty macros
;========================================================================================================

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
;  Bruce Clark / dclxvi http://forum.6502.org/viewtopic.php?p=62581#p62581
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
;     499985 + 18 = 500003
;       pha - 3
;       phy - 3
;       pla - 4
;       ply - 4
;       lda (immediate) - 2
;       ldy (immediate) - 2
  .local @delay
  pha
  phy
  lda acount
  ldy ycount
@delay:
  cpy #1
  dey
  sbc #0
  bcs @delay
  clc
  ply
  pla
.endmacro
.endif


.if    .definedmacro(swn_macro)
.else
.macro swn_macro
;SWN (SWap Nybble) instruction
;Credit David Galloway
;http://6502.org/source/general/SWN.html & http://wilsonminesco.com/6502primer/PgmTips.html
  ASL  A
  ADC  #$80
  ROL  A
  ASL  A
  ADC  #$80
  ROL  A
.endmacro
.endif

.if    .definedmacro(inc_word_at_addr_macro)
.else
.macro inc_word_at_addr_macro addr
;Description
;  increments the word (16 bit value) stored in the provided address
;  this can be used the increment addresses stored in RAM
;Arguments
;  adder - Address housing word to increment 
;Preconditions
;  none
;Side Effects
;  word @ addr is incremented
;Note
;  I am still working on how 16 bit values are handled in an 8 bit context, so there might be better ways to do this
.local @skiphigh
  inc addr
  bne @skiphigh
  inc addr+1
@skiphigh:
  clc
.endmacro
.endif

.if    .definedmacro(inc_dword_at_addr_macro)
.else
.macro inc_dword_at_addr_macro addr
;Description
;  increments the dword (32 bit valuee) stored in the provided address
;  this can be used the increment addresses stored in RAM
;Arguments
;  adder - Address housing dword to increment 
;Preconditions
;  none
;Side Effects
;  dword @ addr is incremented
;Note
;  I am still working on how 32 bit values are handled in an 8 bit context, so there might be better ways to do this
.local @no_carry
  pha
  inc addr
  bne @no_carry
  inc addr + 1
  bne @no_carry
  inc addr + 2
  bne @no_carry
  inc addr + 3
@no_carry:
  clc
  pla
.endmacro
.endif

.if    .definedmacro(adc_dword_at_addr_macro)
.else
.macro adc_dword_at_addr_macro addr, value
;Description
;  Adds the provided value to the dword (32 bit valuee) stored in the provided address
;  this can be use to increment addresses stored in RAM
;Arguments
;  addr - Address housing dword to add to 
;  value - what to add to the dword at the provided address
;Preconditions
;  none
;Side Effects
;  dword @ addr is increased by value
;  carry flag is overwritten
;  A is squished
;  Carry status flag 'should' accurately reflect if there was any carry from the low bit.
;Note
;  I am still working on how 3 bit values are handled in an 8 bit context, so there might be better ways to do this
.local @no_carry
  pha
  lda addr
  adc value
  sta addr
  bcc @no_carry
  inc addr + 1
  bne @no_carry
  inc addr + 2
  bne @no_carry
  inc addr + 3
@no_carry:
  clc
  pla
.endmacro
.endif

.if    .definedmacro(copy_dwords_at_addrs_macro)
.else
.macro copy_dwords_at_addrs_macro from_addr, to_addr
;Description
;  copies the dword (32 bit valuee) stored in the provided address from_addr
;  to the dword stored in provided address to_addr
;Arguments
;  from_adder - Address housing dword to copy
;  to_adder -Address to copy the dword to. Existing contents will be overwritten
;Preconditions
;  none
;Side Effects
;  copies dword from from_addr to to_addr
;  A is squished
;Note
;  I am still working on how 32 bit values are handled in an 8 bit context, so there might be better ways to do this
  lda from_addr
  sta to_addr
  lda from_addr + 1
  sta to_addr + 1
  lda from_addr + 2
  sta to_addr + 2
  lda from_addr + 3
  sta to_addr + 3   
.endmacro
.endif

.if    .definedmacro(compare_dwords_at_addrs_macro)
.else
.macro compare_dwords_at_addrs_macro dword_B, dword_A 
;Description
;  compares two dwords to see if dword_B - dword_A >= 0
;Arguments
;  dword_A - address of 32 bit value (double word)
;  dword_B - address of 32 bit value (double word)
;Preconditions
;  dword_A & dword_B must be initialized
;Side Effects
;  A is squished
;Returns
;  carry flag is set if dword_B - dword_A >= 0
;  else carry flag is clear
;Note
;  I am still working on how 32 bit values are handled in an 8 bit context, so there might be better ways to do this
.local @true
.local @false
.local @end
  lda dword_B + 3 ; starting with the highest byte of the 32 bit dword_A
  cmp dword_A + 3
  bmi @false
  lda dword_B + 2
  cmp dword_A + 2
  bmi @false
  lda dword_B + 1
  cmp dword_A + 1
  bmi @false  
  lda dword_B
  cmp dword_A
  bmi @false
@true:
  sec
  jmp @end
@false:
  clc
@end:
.endmacro
.endif