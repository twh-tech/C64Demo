*=$0801
        .byte   $0b,$08
        .byte   $0a,$00
        .byte   $9e
        .byte   $20
        .text   "2064"
        .byte   $00,$00,$00
        *=$0810

.label VICBORDER       = $d020
.label VICBGCOLOR      = $d021
.label VICRASTER       = $d012
.label VICIRQFLAG      = $d019
.label VICIRQENABLE    = $d01a
.label VICICR          = $d011
.label IRQVEC          = $0314
.label TABLESTART      = 15
.label TABLEND         = 288
.label TABLESIZE       = TABLEND - TABLESTART
.label DISPLAYON       = %00011011
.label DISPOFF_TOP     = 36
.label DISPON_LEN      = 200
.label VICXSCROLL      = $d016
.label SCROLLROW       = 12
.label SCROLLRAM       = $0400 + SCROLLROW * 40
.label SCROLLRAM2      = $0400 + (SCROLLROW+1) * 40

// Raster line where PHASE1 starts (IRQ trigger when PHASE1 active)
.label PHASE1_RASTER   = TABLESTART - 1

// Raster line where PHASE2 starts (IRQ trigger when PHASE1 skipped)
.label PHASE2_RASTER   = TABLESTART - 1 + DISPOFF_TOP

START:
        sei

        // Clear pending VIC IRQ flags
        lda     #$ff
        sta     VICIRQFLAG

        // VIC control: clear high raster bit, enable display
        lda     VICICR
        and     #$7f
        sta     VICICR
        lda     #DISPLAYON
        sta     VICICR

        // Disable CIA1 timer IRQ entirely
        lda     #$7f
        sta     $dc0d
        lda     $dc0d

        // Hook $0314
        lda     #<IRQ1
        sta     IRQVEC
        lda     #>IRQ1
        sta     IRQVEC+1

        // Enable VIC raster IRQ
        lda     #$01
        sta     VICIRQENABLE

        // Phase1 skipped, Phase3 active
        lda     #PHASE2_RASTER
        sta     VICRASTER
        lda     #<PHASE2_ENTRY_SKIP
        sta     IRQHANDLER+1
        lda     #>PHASE2_ENTRY_SKIP
        sta     IRQHANDLER+2
        lda     #<PHASE3_LOOP
        sta     PHASE3_JMP+1
        lda     #>PHASE3_LOOP
        sta     PHASE3_JMP+2

        // Circular buffers are pre-filled with $20 (spaces) in declarations
        // Copy initial buffer contents to screen RAM
        lda     #$20
        ldx     #39
COPYINIT:
        sta     SCROLLRAM,x
        sta     SCROLLRAM2,x
        dex
        bpl     COPYINIT

        // Set fine scroll to 7, 38 column mode (bit 3 = 0)
        lda     VICXSCROLL
        and     #%11110000
        ora     #7
        sta     VICXSCROLL

        // Init scroll variables
        lda     #0
        sta     SCROLLCNT
        sta     SCROLLBUFPTR
        lda     #7
        sta     SCROLLX

        // Clear screen
        jsr     $E544

        // Set all color RAM to black
        lda     #$00
        ldx     #$00
COLORLOOP:
        sta     $d800,x
        sta     $d900,x
        sta     $da00,x
        sta     $dae8,x
        inx
        bne     COLORLOOP

        cli
MAINLOOP:
        jmp     MAINLOOP

IRQ1:
        lda     VICIRQFLAG
        and     #$01
        bne     IS_RASTER
        rti

IS_RASTER:
        lda     #$01
        sta     VICIRQFLAG

IRQHANDLER:
        jmp     PHASE1_ACTIVE

        // -------------------------------------------------------
        // PHASE1 active: top border raster lines
        // -------------------------------------------------------
PHASE1_ACTIVE:
        ldx     #$00

PHASE1_LOOP:
        lda     COLORTABLE,x
        sta     VICBORDER
        sta     VICBGCOLOR
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop                             // 22 NOPs = 44
        inx
        cpx     #DISPOFF_TOP
        bne     PHASE1_LOOP

