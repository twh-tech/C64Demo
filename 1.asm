*=$0801
        .byte   $0b,$08
        .byte   $0a,$00
        .byte   $9e
        .byte   $20
        .text   "2064"
        .byte   $00,$00,$00
        *=$0810

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

// Raster line where PHASE1 starts (IRQ trigger when PHASE1 active)
.label PHASE1_RASTER   = TABLESTART - 1

// Raster line where PHASE2 starts (IRQ trigger when PHASE1 skipped)
.label PHASE2_RASTER   = TABLESTART - 1 + DISPOFF_TOP

START:
		lda     #$35
        sta     $01             // RAM under BASIC+KERNAL, I/O still visible

		// Sprite test - can be removed later
		// Create a solid sprite at $3800
        // In VIC bank 0, sprite pointer value = $3800/64 = $e0
        lda     #$ff
        ldx     #0
MAKESOLID:
        sta     $3800,x
        inx
        cpx     #63             // 63 bytes (21 rows x 3 bytes)
        bne     MAKESOLID
        lda     #$00
        sta     $3840           // padding byte

        // Point sprite 0 and sprite 1 to $3800 (pointer = $e0)
        lda     #$e0
        sta     $07f8           // sprite 0 pointer
        sta     $07f9           // sprite 1 pointer

        // Sprite colors: light blue = $0e
        lda     #$0e
        sta     $d027           // sprite 0 color
        sta     $d028           // sprite 1 color

        // Sprite 0: top border, half in border half in display area
        // Display starts at raster 51, sprite is 21 pixels tall
        // so Y=40 puts it straddling the border/display boundary
        lda     #160
        sta     $d000           // X center
        lda     #40
        sta     $d001           // Y straddles top border/display

        // Sprite 1: bottom border, half in display half in border
        // Display ends at raster 250, bottom border starts at 251
        // Y=241 puts it straddling the display/bottom border boundary
        lda     #160
        sta     $d002           // X center
        lda     #241
        sta     $d003           // Y straddles display/bottom border

        // Enable sprites 0 and 1
        lda     #%00000011
        //sta     $d015
		// end of sprite test code
        
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
     //   sta     VICBGCOLOR

        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
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

        // -------------------------------------------------------
        // PHASE3: raster bars for main display area
        // -------------------------------------------------------
PHASE3_LOOP:
        lda     COLORTABLE,x
        sta     VICBORDER
        

        nop
        nop
        
        
        
        //sta     VICBGCOLOR
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
//        clc
//        bcc     *+2
        nop
        nop
        nop
        nop
        nop                             // 22 cycles = 44
        inx
        cpx     #TABLESIZE
        bne     PHASE3_LOOP

        // -------------------------------------------------------
        // OFFSCREEN_WORK: runs when Phase3 is active.
        // Sets up next IRQ, plays SID, runs scroll and speed update.
        // DOSCROLL runs before UPDATESPEED so that any direction-
        // change pointer correction takes effect on the next frame.
        // -------------------------------------------------------
OFFSCREEN_WORK:
        lda     #$00
        sta     VICBORDER
        sta     VICBGCOLOR
        
        // switch to 24-row mode - opens borders
        //lda     #$13
        //sta     VICICR

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

		// restore 25-row mode - re-arms trick
		lda     #$1b
        sta     VICICR

        rti

        // -------------------------------------------------------
        // OFFSCREEN_WORK_SKIP: runs when Phase3 is skipped.
        // More time available; same work as OFFSCREEN_WORK.
        // -------------------------------------------------------
