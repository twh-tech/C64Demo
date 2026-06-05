*=$0801
        .byte   $0b,$08
        .byte   $0a,$00
        .byte   $9e
        .byte   $20
        .text   "2064"
        .byte   $00,$00,$00
        *=$0810

.label IRQVEC          = $0314
.label VICICR          = $d011
.label VICRASTER       = $d012
.label VICXSCROLL      = $d016
.label VICMEMCTRL      = $d018
.label VICIRQFLAG      = $d019
.label VICBORDER       = $d020
.label VICBGCOLOR      = $d021
.label VICIRQENABLE    = $d01a
.label TABLESTART      = 15
.label TABLEND         = 288
.label TABLESIZE       = TABLEND - TABLESTART
.label DISPLAYON       = %00011011
.label DISPOFF_TOP     = 36
.label DISPON_LEN      = 200
.label SCROLLROW       = 12
.label SCROLLRAM       = $0400 + SCROLLROW * 40
.label SCROLLRAM2      = $0400 + (SCROLLROW+1) * 40
.label garbagebyte     = $3fff

// Raster line where PHASE1 starts (IRQ trigger when PHASE1 active)
.label PHASE1_RASTER   = TABLESTART - 1

// Raster line where PHASE2 starts (IRQ trigger when PHASE1 skipped)
.label PHASE2_RASTER   = TABLESTART - 1 + DISPOFF_TOP

START:
        lda     #$35
        sta     $01             // RAM under BASIC+KERNAL, I/O still visible

        // set garbage byte to visible value for open border testing
        lda     #$7f
        sta     garbagebyte

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

        lda     #$7f
        sta     $dd0d       // disable all CIA2 NMI sources
        lda     $dd0d       // acknowledge any pending NMI

        lda     #<IRQ1
        sta     $fffe
        lda     #>IRQ1
        sta     $ffff

        lda     #<DUMMY_NMI
        sta     $fffa
        lda     #>DUMMY_NMI
        sta     $fffb

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

        // Fill scroll screen rows with spaces
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
        sta     SCROLLCNT2
        sta     SCROLLCNTL
        sta     SCROLLCNTL2
        sta     SCROLLCNTL_RDY
        sta     SCROLLBUFPTR
        sta     SCROLLSIGN          // start scrolling left
        lda     #7
        sta     SCROLLX

        // Clear screen
        lda     #$20
        ldx     #$00
CLEARSCREEN:
        sta     $0400,x
        sta     $0500,x
        sta     $0600,x
        sta     $06e8,x
        inx
        bne     CLEARSCREEN

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

        lda     #$0c            // medium gray
        ldx     #39
COLORTOPSCROLLLINE:
        sta     $d9e0,x
        dex
        bpl     COLORTOPSCROLLLINE

        lda     #$0b            // dark gray
        ldx     #39
COLORBOTTOMSCROLLLINE:
        sta     $da08,x
        dex
        bpl     COLORBOTTOMSCROLLLINE

        // Point VIC to charset at $2800
        lda     #%00011010
        sta     VICMEMCTRL

        cli
MAINLOOP:
        jmp     MAINLOOP

DUMMY_NMI:
        rti

IRQ1:
        lda     VICIRQFLAG
        and     #$01
        bne     IS_RASTER
        rti

IS_RASTER:
        lda     #$01
        sta     VICIRQFLAG
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

IRQHANDLER:
        jmp     PHASE1_ACTIVE

        // -------------------------------------------------------
        // PHASE1 active: raster bars for top border area
        // -------------------------------------------------------
PHASE1_ACTIVE:
        ldx     #$00

PHASE1_LOOP:
        lda     COLORTABLE,x
        sta     VICBORDER
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
        beq     PHASE2_LAST             // last iteration goes to unrolled block
        jmp     PHASE2_GROUP

        // -------------------------------------------------------
        // PHASE2_LAST: unrolled last raster line of PHASE2.
        // Writes #$13 to VICICR to open the bottom border.
        // -------------------------------------------------------
PHASE2_LAST:
        lda     COLORTABLE,x            // 4 cycles
        sta     VICBORDER               // 4 cycles
        sta     VICBGCOLOR              // 4 cycles
        lda     #$13                    // 2 cycles - open border
        sta     VICICR                  // 4 cycles
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
        nop                             // 13 NOPs = 26 cycles
        inx                             // 2 cycles
        nop                             // 2 cycles padding
PHASE3_JMP:
        jmp     PHASE3_LOOP

        // -------------------------------------------------------
        // PHASE3: raster bars for main display area
        // -------------------------------------------------------
