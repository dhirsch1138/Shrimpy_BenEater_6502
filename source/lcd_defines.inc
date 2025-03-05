;LCD defines
;==========================

;*** LCD init type
; uncomment to do init by instruction (default is normal internal LCD reset)
;LCD_DO_INSTRUCTION_INIT = $01


;** Adjust these to fit implementation with your VIA(s)
LCD_VIA_DDR = VIA1_DDRB
LCD_VIA_PORT = VIA1_PORTB

;*** DDR masks that will be applied to the LCD_VIA_DDR
; Current implementation is using ports D0 - D6
LCD_VIA_OUTPUTMASK = %01111111
LCD_VIA_INPUTMASK = %11110000
