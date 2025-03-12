
; This is where you define the clock speed of your system
; supported values:
; * 1000 = 1.000 mhz
; * 1843 = 1.843 mhz
; * 2000 = 2.000 mhz
; * 4000 = 4.000 mhz
DEFINE_OSCILLATOR = 1843



;#########################################
;LCD DEFINES
;
; uses VIA1
;

LCD_USES_VIA_PORT = 'B' ;defines which output port we're using = 'A' or 'B'
;defines the DDR input and output masks assigned when doing LCD operations
LCD_USES_VIA_OUTPUTMASK = %01111111
LCD_USES_VIA_INPUTMASK = %11110000
;LCD_DO_INSTRUCTION_INIT = $01 ;LCD init type - uncomment to do init by instruction (default is normal internal LCD reset)
LCD_CONNECTION = 'V' ; LCD connection type, either 'V'ia or 'I'2C
LCD_I2C_ADDR = $27 ; I2C address of LCD screen


;#########################################
;I2C DEFINES
;
; uses VIA1
;
I2C_USES_VIA_PORT = 'A' ; ;defines which output port we're using = 'A' or 'B'