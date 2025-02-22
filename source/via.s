;PURPOSE - defines the static register references for the via interface as provided by Ben Eater's videos https://eater.net/6502
;
;This file was based on https://github.com/dbuchwald/cc65-tools/blob/main/tutorial/03_blink/blink.s (aside from the comments)

;====================================================
;Exports
  .import __VIA1_START__

  .export VIA1_PORTB
  .export VIA1_PORTA
  .export VIA1_DDRB
  .export VIA1_DDRA
  .export VIA1_T1CL
  .export VIA1_T1CH
  .export VIA1_T1LL
  .export VIA1_T1LH
  .export VIA1_T2CL
  .export VIA1_T2CH
  .export VIA1_SR
  .export VIA1_ACR
  .export VIA1_PCR
  .export VIA1_IFR
  .export VIA1_IER
  .export VIA1_PANH

  .export via_init

VIA_REGISTER_PORTB = $00
VIA_REGISTER_PORTA = $01
VIA_REGISTER_DDRB  = $02
VIA_REGISTER_DDRA  = $03
VIA_REGISTER_T1CL  = $04
VIA_REGISTER_T1CH  = $05
VIA_REGISTER_T1LL  = $06
VIA_REGISTER_T1LH  = $07
VIA_REGISTER_T2CL  = $08
VIA_REGISTER_T2CH  = $09
VIA_REGISTER_SR    = $0a
VIA_REGISTER_ACR   = $0b
VIA_REGISTER_PCR   = $0c
VIA_REGISTER_IFR   = $0d
VIA_REGISTER_IER   = $0e
VIA_REGISTER_PANH  = $0f

VIA1_PORTB = __VIA1_START__ + VIA_REGISTER_PORTB
VIA1_PORTA = __VIA1_START__ + VIA_REGISTER_PORTA
VIA1_DDRB  = __VIA1_START__ + VIA_REGISTER_DDRB
VIA1_DDRA  = __VIA1_START__ + VIA_REGISTER_DDRA
VIA1_T1CL  = __VIA1_START__ + VIA_REGISTER_T1CL
VIA1_T1CH  = __VIA1_START__ + VIA_REGISTER_T1CH
VIA1_T1LL  = __VIA1_START__ + VIA_REGISTER_T1LL
VIA1_T1LH  = __VIA1_START__ + VIA_REGISTER_T1LH
VIA1_T2CL  = __VIA1_START__ + VIA_REGISTER_T2CL
VIA1_T2CH  = __VIA1_START__ + VIA_REGISTER_T2CH
VIA1_SR    = __VIA1_START__ + VIA_REGISTER_SR
VIA1_ACR   = __VIA1_START__ + VIA_REGISTER_ACR
VIA1_PCR   = __VIA1_START__ + VIA_REGISTER_PCR
VIA1_IFR   = __VIA1_START__ + VIA_REGISTER_IFR
VIA1_IER   = __VIA1_START__ + VIA_REGISTER_IER
VIA1_PANH  = __VIA1_START__ + VIA_REGISTER_PANH

;====================================================
;Reserve RAM addresses
;nothing here

;====================================================
;Includes
;nothing here

;====================================================
;Macros
;nothing here

;====================================================
;Code
.segment "VIA_CODE"

via_init:
;Description
;  sets all the known via to input states
;Arguments
;  None
;Preconditions
;  None, but via should be awake
;Side Effects
;  * all known via ports are set to input
;Notes
;  Decided on input as the default as it might prevent us from accidentally setting the wrong pin high and creating
;  magic smoke
pha
lda #%00000000
sta VIA1_DDRA
sta VIA1_DDRB
pla
; 