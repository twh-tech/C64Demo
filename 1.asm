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
.label VICXSCROLL  = $d016
.label SCROLLROW   = 12        // middle of screen (0-24)
.label SCROLLRAM   = $0400 + SCROLLROW * 40

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

        // Disable CIA1 timer IRQ entirely — prevents it from
        // occasionally delaying our raster IRQ and causing flicker.
        lda     #$7f
        sta     $dc0d
        lda     $dc0d       // read back to acknowledge any pending interrupt

        // Hook $0314 — KERNAL and BASIC stay mapped
        lda     #<IRQ1
        sta     IRQVEC
        lda     #>IRQ1
        sta     IRQVEC+1

        // Enable VIC raster IRQ
        lda     #$01
        sta     VICIRQENABLE

        // -------------------------------------------------------
        // Hardcoded initial state: PHASE1 active, PHASE3 skipped.
        //
        // To switch to PHASE1 skipped, PHASE3 active instead,
        // change the three pairs of lda/sta below as follows:
        //   PHASE1_RASTER  -> PHASE2_RASTER
        //   PHASE1_ACTIVE  -> PHASE2_ENTRY_SKIP
        //   OFFSCREEN_WORK_SKIP -> PHASE3_LOOP
        //
        // In the final version this will be set dynamically by
        // the raster bar movement code in OFFSCREEN_WORK.
        // -------------------------------------------------------

        // Set raster trigger line
        lda     #PHASE2_RASTER
        sta     VICRASTER

        // Set IRQ handler entry point
        lda     #<PHASE2_ENTRY_SKIP
        sta     IRQHANDLER+1
        lda     #>PHASE2_ENTRY_SKIP
        sta     IRQHANDLER+2

        // Set PHASE3 jump target — Phase3 active
        lda     #<PHASE3_LOOP
        sta     PHASE3_JMP+1
        lda     #>PHASE3_LOOP
        sta     PHASE3_JMP+2


// Clear scroll buffer
        lda     #$20           // space in screen code = 0, but we store petscii
        ldx     #40
CLEARBUF:
        sta     SCROLLBUF,x
        dex
        bpl     CLEARBUF

        // Copy empty buffer to screen row
        ldx     #39
COPYINIT:
        lda     #$00           // screen code for space
        sta     SCROLLRAM,x
        dex
        bpl     COPYINIT

        // Set fine scroll to 7, enable 38 column mode (bit 3 = 0)
        // 38 col mode hides leftmost and rightmost columns behind border
        // so characters scroll smoothly off left edge instead of jumping
        lda     VICXSCROLL
        and     #%11110000     // clear bits 0-3 (fine scroll + 38col bit)
        ora     #7             // set fine scroll to 7, bit 3 stays 0 = 38 col mode
        sta     VICXSCROLL

        // Init scroll position
        lda     #0
        sta     SCROLLCNT
        lda		#7
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
        jmp MAINLOOP   // infinite loop, CPU spins here between IRQs
//        rts

IRQ1:
        lda     VICIRQFLAG
        and     #$01
        bne     IS_RASTER
        rti                 // not a raster IRQ — just return, don't call KERNAL

IS_RASTER:
        lda     #$01
        sta     VICIRQFLAG

        // Self-modifying jump — target is either PHASE1_ACTIVE
        // or PHASE2_ENTRY_SKIP depending on which phase is active
IRQHANDLER:
        jmp     PHASE1_ACTIVE

        // -------------------------------------------------------
        // PHASE1 active: top border raster lines
        // Fires when raster IRQ triggers at PHASE1_RASTER (line 14)
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

        // Fall through to PHASE2_ENTRY

        // -------------------------------------------------------
        // PHASE2_ENTRY_SKIP: entry point when PHASE1 is skipped.
        // Raster IRQ fires at PHASE2_RASTER, IRQHANDLER jumps here.
        // Preloads X with DISPOFF_TOP as if PHASE1 had run.
        // Then falls through to PHASE2_ENTRY.
        // -------------------------------------------------------
