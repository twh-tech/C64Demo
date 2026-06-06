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
        lda     #$00
        sta     garbagebyte

        sei
        //jsr     SETUPSPRITE

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
        cpy     #1                      // 2 cycles - check if last iteration
        beq     PHASE2_LAST             // 3 cycles taken / 2 cycles not taken
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
        nop                             // 21 NOPs = 42 cycles
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
        beq     PHASE2_N7_DONE
        jmp     PHASE2_GROUP
PHASE2_N7_DONE:
        nop
        jmp     PHASE3_JMP

PHASE2_LAST:
        lda     #$13
        sta     VICICR
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
        nop                             // adjust NOPs to fill penultimate line
        inx                             // crosses into last raster line
        lda     COLORTABLE,x
        sta     VICBORDER
        sta     VICBGCOLOR
        nop
        nop
        nop
        nop
        nop
//        lda     #$13
//        sta     VICICR
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
        nop                             // adjust NOPs to fill last line
        inx
PHASE3_JMP:
        jmp     PHASE3_LOOP

        // -------------------------------------------------------
        // PHASE3: raster bars for main display area
        // -------------------------------------------------------
PHASE3_LOOP:
        lda     COLORTABLE,x
        sta     VICBORDER
        sta		VICBGCOLOR
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

        //jsr     $180c               // SID player
        jsr		DORASTERBARS
        jsr     DOSCROLL
        jsr     UPDATESPEED
        //inc     $d001

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

SETUPSPRITE:
        // Create a solid sprite at $3800
        // In VIC bank 0, sprite pointer value = $3800/64 = $e0
        lda     #$ff
        ldx     #0
MAKESOLID:
        sta     $3800,x
        inx
        cpx     #63
        bne     MAKESOLID
        lda     #$00
        sta     $3840

        // Point sprite 0 to $3800
        lda     #$e0
        sta     $07f8

        // Sprite color: light blue = $0e
        lda     #$0e
        sta     $d027

        // X position: horizontal middle = 160
        lda     #160
        sta     $d000

        // Y position: straddling display/bottom border
        // Display ends around raster 250, sprite is 21 pixels tall
        // Y=241 puts it half in display half in border
        lda     #251
        //lda		#255
        sta     $d001

        // Enable sprite 0
        lda     #%00000001
        sta     $d015

        rts


// -------------------------------------------------------
// Labels used by bar system
// -------------------------------------------------------

.label BAR_COUNT        = 3
.label BAR_HEIGHT       = 7        // changed from 7 to 5, no black edges
.label RASTERBAR_TOP    = 50
.label RASTERBAR_BOT    = 285
.label VISIBLE_RANGE    = RASTERBAR_BOT - RASTERBAR_TOP - BAR_HEIGHT
.label BARTABLE_OFFSET  = RASTERBAR_TOP - TABLESTART   // = 35
.label BAR_PHASE_STEP   = 10

// -------------------------------------------------------
// Zero page locations used by bar system
// -------------------------------------------------------
.label ZP_BARPTR    = $fb       // 2 bytes: pointer into COLORTABLE for current bar
.label ZP_BARCOL    = $fd       // 1 byte: scratch
.label ZP_BARX      = $fe       // 1 byte: bar loop counter

// -------------------------------------------------------
// BAR DATA TABLES
// -------------------------------------------------------

// Current Y position of each bar — index into COLORTABLE
// (relative to start of COLORTABLE, so 0 = raster line TABLESTART)
// Valid range: BARTABLE_OFFSET .. BARTABLE_OFFSET + VISIBLE_RANGE
BAR_YPOS:
        .byte BARTABLE_OFFSET + 20   // bar 0 initial pos
        .byte BARTABLE_OFFSET + 20   // bar 1
        .byte BARTABLE_OFFSET + 20   // bar 2
        .byte BARTABLE_OFFSET + 20   // bar 3
        .byte BARTABLE_OFFSET + 20   // bar 4

