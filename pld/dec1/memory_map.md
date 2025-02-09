
from: https://sbc.rictor.org/decoder.html

The memory decoder described here was design to replace the logic circuits needed to interface RAM, ROM, and up to 4 IO devices to a simple 6502-based computer.

The device chips selects, OE, and WE are all controlled from the microprocessor's address and control signals.

I have named this device - "DEC-1". This is a pinout for the GAL22V10 24-pin DIP package:

       --------
PHI2  |1     24| Vcc
RW    |2     23| /OE
A15   |3     22| /WE
A14   |4     21| /RAM
A13   |5     20| /ROM
A12   |6     19| /IO1
A11   |7     18| /IO2
A10   |8     17| /IO3
A9    |9     16| /IO4
A8    |10    15| A4
A7    |11    14| A5
Gnd   |12    13| A6 
       --------

Using this package, the system memory map would look like this:

$0000-$01FF - RAM (zero page and stack space)
$0200-$020F - IO Device #1 (16 bytes) 
$0210-$021F - IO Device #2 (16 bytes) 
$0220-$022F - IO Device #3 (16 bytes) 
$0230-$023F - IO Device #4 (16 bytes) 
$0240-$02FF - unassigned (can be externally decoded for use) 
$0300-$7FFF - RAM 
$8000-$FFFF - ROM 

