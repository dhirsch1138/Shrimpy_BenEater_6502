;export custom char set addresses
.export customcharset

;export custom char def addresses
.export dinorightchar
.export fullheartchar
.export emptyheartchar
.export cakechar
.export cakealt1char
.export cakealt2char

.segment "CHAR_CODE"

.include "characters_statics.inc"
;custom character definitions:
;
;The datasheet says we get eight usuable custom character address that are in CGRAM (addressible in DDROM as $00 - $08)
;
;To make referencing these characters simple, I created a basic structure for 5x8 font custom character definitions
; * Offset 0    - DDRAM address
; * Offset 1-8  - bytes to write to CGRAM
;
;The primary benefit of this structure is that the program can simply reference the label when wanting to send the custom character,
;as offset 0 is the DDRAM that the custom character should be addressible at (if it was loaded)
;
;The lcd_load_custom_character_macro macro handles the translation of the DDROM address to the applicable CGRAM addresses that the character will be
;stored.
customcharset:
  .byte $06
dinorightchar:
  .byte DINORIGHTCHAR ;DDRAM address 
  .byte %00001111  ;b0
  .byte %00001010  ;b1
  .byte %00001111  ;b2
  .byte %00001100  ;b3
  .byte %00001110  ;b4
  .byte %00011100  ;b5
  .byte %00001010  ;b6
  .byte %00000000  ;b7

fullheartchar:
  .byte FULLHEARTCHAR  ;DDRAM address 
  .byte %00000000  ;b0
  .byte %00001010  ;b1
  .byte %00011111  ;b2
  .byte %00011111  ;b3
  .byte %00001110  ;b4
  .byte %00000100  ;b5
  .byte %00000000  ;b6
  .byte %00000000  ;b7

emptyheartchar:
  .byte EMPTYHEARTCHAR  ;DDRAM address 
  .byte %00000000  ;b0
  .byte %00001010  ;b1
  .byte %00010101  ;b2
  .byte %00010001  ;b3
  .byte %00001010  ;b4
  .byte %00000100  ;b5
  .byte %00000000  ;b6
  .byte %00000000  ;b7  

cakechar: 
  .byte CAKECHAR ;DDRAM address 
  .byte %00000000  ;b0
  .byte %00000000  ;b1
  .byte %00000000  ;b2
  .byte %00001010  ;b3
  .byte %00011111  ;b4
  .byte %00010001  ;b5
  .byte %00011111  ;b6
  .byte %00000000  ;b7

cakealt1char:
  .byte CAKEALT1CHAR ;DDRAM address 
  .byte %00000010  ;b0
  .byte %00000000  ;b1
  .byte %00000000  ;b2
  .byte %00001010  ;b3
  .byte %00011111  ;b4
  .byte %00010001  ;b5
  .byte %00011111  ;b6
  .byte %00000000  ;b7

cakealt2char:
  .byte CAKEALT2CHAR ;DDRAM address 
  .byte %00000000  ;b0
  .byte %00000100  ;b1
  .byte %00000000  ;b2
  .byte %00001010  ;b3
  .byte %00011111  ;b4
  .byte %00010001  ;b5
  .byte %00011111  ;b6
  .byte %00000000  ;b7