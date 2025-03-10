# Shrimpy
This is my attempt at slowly building up a 6502 based microcomputer loosely structured around Ben Eater's lessons. I will wander off and chase squirrels, wrestle with interesting problems, and generally follow the "rule of cool" when deciding what to do next.

![schematic](schematics/shrimpy.png)

# Current Status
3/9/2025 - Schematic updated, got most of the wiring down for the UART, just figuring out which clock I want to use

# Goals
See [Shopping List](shopping_list.md) for parts that I would need to get for these.
- [x] Implement custom characters for the LCD, it NEEDS DINOSAURS
  - [x] Bonus points: make the dinosaur march across the LCD
- [X] Implement PLD memory address decoder to effectively double RAM. [(ATF22V10C)](https://www.mouser.com/ProductDetail/Microchip-Technology/ATF22V10CQZ-20PU?qs=2mdvTlUeTfCbTTksYbflfg%3D%3D&countryCode=US&currencyCode=USD)
- [ ] Implement UART DB9 serial adapter
- [x] Get the schematic built in kicad and included in this repository
- [ ] Implement wozmon
- [ ] Implement basic
- [ ] Implement cold start menu that lets user select from basic or wozmon
- [ ] Implement keyboard support (ps2)
- [ ] Implement video using TMS9918
- [ ] Implement storage support either through SPI or I2C

# Current Features
## Hardware
* Wire wrap connections for pretty much everything except for power for durablity and ease of maintenance. Seriously, wire wrapping goes SO GOOD with breadboard prototyping.
* 28 pin ZIF socket for the EEPROM. [https://www.pcbway.com/project/shareproject/Breadboard_to_28p_wide_ZIF_adapter_fc6528ee.html]
### Datasheets
* [w65c02s - MPU](doc/w65c02s.pdf)
* [w65c22 - VIA](doc/w65c22.pdf)
* [HD44780 - LCD](doc/HD44780.pdf) - implemented in 4 bit mode
* [ATF22V10CQZ - Address decoder PLD](doc/doc0778-3445105.pdf) - using logic from Daryl Rictor @ https://sbc.rictor.org/decoder.html
* [DS1813 - Reset Supervisor](doc/DS1813-3468265.pdf) - Thank you Garth Wilson @ http://wilsonminesco.com/6502primer/RSTreqs.html
* [SN74HC11 - Interrupt combiner](doc/sn74hc11.pdf)
## Software
Project was initially based on Ben Eater's [keyboard.s](https://eater.net/downloads/keyboard.s)
* Modularized development (no monolithic code, I tried to break the project into distinct files that could be re-used in future efforts)
* Leaning into CC65's provided functionality including:
  * Using the linker configuration file to declare memory blocks, and map segments to the respective memory blocks
  * Using (.res)erved symbols to _declare_ variables and map them to general ram or ZP as appropriate
  * Basically never having to deal with static addresses ever. Everything is dynamically handled by the linker.
  * Exploring & utilizing macros
* Working on heavily restricting the need for and usage of magic number/symbols.
* Got the LCD consistenly initializing on cold start and reset, writing to two lines in both scenarios.
  * Did it by implementing the full initialization by instruction sequence for 4-bit operation
* Custom characters for the LCD (yay dinosaurs)
* Using a via timer an interrupt driven main loop, no more busy work delays!
