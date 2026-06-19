// VIC-II constants

.const VIC2Sprite0X       = $D000
.const VIC2Sprite0Y       = $D001
.const VIC2Sprite4X       = $D008
.const VIC2Sprite4Y       = $D009

.const VIC2ScreenControlH = $D011
.const VIC2Raster         = $D012
.const VIC2SpriteXMSB     = $D010
.const VIC2SpriteEnable   = $D015

.const VIC2ScreenColour   = $D021

.const VIC2Sprite0Colour  = $D027
.const VIC2Sprite1Colour  = $D028

.const VIC2Colour_Black   = 0
.const VIC2Colour_White   = 1


* = $1000

    sei
    clc

    // Enable all sprites
    lda #%11111111
    sta VIC2SpriteEnable

    // Sprite Y positions
    lda #100

    .for (var i = 0; i < 4; i++) {
        sta VIC2Sprite0Y + i * 2
        sta VIC2Sprite4Y + i * 2
        adc #21
    }

    // Sprite colours
    lda #VIC2Colour_Black
    ldx #VIC2Colour_White

    .for (var i = 0; i < 4; i++) {
        sta VIC2Sprite0Colour + i * 2
        stx VIC2Sprite1Colour + i * 2
    }

    // Sprites 0-3 X positions
    lda #0

    .for (var i = 0; i < 4; i++) {
        sta VIC2Sprite0X + i * 2
        adc #8
    }

    // Sprites 4-7 X positions
    lda #72

    .for (var i = 0; i < 4; i++) {
        sta VIC2Sprite4X + i * 2
        adc #8
    }

    lda #%11110000
    sta VIC2SpriteXMSB

// Show cycle jitter

l1:
    ldy #80

l2:
wl1:
    cpy VIC2Raster
    bne wl1

    dec VIC2ScreenColour
    dec VIC2ScreenControlH
    inc VIC2ScreenColour
    inc VIC2ScreenControlH

    iny
    cpy #200
    bne l2

    jmp l1


// Equivalent of ACME:
// !for .i , 40 { !scr "testing... " }

.encoding "screencode_upper"

.for (var i = 0; i < 40; i++) {
    .text "testing... "
}


// Sprite pointers

* = $07F8

.byte 16,17,18,19,20,21,22,23