OFFSCREEN_WORK_SKIP:
        lda     #$00
        sta     VICBORDER
        sta     VICBGCOLOR

        // switch to 24-row mode - opens borders
        //lda     #$13
        //sta     VICICR

        lda     #PHASE1_RASTER
        sta     VICRASTER

        jsr     $180c               // SID player
        jsr     DOSCROLL
        jsr     UPDATESPEED

		// restore 25-row mode - re-arms trick
		lda     #$1b
        sta     VICICR

        rti

        // -------------------------------------------------------
        // DOSCROLL: update fine scroll register; trigger coarse
        // scroll step when fine scroll wraps in either direction.
        //
        // SCROLLSPEED is signed: positive = scroll left,
        // negative (e.g. $ff = -1) = scroll right.
        // SCROLLX holds the current fine scroll value (0-7).
        // Subtracting a negative speed adds to SCROLLX (right).
        // Subtracting a positive speed decreases SCROLLX (left).
        // A coarse left step is needed when SCROLLX goes below 0.
        // A coarse right step is needed when SCROLLX reaches 8.
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
        // COARSELEFT: called when the fine scroll wraps left.
        // Advances the circular buffer pointer, feeds the next
        // column from SCROLLTEXT/SCROLLTEXT2 into the rightmost
        // buffer slot, and advances the left-edge pointer
        // SCROLLCNTL once the buffer is full (after 41 steps).
        //
        // Pointer layout:
        //   SCROLLCNT  = next text position to feed into right edge
        //   SCROLLCNTL = text position of current leftmost column
        //   SCROLLBUFPTR = circular buffer index of leftmost column
        //   Right edge slot = (SCROLLBUFPTR + 39) mod 256
        // -------------------------------------------------------
COARSELEFT:
        inc     SCROLLBUFPTR

        // Right edge slot = (SCROLLBUFPTR + 39) mod 256
        lda     SCROLLBUFPTR
        clc
        adc     #39
        tay

        // Feed next column into right edge slot for row 1
        ldx     SCROLLCNT
        lda     SCROLLTEXT,x
        cmp     #$ff
        bne     GOTLEFT1
        ldx     #0                  // wrap: read position 0
        lda     SCROLLTEXT,x
        ldx     #1                  // next call starts at position 1
        stx     SCROLLCNT
        jmp     STORELEFT1
GOTLEFT1:
        inx
        stx     SCROLLCNT
STORELEFT1:
        sta     SCROLLBUF,y

        // Feed next column into right edge slot for row 2
        ldx     SCROLLCNT2
        lda     SCROLLTEXT2,x
        cmp     #$ff
        bne     GOTLEFT2
        ldx     #0                  // wrap: read position 0
        lda     SCROLLTEXT2,x
        ldx     #1                  // next call starts at position 1
        stx     SCROLLCNT2
        jmp     STORELEFT2
GOTLEFT2:
        inx
        stx     SCROLLCNT2
STORELEFT2:
        sta     SCROLLBUF2,y

        // Advance left-edge pointer SCROLLCNTL once the buffer is
        // full. SCROLLCNTL starts at 0 and SCROLLCNT starts at 0;
        // after 41 coarse steps SCROLLCNT reaches 41 and SCROLLCNTL
        // begins advancing, keeping it exactly 40 steps behind.
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
        ldx     #0                  // wrap: next call reads position 0
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
        ldx     #0                  // wrap: next call reads position 0
        stx     SCROLLCNTL2
        jmp     SKIPCNTL
ADVANCELEFT3:
        inx
        stx     SCROLLCNTL2

SKIPCNTL:
        // Copy circular buffer to screen RAM (40 columns)
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
        // COARSERIGHT: called when the fine scroll wraps right.
        // Decrements the circular buffer pointer and feeds the
        // previous column from SCROLLTEXT/SCROLLTEXT2 into the
        // new leftmost buffer slot using SCROLLCNTL.
        //
        // SCROLLCNTL is decremented by one on each call, walking
        // backwards through the text one column at a time.
        // Wraps to the last byte of the text on underflow.
        // -------------------------------------------------------
COARSERIGHT:
        dec     SCROLLBUFPTR

        lda     SCROLLBUFPTR
        tay                         // Y = new leftmost slot

        // Feed previous column into leftmost slot for row 1
        ldx     SCROLLCNTL
        dex
        cpx     #$ff
        bne     GOTRIGHT1
        // Underflow: wrap to last valid text position
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

        // Feed previous column into leftmost slot for row 2
        ldx     SCROLLCNTL2
        dex
        cpx     #$ff
        bne     GOTRIGHT2
        // Underflow: wrap to last valid text position
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

        // Copy circular buffer to screen RAM (40 columns)
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
        // UPDATESPEED: advance the speed table every 6 frames.
        // Detects direction changes and resyncs scroll pointers.
        //
        // SCROLLSIGN tracks current direction:
        //   0 = scrolling left  (SCROLLSPEED positive or zero)
        //   1 = scrolling right (SCROLLSPEED negative)
        //
        // On direction change, either SCROLLCNTL (left->right) or
        // SCROLLCNT (right->left) has become stale and is resynced
        // from the pointer that was actively maintained.
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

        // Speed zero or positive: scrolling left
        lda     SCROLLSIGN
        beq     SPEEDDONE           // already going left, no change
        // Transition right->left: resync SCROLLCNT from SCROLLCNTL
        lda     #0
        sta     SCROLLSIGN
        jsr     ALIGNFORRIGHT
        jmp     SPEEDDONE