PHASE3_LOOP:
        lda     COLORTABLE,x
        sta     VICBORDER
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


//		clc
//		bcc *+2
		
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
        // OFFSCREEN_WORK: runs when Phase3 is active.
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

        jsr     $180c               // SID player
        jsr     DOSCROLL
        jsr     UPDATESPEED

        // restore 25-row mode - re-arms open border trick for next frame
        lda     #$1b
        sta     VICICR

        rti

        // -------------------------------------------------------
        // OFFSCREEN_WORK_SKIP: runs when Phase3 is skipped.
        // -------------------------------------------------------
OFFSCREEN_WORK_SKIP:
        lda     #$00
        sta     VICBORDER
        sta     VICBGCOLOR

        lda     #PHASE1_RASTER
        sta     VICRASTER

        jsr     $180c               // SID player
        jsr     DOSCROLL
        jsr     UPDATESPEED

        // restore 25-row mode - re-arms open border trick for next frame
        lda     #$1b
        sta     VICICR

        rti

        // -------------------------------------------------------
        // DOSCROLL
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
        // COARSELEFT
        // -------------------------------------------------------
COARSELEFT:
        inc     SCROLLBUFPTR

        lda     SCROLLBUFPTR
        clc
        adc     #39
        tay

        ldx     SCROLLCNT
        lda     SCROLLTEXT,x
        cmp     #$ff
        bne     GOTLEFT1
        ldx     #0
        lda     SCROLLTEXT,x
        ldx     #1
        stx     SCROLLCNT
        jmp     STORELEFT1
GOTLEFT1:
        inx
        stx     SCROLLCNT
STORELEFT1:
        sta     SCROLLBUF,y

        ldx     SCROLLCNT2
        lda     SCROLLTEXT2,x
        cmp     #$ff
        bne     GOTLEFT2
        ldx     #0
        lda     SCROLLTEXT2,x
        ldx     #1
        stx     SCROLLCNT2
        jmp     STORELEFT2
GOTLEFT2:
        inx
        stx     SCROLLCNT2
STORELEFT2:
        sta     SCROLLBUF2,y

        lda     SCROLLCNTL_RDY
        bne     ADVANCELEFT

        lda     SCROLLCNT
        cmp     #41
        bcc     SKIPCNTL
        lda     #1
        sta     SCROLLCNTL_RDY

ADVANCELEFT:
        ldx     SCROLLCNTL
        lda     SCROLLTEXT,x
        cmp     #$ff
        bne     ADVANCELEFT1
        ldx     #0
        stx     SCROLLCNTL
        jmp     ADVANCELEFT2
ADVANCELEFT1:
        inx
        stx     SCROLLCNTL
ADVANCELEFT2:
        ldx     SCROLLCNTL2
        lda     SCROLLTEXT2,x
        cmp     #$ff
        bne     ADVANCELEFT3
        ldx     #0
        stx     SCROLLCNTL2
        jmp     SKIPCNTL
ADVANCELEFT3:
        inx
        stx     SCROLLCNTL2

SKIPCNTL:
        ldx     SCROLLBUFPTR
        ldy     #0
COPYLEFT:
        lda     SCROLLBUF,x
        sta     SCROLLRAM,y
        lda     SCROLLBUF2,x
        sta     SCROLLRAM2,y
        inx
        iny
        cpy     #40
        bne     COPYLEFT
        rts

        // -------------------------------------------------------
        // COARSERIGHT
        // -------------------------------------------------------
COARSERIGHT:
        dec     SCROLLBUFPTR

        lda     SCROLLBUFPTR
        tay

        ldx     SCROLLCNTL
        dex
        cpx     #$ff
        bne     GOTRIGHT1
        ldx     #0
FINDEND1:
        lda     SCROLLTEXT,x
        cmp     #$ff
        beq     FOUNDEND1
        inx
        bne     FINDEND1
FOUNDEND1:
        dex
        cpx     #$ff
        bne     GOTRIGHT1
GOTRIGHT1:
        stx     SCROLLCNTL
        lda     SCROLLTEXT,x
        sta     SCROLLBUF,y

        ldx     SCROLLCNTL2
        dex
        cpx     #$ff
        bne     GOTRIGHT2
        ldx     #0
FINDEND2:
        lda     SCROLLTEXT2,x
        cmp     #$ff
        beq     FOUNDEND2
        inx
        bne     FINDEND2
FOUNDEND2:
        dex
        cpx     #$ff
        bne     GOTRIGHT2
