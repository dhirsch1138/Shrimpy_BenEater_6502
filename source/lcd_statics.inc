;control symbols
;==================
LCD_PIN_E  = %01000000
LCD_PIN_RW = %00100000
LCD_PIN_RS = %00010000 

;instruction masks
;==================
LCD_INST_CRAMADR = %01000000
LCD_INST_FUNCSET = %00100000
LCD_INST_CURSHFT = %00010000
LCD_INST_DISPLAY = %00001000
LCD_INST_ENTRYMO = %00000100
LCD_INST_RTNHOME = %00000010
LCD_INST_CLRDISP = %00000001

;function masks (use w/ LCD_INST_FUNCSET)
;==================
;000XXX00
LCD_FUNCSET_DATA = %00010000 ;8-bit mode (default 4-bit mode)
LCD_FUNCSET_LINE = %00001000 ;two line mode (default one line mode)
LCD_FUNCSET_SIZE = %00000100 ;5x10 characters (default 5x8)

;cursor shift masks (use w/ LCD_INST_CURSHFT)
;==================
;0000XX00
LCD_CURSHFT_MOVE = %00001000 ; display shifts (default cursor shifts)
LCD_CURSHFT_SDIR = %00000100 ; shift right (default shift left)

;display masks (use w/ LCD_INST_DISPLAY)
;==================
;00000XXX
LCD_DISPLAY_DSON = %00000100 ; display on (default display off)
LCD_DISPLAY_CUON = %00000010 ; cursor on (default cursor off)
LCD_DISPLAY_BLON = %00000001 ; blink on (default blink off)

;entry mode masks (use w/ LCD_INST_ENTRYMO)
;==================
;000000XX
LCD_ENTRYMO_INCR = %00000010 ; increment cursor (default decrement cursor)
LCD_ENTRYMO_ADSH = %00000001 ; accompanies display shift (default no)

;DDRAM shortcuts
;==================
LCD_DDRAM2LN58CR = %11000000 ; set the DDRRAM address to the start of the 2nd line (if 2line mode, 5x8 characters)