SPEED_IS_NEG:
        // Speed negative: scrolling right
        lda     SCROLLSIGN
        bne     SPEEDDONE           // already going right, no change
        // Transition left->right: resync SCROLLCNTL from SCROLLCNT
        lda     #1
        sta     SCROLLSIGN
        jsr     ALIGNFORLEFT

SPEEDDONE:
        rts

        // -------------------------------------------------------
        // ALIGNFORLEFT: called on left->right direction change.
        //
        // During left-scroll, SCROLLCNT is authoritative (actively
        // maintained by COARSELEFT). SCROLLCNTL has drifted.
        // Resync: SCROLLCNTL = SCROLLCNT - 40 (mod TEXTLENGTH).
        // COARSERIGHT uses dex before writing, so with SCROLLCNTL
        // set to SCROLLCNT-40 its first dex lands on the correct
        // column to feed into the new leftmost slot.
        // -------------------------------------------------------
ALIGNFORLEFT:
        lda     SCROLLCNT
        sec
        sbc     #40
        bcs     ALIGNFORLEFT_STORE
        clc
        adc     #<TEXTLENGTH        // wrap: add text length
ALIGNFORLEFT_STORE:
        sta     SCROLLCNTL
        sta     SCROLLCNTL2
        rts

        // -------------------------------------------------------
        // ALIGNFORRIGHT: called on right->left direction change.
        //
        // During right-scroll, SCROLLCNTL is authoritative
        // (actively maintained by COARSERIGHT). SCROLLCNT has
        // drifted. Resync: SCROLLCNT = SCROLLCNTL + 40
        // (mod TEXTLENGTH). COARSELEFT uses inx before writing,
        // so with SCROLLCNT set to SCROLLCNTL+40 its first inx
        // lands on the correct column to feed into the new
        // rightmost slot.
        // -------------------------------------------------------
ALIGNFORRIGHT:
        lda     SCROLLCNTL
        clc
        adc     #40
        tax
        cpx     #<TEXTLENGTH
        bcc     ALIGNFORRIGHT_STORE // result < TEXTLENGTH, no wrap needed
        txa
        sec
        sbc     #<TEXTLENGTH        // wrap: subtract text length
        tax
ALIGNFORRIGHT_STORE:
        stx     SCROLLCNT
        stx     SCROLLCNT2
        rts

DUMMY_NMI:
        rti

SCROLLSPEED:
        .byte 1
SCROLLX:
        .byte 7
SCROLLCNT:
        .byte 0                     // right-edge text pointer (left-scroll)
SCROLLCNT2:
        .byte 0                     // right-edge text pointer, row 2
SCROLLCNTL:
        .byte 0                     // left-edge text pointer (right-scroll)
SCROLLCNTL2:
        .byte 0                     // left-edge text pointer, row 2
SCROLLCNTL_RDY:
        .byte 0                     // 1 once buffer is full and SCROLLCNTL active
SCROLLBUFPTR:
        .byte 0                     // circular buffer index of leftmost column
SCROLLSIGN:
        .byte 0                     // 0=left, 1=right
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
.label TEXTLENGTH = * - SCROLLTEXT - 1  // text length excluding $ff sentinel

.align 256
SCROLLTEXT2:
        .import binary "scroll_bot.bin"
        .byte $ff

.align 256
SCROLLBND:
        .import binary "scroll_bnd.bin"
        .byte $ff

SPEEDTABLE:
        // Ramp up left
        .byte 1,1,1,2,2,2,3,3,3,4,4,4,5,5,5
        // Hold at max left speed
        .fill 30, 5
        // Ramp down to zero
        .byte 4,4,4,3,3,3,2,2,2,1,1,1,0,0,0
        // Ramp into reverse (right)
        .byte $ff,$ff,$ff,$fe,$fe,$fe,$fd,$fd,$fd,$fc,$fc,$fc,$fb,$fb,$fb
        // Hold at max right speed
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