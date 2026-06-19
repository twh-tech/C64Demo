// VIC-II Register Definitions
// For a full register map see: https://www.c64-wiki.com/wiki/VIC

// Control register 1
// Bits 0-2: vertical fine scroll (0-7)
// Bit 3: 24/25 row select (0=24 rows, 1=25 rows)
// Bit 4: display enable (0=blank, 1=display on)
// Bit 5: bitmap/text mode (0=text, 1=bitmap)
// Bit 6: extended color mode
// Bit 7: high bit of raster line counter
.label VICICR          = $d011

// Raster counter/compare register
// Read: current raster line (low 8 bits, high bit in VICICR bit 7)
// Write: raster line to trigger IRQ on
.label VICRASTER       = $d012

// Sprite enable register
// Bit 0 = sprite 0
// Bit 1 = sprite 1
// Bit 2 = sprite 2
// Bit 3 = sprite 3
// Bit 4 = sprite 4
// Bit 5 = sprite 5
// Bit 6 = sprite 6
// Bit 7 = sprite 7
.label VIC_SPRITE_ENABLE = $D015

// Control register 2 / horizontal scroll
// Bits 0-2: horizontal fine scroll (0-7)
// Bit 3: 38/40 column select (0=38 cols, 1=40 cols)
// Bit 4: multicolor mode enable
.label VICXSCROLL      = $d016

// Memory control register
// Bits 1-3: character set base address (within VIC bank, x * $0800)
// Bits 4-7: screen RAM base address (within VIC bank, x * $0400)
.label VICMEMCTRL      = $d018

// IRQ status register
// Bit 0: raster IRQ occurred
// Bit 1: sprite/background collision
// Bit 2: sprite/sprite collision
// Bit 3: light pen triggered
// Write $01 to acknowledge raster IRQ
.label VICIRQFLAG      = $d019

// Border color register (bits 0-3)
.label VICBORDER       = $d020

// Background color register (bits 0-3)
.label VICBGCOLOR      = $d021

// IRQ enable register
// Bit 0: enable raster IRQ
// Bit 1: enable sprite/background collision IRQ
// Bit 2: enable sprite/sprite collision IRQ
// Bit 3: enable light pen IRQ
.label VICIRQENABLE    = $d01a

// VICICR value for display on, 25 rows, no scroll, text mode
.label DISPLAYON       = %00011011
.label DISPLAYOFF	   = %00001011
