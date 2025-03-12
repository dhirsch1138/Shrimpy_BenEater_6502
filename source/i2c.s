.include "via.inc"
.include "defines.inc"

;LCD defines from defines.inc
;========================================================================================================

.if I2C_USES_VIA_PORT = 'B'
			PA  = VIA1_PORTB
			DDRA = VIA1_DDRB
.elseif I2C_USES_VIA_PORT = 'A'
			PA  = VIA1_PORTA
			DDRA = VIA1_DDRA
.else
.error "I2C_USES_VIA_PORT defined is not recognized, check defines.inc"
.endif


.segment "I2C_RAM"
I2C_TEMP:        .byte  $00
.segment "I2C_CODE"

.include "i2c.inc"

.macro I2C_DATA_UP
             LDA   #%10000000   ; Two instructions here.  Clear bit 7 of the DDR
			 TRB   DDRA         ; to make PA7 an input and let it float up.
.endmacro
 ;-----------------------

.macro I2C_DATA_DN
             LDA   #%10000000   ; Two instructions here.  Set bit 7 of the DDR
             TSB   DDRA         ; to make PA7 an output and pull it down since
.endmacro                       ; bit 7 of the output register is a 0.
 ;-----------------------

.macro I2C_CLK_UP               ; (as above)
             LDA   #1
             TRB   DDRA
.endmacro
 ;-----------------------

.macro I2C_CLK_DN               ; (as above)
             LDA   #1
             TSB   DDRA
.endmacro
 ;-----------------------

I2C_START:   I2C_DATA_UP
             I2C_CLK_UP
             I2C_DATA_DN
 ist1:       INC   DDRA         ; Clk down.  We now know the bit val, so just INC.
             TRB   DDRA         ; Data up, using accum val left from I2C_DATA_DN above.
             RTS
 ;-----------------------

I2C_STOP:    I2C_DATA_DN
             I2C_CLK_UP
             I2C_DATA_UP
             BRA   ist1
 ;-----------------------

I2C_ACK:     I2C_DATA_DN        ; Acknowledge.  The ACK bit in I2C is the 9th bit of a "byte".
 ia1:        I2C_CLK_UP         ;               and acknowledging consists of pulling it down.
             INC   DDRA         ; Clk down.  We know the bit val, so just INC.
             I2C_DATA_UP
             RTS
 ;-----------------------

I2C_NAK:     I2C_DATA_UP        ; Not acknowledge.
             BRA   ia1
 ;-----------------------

I2C_ACKQ:    I2C_DATA_UP        ; At end, N=0 means ACK.  N=1 means NAK.
             I2C_CLK_UP
             BIT   PA           ; Bit 7 (the data line) gets put in the N flag.
             TSB   DDRA         ; Clk down.  Accum still has 1 from I2C_CLK_UP.  Take advantage.
             RTS
 ;-----------------------

INIT_I2C:                       ; Set up the port bit directions and values.  Leaves clk & data low.
        LDA     #%10000000
        INC     A               ; Put 10000001B in A for data and clock lines on port A.
        TSB     DDRA            ; Make PA0 and PA7 outputs to hold clock and data low
        TRB     PA              ; and make the output value to be 0 for the same.
        RTS
 ;------------------

CLR_I2C:                        ; This clears any unwanted transaction that might be in progress, by giving
        JSR     I2C_STOP        ;    enough clock pulses to finish a byte and not acknowledging it.
        JSR     I2C_START
        I2C_DATA_UP             ; Keep data line released so we don't ACK any byte sent by a device.
        LDX     #9              ; Loop 9x to send 9 clock pulses to finish any byte a device might send.
 ci2c:     DEC  DDRA            ; Like I2C_CLK_UP since we know I2C_START left clock down (DDRA bit 0 high).
           INC  DDRA            ; Like I2C_CLK_DN since we know the state from the above instruction.
           DEX
        BNE     ci2c
        JSR     I2C_START
        JMP     I2C_STOP        ; (JSR, RTS)
 ;------------------

SEND_I2C_BYTE:                  ; Start with byte in A, and clock low.  Ends with I2C_ACKQ
        STA     I2C_TEMP        ; Store the byte in a variable so we can use A with TSB & TRB for data line.
        LDA     #%10000000      ; Init A for mask for TRB & TSB below.  A does not get disturbed below.
        LDX     #8              ; We will do 8 bits.
 sIb2:     TRB  DDRA            ; Release data line.  This is like I2C_DATA_UP but saves 1 instruction.
           ASL  I2C_TEMP        ; Get next bit to send and put it in the C flag.
           BCS  sIb1
              TSB DDRA          ; If the bit was 0, pull data line down by making it an output.
 sIb1:     DEC  DDRA            ; Do a high pulse on the clock line.  Remember there's a 0 in the output
           INC  DDRA            ; register bit, and DEC'ing DDRA makes that bit an input, so it can float up.
           DEX                  ;    IOW, it's backwards from what it seems.
        BNE     sIb2
        JMP     I2C_ACKQ        ; (JSR, RTS)
 ;------------------

RCV_I2C_BYTE:                   ; Start with clock low.  Ends with byte in I2C_TEMP.  Do ACK bit separately.
        I2C_DATA_UP             ; Make sure we're not holding the data line down.  Be ready to input data.
        LDX     #8              ; We will do 8 bits.  There's no need to init I2C_TEMP.
 rIb1:     DEC  DDRA            ; Set clock line high.
           ASL  I2C_TEMP        ; Get the forming byte's next bit position ready to accept the bit.
           BIT  PA              ; Read the data line value into N flag.
           BPL  rIb2            ; If the data line was high,
              INC  I2C_TEMP     ; increment the 1's place to a 1 in the forming byte.  (ASL made bit 0 = 0.)
 rIb2:     INC  DDRA            ; Put clock line back low.
           DEX
        BNE     rIb1            ; Go back for next bit if there is one.
        RTS
 ;------------------