GOTRIGHT2:
        stx     SCROLLCNTL2
        lda     SCROLLTEXT2,x
        sta     SCROLLBUF2,y

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
        // UPDATESPEED
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

        lda     SCROLLSPEED
        bmi     SPEED_IS_NEG

        lda     SCROLLSIGN
        beq     SPEEDDONE
        lda     #0
        sta     SCROLLSIGN
        jsr     ALIGNFORRIGHT
        jmp     SPEEDDONE

SPEED_IS_NEG:
        lda     SCROLLSIGN
        bne     SPEEDDONE
        lda     #1
        sta     SCROLLSIGN
        jsr     ALIGNFORLEFT

SPEEDDONE:
        rts

        // -------------------------------------------------------
        // ALIGNFORLEFT
        // -------------------------------------------------------
ALIGNFORLEFT:
        lda     SCROLLCNT
        sec
        sbc     #40
        bcs     ALIGNFORLEFT_STORE
        clc
        adc     #<TEXTLENGTH
ALIGNFORLEFT_STORE:
        sta     SCROLLCNTL
        sta     SCROLLCNTL2
        rts

        // -------------------------------------------------------
        // ALIGNFORRIGHT
        // -------------------------------------------------------
ALIGNFORRIGHT:
        lda     SCROLLCNTL
        clc
        adc     #40
        tax
        cpx     #<TEXTLENGTH
        bcc     ALIGNFORRIGHT_STORE
        txa
        sec
        sbc     #<TEXTLENGTH
        tax
ALIGNFORRIGHT_STORE:
        stx     SCROLLCNT
        stx     SCROLLCNT2
        rts

        // -------------------------------------------------------
        // Variables
        // -------------------------------------------------------
SCROLLSPEED:
        .byte 1
SCROLLX:
        .byte 7
SCROLLCNT:
        .byte 0
SCROLLCNT2:
        .byte 0
SCROLLCNTL:
        .byte 0
SCROLLCNTL2:
        .byte 0
SCROLLCNTL_RDY:
        .byte 0
SCROLLBUFPTR:
        .byte 0
SCROLLSIGN:
        .byte 0
SPEEDIDX:
        .byte 0
SPEEDDELAY:
        .byte 0
DBG_CNTL:
        .byte 0
DBG_BUFPTR:
        .byte 0
DBG_CNT:
        .byte 0

.align 256
SCROLLTEXT:
        .import binary "scroll_top.bin"
        .byte $ff
.label TEXTLENGTH = * - SCROLLTEXT - 1

.align 256
SCROLLTEXT2:
        .import binary "scroll_bot.bin"
        .byte $ff

.align 256
SCROLLBND:
        .import binary "scroll_bnd.bin"
        .byte $ff

SPEEDTABLE:
        .byte 1,1,1,2,2,2,3,3,3,4,4,4,5,5,5
        .fill 30, 5
        .byte 4,4,4,3,3,3,2,2,2,1,1,1,0,0,0
        .byte $ff,$ff,$ff,$fe,$fe,$fe,$fd,$fd,$fd,$fc,$fc,$fc,$fb,$fb,$fb
        .fill 10, $fb
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

* = $3000
SCROLLBUF:
        .fill 256, $20

* = $3100
SCROLLBUF2:
        .fill 256, $20

* = $1800
.import binary "bombo.sid", 126

* = $2800
.var charset = LoadBinary("ace2char.bin", BF_C64FILE)
.fill charset.getSize(), charset.get(i)

.print "SCROLLTEXT = $"+toHexString(SCROLLTEXT)
.print "TEXTLENGTH = "+TEXTLENGTH
.print "COARSERIGHT = $"+toHexString(COARSERIGHT)
.print "SCROLLCNT = $"+toHexString(SCROLLCNT)
.print "SCROLLCNTL = $"+toHexString(SCROLLCNTL)
.print "SCROLLBUF = $"+toHexString(SCROLLBUF)
.print "SCROLLSPEED = $"+toHexString(SCROLLSPEED)
.print "SCROLLX = $"+toHexString(SCROLLX)
.print "SCROLLCNTL_RDY = $"+toHexString(SCROLLCNTL_RDY)
.print "ADVANCELEFT = $"+toHexString(ADVANCELEFT)
.print "COARSELEFT = $"+toHexString(COARSELEFT)
.print "SCROLLBND = $"+toHexString(SCROLLBND)
.print "SCROLLSIGN = $"+toHexString(SCROLLSIGN)
.print "DBG_CNTL = $"+toHexString(DBG_CNTL)
.print "DBG_CNT = $"+toHexString(DBG_CNT)