PHASE2_ENTRY_SKIP:
        ldx     #DISPOFF_TOP            // 2 — preload X for PHASE2

        // -------------------------------------------------------
        // PHASE2: character area, always runs, never skipped
        // X = DISPOFF_TOP carried from PHASE1 or preloaded above
        // -------------------------------------------------------
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
        nop                             // 2
PHASE3_JMP:
        jmp     PHASE3_LOOP             // 3 — target modified in OFFSCREEN_WORK

        // -------------------------------------------------------
        // PHASE3 active: bottom border raster lines
        // X carries over from PHASE2
        // Followed by OFFSCREEN_WORK with PHASE4 time only
        // -------------------------------------------------------
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

        // Fall through to OFFSCREEN_WORK

        // -------------------------------------------------------
        // OFFSCREEN_WORK: runs after PHASE3 when PHASE3 is active.
        // Has PHASE4 time only.
        // -------------------------------------------------------
OFFSCREEN_WORK:
        lda     #$00
        sta     VICBORDER
        sta     VICBGCOLOR

        // Re-arm raster IRQ for next frame — Phase1 skipped means
        // IRQ fires at PHASE2_RASTER pointing to PHASE2_ENTRY_SKIP
        lda     #PHASE2_RASTER
        sta     VICRASTER
        lda     #<PHASE2_ENTRY_SKIP
        sta     IRQHANDLER+1
        lda     #>PHASE2_ENTRY_SKIP
        sta     IRQHANDLER+2

        // Set PHASE3 jump to PHASE3_LOOP (Phase3 active)
        lda     #<PHASE3_LOOP
        sta     PHASE3_JMP+1
        lda     #>PHASE3_LOOP
        sta     PHASE3_JMP+2

        // Call SID player — has Phase4 + Phase1 time combined
        jsr     $180c
		jsr DOSCROLL
		
        // -------------------------------------------------------
        // PHASE FLIP LOGIC — currently hardcoded, no flipping.
        // In the final version, raster bar movement code will
        // trigger a flip here when the leading bar enters
        // PHASE1 or PHASE3 area.
        //
        // To flip to PHASE1 active, PHASE3 skipped:
        //   lda #PHASE1_RASTER
        //   sta VICRASTER
        //   lda #<PHASE1_ACTIVE
        //   sta IRQHANDLER+1
        //   lda #>PHASE1_ACTIVE
        //   sta IRQHANDLER+2
        //   lda #<OFFSCREEN_WORK_SKIP
        //   sta PHASE3_JMP+1
        //   lda #>OFFSCREEN_WORK_SKIP
        //   sta PHASE3_JMP+2
        //
        // To flip to PHASE1 skipped, PHASE3 active:
        //   lda #PHASE2_RASTER
        //   sta VICRASTER
        //   lda #<PHASE2_ENTRY_SKIP
        //   sta IRQHANDLER+1
        //   lda #>PHASE2_ENTRY_SKIP
        //   sta IRQHANDLER+2
        //   lda #<PHASE3_LOOP
        //   sta PHASE3_JMP+1
        //   lda #>PHASE3_LOOP
        //   sta PHASE3_JMP+2
        // -------------------------------------------------------

        // Restore registers that KERNAL saved on entry, then RTI
        pla
        tay
        pla
        tax
        pla
        rti

        // -------------------------------------------------------
        // OFFSCREEN_WORK_SKIP: jumped to from PHASE2_DONE when
        // PHASE3 is skipped. Has PHASE3 + PHASE4 time available.
        // Raster cannon is just entering bottom border area.
        // We set border black immediately and do off-screen work.
        // -------------------------------------------------------
OFFSCREEN_WORK_SKIP:
        lda     #$00
        sta     VICBORDER
        sta     VICBGCOLOR

        // Re-arm raster IRQ for next frame — PHASE3 skipped means
        // next frame also starts at PHASE1_RASTER
        lda     #PHASE1_RASTER
        sta     VICRASTER

        // Call SID player once per frame — commented out for now
       // jsr     $180c
        
        jsr DOSCROLL
        
        lda     #$02
        sta     VICBORDER
        sta     VICBGCOLOR

		//jmp $EA7E
		//jmp $EA31

        // Restore registers that KERNAL saved on entry, then RTI

        pla
        tay
        pla
        tax
        pla
        rti