PHASE2_ENTRY_SKIP:
        ldx     #DISPOFF_TOP

PHASE2_ENTRY:
        ldy     #25

PHASE2_GROUP:
        lda     COLORTABLE,x
        sta     VICBORDER
        sta     VICBGCOLOR
        nop
        nop
        nop
        nop                             // 4 NOPs = 8
        inx
        bne     PHASE2_N1

PHASE2_N1:
        lda     COLORTABLE,x
        sta     VICBORDER
        sta     VICBGCOLOR
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop                             // 23 NOPs = 46
        inx
        bne     PHASE2_N2

PHASE2_N2:
        lda     COLORTABLE,x
        sta     VICBORDER
        sta     VICBGCOLOR
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop                             // 23 NOPs = 46
        inx
        bne     PHASE2_N3

PHASE2_N3:
        lda     COLORTABLE,x
        sta     VICBORDER
        sta     VICBGCOLOR
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop                             // 23 NOPs = 46
        inx
        bne     PHASE2_N4

PHASE2_N4:
        lda     COLORTABLE,x
        sta     VICBORDER
        sta     VICBGCOLOR
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop                             // 23 NOPs = 46
        inx
        bne     PHASE2_N5

PHASE2_N5:
        lda     COLORTABLE,x
        sta     VICBORDER
        sta     VICBGCOLOR
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop                             // 23 NOPs = 46
        inx
        bne     PHASE2_N6

PHASE2_N6:
        lda     COLORTABLE,x
        sta     VICBORDER
        sta     VICBGCOLOR
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop                             // 23 NOPs = 46
        inx
        bne     PHASE2_N7

PHASE2_N7:
        lda     COLORTABLE,x
        sta     VICBORDER
        sta     VICBGCOLOR
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop                             // 19 NOPs = 38
        inx
        dey
        beq     PHASE2_DONE
        jmp     PHASE2_GROUP

PHASE2_DONE:
        nop
PHASE3_JMP:
        jmp     PHASE3_LOOP

PHASE3_LOOP:
        lda     COLORTABLE,x
        sta     VICBORDER
        sta     VICBGCOLOR
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop                             // 22 NOPs = 44
        inx
        cpx     #TABLESIZE
        bne     PHASE3_LOOP

        // -------------------------------------------------------
        // OFFSCREEN_WORK: Phase3 active, Phase4+Phase1 time available
        // -------------------------------------------------------
OFFSCREEN_WORK:
        lda     #$00
        sta     VICBORDER
        sta     VICBGCOLOR

        lda     #PHASE2_RASTER
        sta     VICRASTER
        lda     #<PHASE2_ENTRY_SKIP
        sta     IRQHANDLER+1
        lda     #>PHASE2_ENTRY_SKIP
        sta     IRQHANDLER+2
        lda     #<PHASE3_LOOP
        sta     PHASE3_JMP+1
        lda     #>PHASE3_LOOP
        sta     PHASE3_JMP+2

        jsr     $180c
        jsr     UPDATESPEED
        jsr     DOSCROLL

        pla
        tay
        pla
        tax
        pla
        rti

        // -------------------------------------------------------
        // OFFSCREEN_WORK_SKIP: Phase3 skipped, Phase3+Phase4 time available
        // -------------------------------------------------------
OFFSCREEN_WORK_SKIP:
        lda     #$00
        sta     VICBORDER
        sta     VICBGCOLOR

        lda     #PHASE1_RASTER
        sta     VICRASTER

        jsr     $180c
        jsr     UPDATESPEED
        jsr     DOSCROLL

        pla
        tay
        pla
        tax
        pla
        rti

        // -------------------------------------------------------
        // DOSCROLL: update fine scroll, coarse scroll if needed
        // -------------------------------------------------------
DOSCROLL:
        lda     SCROLLX
        sec
        sbc     SCROLLSPEED
        bmi     NEEDCOARSELEFT
        cmp     #8
        bcs     NEEDCOARSERIGHT
        sta     SCROLLX
        jmp     WRITESCROLL