// Sine table phase for each bar
BAR_PHASE:
        .byte 0                      // bar 0 — leading bar
        .byte 256 - BAR_PHASE_STEP*1 // bar 1 trails by 1 step
        .byte 256 - BAR_PHASE_STEP*2 // bar 2 trails by 2 steps
        .byte 256 - BAR_PHASE_STEP*3 // bar 3
        .byte 256 - BAR_PHASE_STEP*4 // bar 4

// Which color pattern each bar uses (index into BAR_COLOR_LO/HI)
BAR_TYPE:
        .byte 0    // red
        .byte 1    // blue
        .byte 2    // gray
//        .byte 3    // green
//        .byte 4    // yellow

// -------------------------------------------------------
// BAR COLOR PATTERNS
// 5 pattern types, each BAR_HEIGHT (5) bytes, top to bottom
// -------------------------------------------------------
BAR_COLORS_0:  .byte $02,$02,$0a,$0f,$0a,$02,$02   // red:    red, red, light red, white, light red, red, red
BAR_COLORS_1:  .byte $06,$06,$04,$0f,$04,$06,$06   // blue:   blue, blue, purple, white, purple, blue, blue
BAR_COLORS_2:  .byte $0b,$0b,$0c,$0f,$0c,$0b,$0b   // gray:   dark gray, dark gray, medium gray, white, medium gray, dark gray, dark gray
BAR_COLORS_3:  .byte $05,$05,$0d,$0f,$0d,$05,$05   // green:  green, green, light green, white, light green, green, green
BAR_COLORS_4:  .byte $09,$09,$07,$0f,$07,$09,$09   // yellow: brown, brown, yellow, white, yellow, brown, brown

// Low/high byte tables for indirect indexed access to color patterns
BAR_COLOR_LO:
        .byte <BAR_COLORS_0, <BAR_COLORS_1, <BAR_COLORS_2, <BAR_COLORS_3, <BAR_COLORS_4

BAR_COLOR_HI:
        .byte >BAR_COLORS_0, >BAR_COLORS_1, >BAR_COLORS_2, >BAR_COLORS_3, >BAR_COLORS_4

// -------------------------------------------------------
// SINE TABLE
// 256 entries, range scaled to VISIBLE_RANGE
// Values are COLORTABLE offsets: BARTABLE_OFFSET .. BARTABLE_OFFSET+VISIBLE_RANGE
// Generate with: BARTABLE_OFFSET + (sin(i/256*2pi)+1)/2 * VISIBLE_RANGE
//
// VISIBLE_RANGE = 285 - 50 - 7 = 228
// BARTABLE_OFFSET = 35
// So values range from 35 to 35+228 = 263
// -------------------------------------------------------
SINETABLE:
        // 256 bytes — generated values below
        // sin scaled: offset + (sin+1)/2 * range
        // These are approximated — regenerate with a script for accuracy
		.byte 145,147,150,153,155,158,161,163,166,169,171,174,176,179,182,184
        .byte 187,189,192,194,196,199,201,203,206,208,210,212,214,216,218,220
        .byte 222,224,226,228,230,231,233,234,236,237,239,240,242,243,244,245
        .byte 246,247,248,249,250,251,251,252,252,253,253,254,254,254,254,254
        .byte 255,254,254,254,254,254,253,253,252,252,251,251,250,249,248,247
        .byte 246,245,244,243,242,240,239,237,236,234,233,231,230,228,226,224
        .byte 222,220,218,216,214,212,210,208,206,203,201,199,196,194,192,189
        .byte 187,184,182,179,176,174,171,169,166,163,161,158,155,153,150,147
        .byte 145,142,139,136,134,131,128,126,123,120,118,115,113,110,107,105
        .byte 102,100,97,95,93,90,88,86,83,81,79,77,75,73,71,69
        .byte 67,65,63,61,59,58,56,55,53,52,50,49,47,46,45,44
        .byte 43,42,41,40,39,38,38,37,37,36,36,35,35,35,35,35
        .byte 35,35,35,35,35,35,36,36,37,37,38,38,39,40,41,42
        .byte 43,44,45,46,47,49,50,52,53,55,56,58,59,61,63,65
        .byte 67,69,71,73,75,77,79,81,83,86,88,90,93,95,97,100
        .byte 102,105,107,110,113,115,118,120,123,126,128,131,134,136,139,142