DOSCROLL:
        // Subtract signed speed from fine scroll position each frame.
        // SCROLLX counts 7..0, written directly to $D016 bits 0-2.
        // Positive speed = scroll left, negative speed = scroll right.
        lda     SCROLLX
        sec
        sbc     SCROLLSPEED         // subtract speed from current position
        bmi     NEEDCOARSELEFT      // result < 0: need coarse scroll left
        cmp     #8
        bcs     NEEDCOARSERIGHT     // result > 7: need coarse scroll right
        sta     SCROLLX             // result 0-7: just save and write
        jmp     WRITESCROLL

NEEDCOARSELEFT:
        // Result went below 0 — add 8 to wrap and shift buffer left
        clc
        adc     #8                  // bring back into 0-7 range
        sta     SCROLLX
        jsr     COARSELEFT
        jmp     WRITESCROLL

NEEDCOARSERIGHT:
        // Result went above 7 — subtract 8 to wrap and shift buffer right
        sec
        sbc     #8                  // bring back into 0-7 range
        sta     SCROLLX
        jsr     COARSERIGHT
        jmp     WRITESCROLL

WRITESCROLL:
        lda     VICXSCROLL
        and     #%11110000          // clear bits 0-3, preserve bits 4-7
        ora     SCROLLX             // OR in fine scroll value (0-7)
        sta     VICXSCROLL          // write to VIC
        rts

// -------------------------------------------------------
// COARSELEFT: shift buffer left, fetch next char into pos 39
// -------------------------------------------------------
COARSELEFT:
        ldx     #0
SHIFTLEFT:
        lda     SCROLLBUF+1,x
        sta     SCROLLBUF,x
        inx
        cpx     #39
        bne     SHIFTLEFT

        // Fetch next character
        ldx     SCROLLCNT
        lda     SCROLLTEXT,x
        cmp     #$ff                // end of text?
        bne     GOTLEFT
        ldx     #0                  // wrap to start
        stx     SCROLLCNT
        lda     SCROLLTEXT,x
        inx
        stx     SCROLLCNT
        jmp     STORELEFT
GOTLEFT:
        inx
        stx     SCROLLCNT
STORELEFT:
        sta     SCROLLBUF+39
        ldx     #39
COPYLEFT:
        lda     SCROLLBUF,x
        sta     SCROLLRAM,x
        dex
        bpl     COPYLEFT
        rts

// -------------------------------------------------------
// COARSERIGHT: shift buffer right, fetch previous char into pos 0
// -------------------------------------------------------
COARSERIGHT:
        ldx     #38
SHIFTRIGHT:
        lda     SCROLLBUF,x
        sta     SCROLLBUF+1,x
        dex
        bpl     SHIFTRIGHT

        // Fetch previous character
        ldx     SCROLLCNT
        dex                         // go back one
        bpl     GOTRIGHT
        // Underflow — find end of text and wrap
        ldx     #0
FINDEND:
        lda     SCROLLTEXT,x
        cmp     #$ff
        beq     FOUNDEND
        inx
        jmp     FINDEND
FOUNDEND:
        dex                         // step back from $ff to last real char
GOTRIGHT:
        stx     SCROLLCNT
        lda     SCROLLTEXT,x
        sta     SCROLLBUF+0

        ldx     #39
COPYRIGHT:
        lda     SCROLLBUF,x
        sta     SCROLLRAM,x
        dex
        bpl     COPYRIGHT
        rts
// Scroll text

SCROLLSPEED:
        .byte $1                 // initial speed: 1 pixel/frame left
SCROLLX:
        .byte 7                 // current fine scroll value (0-7)
SCROLLCNT:
        .byte 0                 // current position in scroll text
SCROLLBUF:
        .fill 41, 0             // 41-byte working buffer
SCROLLTEXT:
        // "HELLO THIS IS A SMOOTH SCROLLER ON THE C64   "
        .byte 8,5,12,12,15,32,20,8,9,19,32,9,19,32,1,32,19,13,15,15,20,8,32
        .byte 19,3,18,15,12,12,5,18,32,15,14,32,20,8,5,32,3,54,52,32,32,32
        .byte $ff

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

* = $1800
.import binary "bombo.sid", 126