NEEDCOARSELEFT:
        clc
        adc     #8
        sta     SCROLLX
        jsr     COARSELEFT
        jmp     WRITESCROLL

NEEDCOARSERIGHT:
        sec
        sbc     #8
        sta     SCROLLX
        jsr     COARSERIGHT

WRITESCROLL:
        lda     VICXSCROLL
        and     #%11110000
        ora     SCROLLX
        sta     VICXSCROLL
        rts

        // -------------------------------------------------------
        // COARSELEFT: advance circular buffer pointer forward by 1,
        // write new character at (ptr+39) mod 256,
        // copy 40 chars from circular buffer to screen RAM.
        // No shifting needed — pointer increment is the "shift".
        // -------------------------------------------------------
COARSELEFT:
        // Advance pointer — this is the entire "shift" operation
        inc     SCROLLBUFPTR        // 5 cycles — replaces 897 cycle shift loop!

        // New character position = (SCROLLBUFPTR + 39) mod 256
        // Since buffers are page aligned, addition wraps automatically
        lda     SCROLLBUFPTR
        clc
        adc     #39
        tay                         // Y = position for new character

        // Fetch next character from scroll text
        ldx     SCROLLCNT
        lda     SCROLLTEXT,x
        cmp     #$ff                // end of text?
        bne     GOTLEFT
        ldx     #0
        stx     SCROLLCNT
        lda     SCROLLTEXT,x
        inx
        stx     SCROLLCNT
        jmp     STORELEFT
GOTLEFT:
        inx
        stx     SCROLLCNT
STORELEFT:
        // Store new character in both circular buffers
        sta     SCROLLBUF,y
        sta     SCROLLBUF2,y

        // Copy 40 chars from both circular buffers to screen RAM
        // X = buffer read position (wraps at 256 automatically)
        // Y = screen RAM write position (0..39)
        ldx     SCROLLBUFPTR
        ldy     #0
COPYLEFT:
        lda     SCROLLBUF,x
        sta     SCROLLRAM,y
        lda     SCROLLBUF2,x
        sta     SCROLLRAM2,y
        inx                         // wraps at 256 automatically
        iny
        cpy     #40
        bne     COPYLEFT
        rts

        // -------------------------------------------------------
        // COARSERIGHT: decrement circular buffer pointer by 1,
        // write new character at (ptr-1) mod 256,
        // copy 40 chars from circular buffer to screen RAM.
        // -------------------------------------------------------
COARSERIGHT:
        // Decrement pointer — replaces 897 cycle shift loop
        dec     SCROLLBUFPTR        // 5 cycles

        // New character position = (SCROLLBUFPTR - 1) mod 256
        lda     SCROLLBUFPTR
        sec
        sbc     #1
        tay                         // Y = position for new character

        // Fetch previous character from scroll text
        ldx     SCROLLCNT
        dex
        bpl     GOTRIGHT
        ldx     #0
FINDEND:
        lda     SCROLLTEXT,x
        cmp     #$ff
        beq     FOUNDEND
        inx
        jmp     FINDEND
FOUNDEND:
        dex
GOTRIGHT:
        stx     SCROLLCNT
        lda     SCROLLTEXT,x
        // Store new character in both circular buffers
        sta     SCROLLBUF,y
        sta     SCROLLBUF2,y

        // Copy 40 chars from both circular buffers to screen RAM
        ldx     SCROLLBUFPTR
        ldy     #0
COPYRIGHT:
        lda     SCROLLBUF,x
        sta     SCROLLRAM,y
        lda     SCROLLBUF2,x
        sta     SCROLLRAM2,y
        inx
        iny
        cpy     #40
        bne     COPYRIGHT
        rts

        // -------------------------------------------------------
        // UPDATESPEED: advance speed table every 6 frames
        // -------------------------------------------------------
UPDATESPEED:
        inc     SPEEDDELAY
        lda     SPEEDDELAY
        cmp     #6
        bne     SPEEDDONE
        lda     #0
        sta     SPEEDDELAY
        ldx     SPEEDIDX
        lda     SPEEDTABLE,x
        sta     SCROLLSPEED
        inx
        cpx     #SPEEDTABLE_SIZE
        bne     SAVEIDX
        ldx     #0
