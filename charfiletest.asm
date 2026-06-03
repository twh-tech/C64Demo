* = $0801
.word next
.word 10
.byte $9e
.text "2064"
.byte 0
next: .word 0
* = $0810
.const SCREEN = $0400
.const TOP_DATA = $1000
.const BOT_DATA = $1100

start:
        lda     #$1a
        sta     $d018
        lda     #0
        sta     col
        sta     rowoffset_lo
        sta     rowoffset_hi
        ldx     #0

mainloop:
        lda     TOP_DATA,x
        cmp     #$ff
        beq     done

        lda     TOP_DATA,x
        sta     curtop
        lda     BOT_DATA,x
        sta     curbot

        // Determine width by checking top tile code
        // Space top = $20 (1-wide)
        // J top = $22 (1-wide)
        // I top = $8e (1-wide)
        // W top = $54 (3-wide)
        // Everything else = 2-wide
        lda     curtop
        cmp     #$20
        beq     width1
        cmp     #$22
        beq     width1
        cmp     #$8e
        beq     width1
        cmp     #$54
        beq     width3
        jmp     width2

width1:
        // Need 1 column free
        lda     col
        cmp     #40
        bcc     place1
        jsr     newline
place1:
        jsr     place_tile_1
        lda     col
        clc
        adc     #1
        sta     col
        inx
        jmp     mainloop

width2:
        // Need 2 columns free — wrap if col >= 39
        lda     col
        cmp     #39
        bcc     place2
        jsr     newline
place2:
        jsr     place_tile_2
        lda     col
        clc
        adc     #2
        sta     col
        inx
        inx
        jmp     mainloop

width3:
        // Need 3 columns free — wrap if col >= 38
        lda     col
        cmp     #38
        bcc     place3
        jsr     newline
place3:
        jsr     place_tile_3
        lda     col
        clc
        adc     #3
        sta     col
        inx
        inx
        inx
        jmp     mainloop

done:
        jsr     $ffcc
        rts

// Compute 16-bit screen address into $fb/$fc
// Result = SCREEN + rowoffset + col
calc_addr:
        lda     #<SCREEN
        clc
        adc     rowoffset_lo
        sta     $fb
        lda     #>SCREEN
        adc     rowoffset_hi
        sta     $fc
        lda     $fb
        clc
        adc     col
        sta     $fb
        bcc     NOADD
        inc     $fc
NOADD:
        rts

// Place a 1-wide tile at current col/rowoffset
place_tile_1:
        jsr     calc_addr
        ldy     #0
        lda     curtop
        sta     ($fb),y
        lda     $fb
        clc
        adc     #40
        sta     $fb
        bcc     NOBORROW1
        inc     $fc
NOBORROW1:
        lda     curbot
        sta     ($fb),y
        rts

// Place a 2-wide tile at current col/rowoffset
place_tile_2:
        jsr     calc_addr
        ldy     #0
        lda     TOP_DATA,x
        sta     ($fb),y
        iny
        lda     TOP_DATA+1,x
        sta     ($fb),y
        lda     $fb
        clc
        adc     #40
        sta     $fb
        bcc     NOBORROW2
        inc     $fc
NOBORROW2:
        ldy     #0
        lda     BOT_DATA,x
        sta     ($fb),y
        iny
        lda     BOT_DATA+1,x
        sta     ($fb),y
        rts

// Place a 3-wide tile at current col/rowoffset
place_tile_3:
        jsr     calc_addr
        ldy     #0
        lda     TOP_DATA,x
        sta     ($fb),y
        iny
        lda     TOP_DATA+1,x
        sta     ($fb),y
        iny
        lda     TOP_DATA+2,x
        sta     ($fb),y
        lda     $fb
        clc
        adc     #40
        sta     $fb
        bcc     NOBORROW3
        inc     $fc
NOBORROW3:
        ldy     #0
        lda     BOT_DATA,x
        sta     ($fb),y
        iny
        lda     BOT_DATA+1,x
        sta     ($fb),y
        iny
        lda     BOT_DATA+2,x
        sta     ($fb),y
        rts

newline:
        lda     #0
        sta     col
        lda     rowoffset_lo
        clc
        adc     #80
        sta     rowoffset_lo
        bcc     NOINC
        inc     rowoffset_hi
NOINC:
        rts

col:            .byte 0
rowoffset_lo:   .byte 0
rowoffset_hi:   .byte 0
curtop:         .byte 0
curbot:         .byte 0

* = $1000
.import binary "scroll_top.bin"
.byte $ff

* = $1100
.import binary "scroll_bot.bin"
.byte $ff

* = $2800
.var charset = LoadBinary("ace2char.bin", BF_C64FILE)
.fill charset.getSize(), charset.get(i)