// Sine index for leading bar (bar 0)
SINE_IDX:
        .byte 0

// sine table steps to advance per frame (higher = faster motion)
SINE_SPEED:
        .byte 1

// -------------------------------------------------------
// DORASTERBARS
// Call from offscreen work each frame.
// -------------------------------------------------------
DORASTERBARS:

        // ---- Step 1: Erase all bars (write black to old positions) ----
        lda     #BAR_COUNT-1
        sta     ZP_BARX

ERASE_BAR:
        ldx     ZP_BARX
        lda     BAR_YPOS,x          // COLORTABLE offset for top of bar
        tay                         // Y = index into COLORTABLE

        lda     #$00
        sta     COLORTABLE,y
        iny
        sta     COLORTABLE,y
        iny
        sta     COLORTABLE,y
        iny
        sta     COLORTABLE,y
        iny
        sta     COLORTABLE,y
        iny
        sta     COLORTABLE,y
        iny
        sta     COLORTABLE,y        // 7 stores — unrolled, no inner loop

        dec     ZP_BARX
        bpl     ERASE_BAR

        // ---- Step 2: Advance sine index ----
        lda     SINE_IDX
        clc
        adc     SINE_SPEED
        sta     SINE_IDX            // wraps naturally mod 256

        // ---- Step 3: Update bar positions and paint ----
        lda     #BAR_COUNT-1
        sta     ZP_BARX

UPDATE_BAR:
        ldx     ZP_BARX

        // Compute sine index for this bar: SINE_IDX + BAR_PHASE[x]
        lda     SINE_IDX
        clc
        adc     BAR_PHASE,x         // wraps mod 256 — that's fine, table is 256 entries
        tay
        lda     SINETABLE,y         // new Y position (COLORTABLE offset)
        sta     BAR_YPOS,x          // save for next frame's erase

        // Set up ZP_BARPTR = COLORTABLE + BAR_YPOS[x]
        // Since COLORTABLE is page-aligned (.align 256), we just need:
        //   ZP_BARPTR lo = BAR_YPOS[x]
        //   ZP_BARPTR hi = >COLORTABLE
        sta     ZP_BARPTR
        lda     #>COLORTABLE
        sta     ZP_BARPTR+1

        // Set up source pointer to color pattern for this bar type
        lda     BAR_TYPE,x
        tay
        lda     BAR_COLOR_LO,y
        sta     ZP_BARCOL           // reuse as src ptr lo — need 2 ZP bytes
        // Actually need a second ZP pointer for source.
        // Let's use ZP_SRCPTR = $f9/$fa
        lda     BAR_COLOR_LO,y
        sta     $f9
        lda     BAR_COLOR_HI,y
        sta     $fa

        // Paint 7 bytes: (ZP_BARPTR)[0..6] = (ZP_SRCPTR)[0..6]
        ldy     #0
        lda     ($f9),y
        sta     (ZP_BARPTR),y
        iny
        lda     ($f9),y
        sta     (ZP_BARPTR),y
        iny
        lda     ($f9),y
        sta     (ZP_BARPTR),y
        iny
        lda     ($f9),y
        sta     (ZP_BARPTR),y
        iny
        lda     ($f9),y
        sta     (ZP_BARPTR),y
        iny
        lda     ($f9),y
        sta     (ZP_BARPTR),y
        iny
        lda     ($f9),y
        sta     (ZP_BARPTR),y       // 7 unrolled indirect stores

        dec     ZP_BARX
        bpl     UPDATE_BAR

        rts