SAVEIDX:
        stx     SPEEDIDX
SPEEDDONE:
        rts

SCROLLSPEED:
        .byte 1
SCROLLX:
        .byte 7
SCROLLCNT:
        .byte 0
SCROLLBUFPTR:
        .byte 0
SPEEDIDX:
        .byte 0
SPEEDDELAY:
        .byte 0

SCROLLTEXT:
        .byte 8,5,12,12,15,32,20,8,9,19,32,9,19,32,1,32,19,13,15,15,20,8,32
        .byte 19,3,18,15,12,12,5,18,32,15,14,32,20,8,5,32,3,54,52,32,32,32
        .byte $ff

SPEEDTABLE:
        // Ramp up left
        .byte 1,1,1,2,2,2,3,3,3,4,4,4,5,5,5
        // Hold at max left speed
        .fill 30, 5
        // Ramp down to zero
        .byte 4,4,4,3,3,3,2,2,2,1,1,1,0,0,0
        // Ramp into reverse
        .byte $ff,$ff,$ff,$fe,$fe,$fe,$fd,$fd,$fd,$fc,$fc,$fc,$fb,$fb,$fb
        // Hold at reverse speed
        .fill 10, $fb
        // Ramp back to zero
        .byte $fc,$fc,$fc,$fd,$fd,$fd,$fe,$fe,$fe,$ff,$ff,$ff,0,0,0
.label SPEEDTABLE_END = *
.label SPEEDTABLE_SIZE = SPEEDTABLE_END - SPEEDTABLE

.align 256
COLORTABLE:
        .byte $00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0a,$0b,$0c,$0d,$0e,$0f
        .byte $0e,$0d,$0c,$0b,$0a,$09,$08,$07,$06,$05,$04,$03,$02,$01
        .byte $00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0a,$0b,$0c,$0d,$0e,$0f
        .byte $0e,$0d,$0c,$0b,$0a,$09,$08,$07,$06,$05,$04,$03,$02,$01
        .byte $00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0a,$0b,$0c,$0d,$0e,$0f
        .byte $0e,$0d,$0c,$0b,$0a,$09,$08,$07,$06,$05,$04,$03,$02,$01
        .byte $00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0a,$0b,$0c,$0d,$0e,$0f
        .byte $0e,$0d,$0c,$0b,$0a,$09,$08,$07,$06,$05,$04,$03,$02,$01
        .byte $00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0a,$0b,$0c,$0d,$0e,$0f
        .byte $0e,$0d,$0c,$0b,$0a,$09,$08,$07,$06,$05,$04,$03,$02,$01
        .byte $00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0a,$0b,$0c,$0d,$0e,$0f
        .byte $0e,$0d,$0c,$0b,$0a,$09,$08,$07,$06,$05,$04,$03,$02,$01
        .byte $00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0a,$0b,$0c,$0d,$0e,$0f
        .byte $0e,$0d,$0c,$0b,$0a,$09,$08,$07,$06,$05,$04,$03,$02,$01
        .byte $00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0a,$0b,$0c,$0d,$0e,$0f
        .byte $0e,$0d,$0c,$0b,$0a,$09,$08,$07,$06,$05,$04,$03,$02,$01
        .byte $00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0a,$0b,$0c,$0d,$0e,$0f
        .byte $0e,$0d,$0c,$0b,$0a,$09,$08,$07,$06,$05,$04,$03,$02,$01
        .byte $00,$01,$02

// Circular buffers must be page aligned so pointer wraps correctly
.align 256
SCROLLBUF:
        .fill 256, $20          // 256-byte circular buffer line 1

.align 256
SCROLLBUF2:
        .fill 256, $20          // 256-byte circular buffer line 2

* = $1800
.import binary "bombo.sid", 126

* = $2800
.var charset = LoadBinary("charset.bin", BF_C64FILE)
.fill charset.getSize(), charset.get(i)