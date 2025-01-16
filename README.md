# Shrimpy
This is my attempt at slowly building up a 6502 based microcomputer loosely structured around Ben Eater's lessons. I will wander off and chase squirrels, wrestle with interesting problems, and generally follow the "rule of cool" when deciding what to do next.

# Current Status
LCD is pretty well implemented, I got it behaving after reset.

# Goals
[ ] Implement UART DB9 serial adapter
[ ] Implement wozmon
[ ] Implement basic
[ ] Implement cold start menu that lets user select from basic or wozmon
[ ] Implement keyboard support (ps2)
[ ] Implement video using TMS9918
[ ] Implement storage support either through SPI or I2C

# Current Features
## Hardware
* 4-bit implementation of the LCD
* Wire wrap connections for pretty much everything except for power for durablity and ease of maintenance. Seriously, wire wrapping goes SO GOOD with breadboard prototyping.
* Enhanced durability by removing fragile potentiometers and replacing them with resistors
  * I just dialed in the desired resistence on a potentiometer, measured it using my trusty multimeter, and swapped it out with a resistor. Like the wire wrapped connections, durability is the name of the game.
* 28 pin ZIF socket for the EEPROM. [https://www.pcbway.com/project/shareproject/Breadboard_to_28p_wide_ZIF_adapter_fc6528ee.html]
* Replaced the 74LS00 address decoder with a 74HC00, it can be quicker and it uses much less power.

## Software
Project was initially based on Ben Eater's keyboard.s [https://eater.net/downloads/keyboard.s]
* Modularized development (no monolithic code, I tried to break the project into distinct files that could be re-used in future efforts)
* Leaning into CC65's provided functionality including:
  * Using the linker configuration file to declare memory blocks, and map segments to the respective memory blocks
  * Using (.res)erved symbols to _declare_ variables and map them to general ram or ZP as appropriate
  * Basically never having to deal with static addresses ever. Everything is dynamically handled by the linker.
  * Exploring & utilizing macros
* Working on heavily restricting the need for and usage of magic number/symbols.
* Got the LCD consistenly initializing on cold start and reset, writing to two lines in both scenarios.
