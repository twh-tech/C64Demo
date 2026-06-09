*=$0801 "Basic stub"
        .byte   $0b,$08
        .byte   $0a,$00
        .byte   $9e
        .byte   $20
        .text   "2064"
        .byte   $00,$00,$00
        *=$0810 "Start"

.label IRQVEC          = $0314
.label VICICR          = $d011
.label VICRASTER       = $d012
.label VICXSCROLL      = $d016
.label VICMEMCTRL      = $d018
.label VICIRQFLAG      = $d019
.label VICBORDER       = $d020
.label VICBGCOLOR      = $d021
.label VICIRQENABLE    = $d01a
.label TABLESTART      = 16
.label TABLEND         = 288
.label TABLESIZE       = TABLEND - TABLESTART
.label PHASE3_SIZE     = 37
.label DISPLAYON       = %00011011
//.label DISPOFF_TOP     = 36
.label DISPOFF_TOP = 35   // was 36, compensate for TABLESTART moving from 15 to 16
.label DISPON_LEN      = 200
.label SCROLLROW       = 12
.label SCROLLRAM       = $0400 + SCROLLROW * 40
.label SCROLLRAM2      = $0400 + (SCROLLROW+1) * 40
.label PHASE3_START_IDX = 235 // was 236
.label COLORTABLE2 = COLORTABLE + 235 // Used in PHASE3_LOOP

// Raster line where PHASE1 starts (IRQ trigger when PHASE1 active)
.label PHASE1_RASTER   = TABLESTART - 1

// Raster line where PHASE2 starts (IRQ trigger when PHASE1 skipped)
//.label PHASE2_RASTER   = TABLESTART - 1 + DISPOFF_TOP
.label PHASE2_RASTER = 50 

START:
        lda     #$35		// Disable Kernal
        //lda		#$36		// Disable Kernal and Basic
        sta     $01             // RAM under BASIC+KERNAL, I/O still visible

		lda		#$01
		//jsr		$b4c0	// Init the SID tune Ark Pandora

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

		lda     PHASE_STATE
        bne     INIT_STATE_B
        // State A: Phase1 skipped, Phase3 active
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
        jmp     INIT_DONE
INIT_STATE_B:
        // State B: Phase1 active, Phase3 skipped
        lda     #PHASE1_RASTER
        sta     VICRASTER
        lda     #<PHASE1_ACTIVE
        sta     IRQHANDLER+1
        lda     #>PHASE1_ACTIVE
        sta     IRQHANDLER+2
        lda     #<OFFSCREEN_WORK_SKIP
        sta     PHASE3_JMP+1
        lda     #>OFFSCREEN_WORK_SKIP
        sta     PHASE3_JMP+2
INIT_DONE:

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
        nop                             // 22 NOPs = 44
        
        //extra
        nop
        nop
        nop
        nop
        nop
        nop
        
        nop
        nop
        inx
        cpx     #DISPOFF_TOP
        bne     PHASE1_LOOP
        jmp     PHASE2_ENTRY

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
        ldx		#$00					// Reset x, as PHASE3_LOOP that comes next use COLORTABLE2 instead of COLORTABLE - This is to prevent wrap around of X
PHASE3_JMP:
        jmp     PHASE3_LOOP

        // -------------------------------------------------------------------
        // PHASE3: raster bars for main display area
        // PHASE3 is split into two loops as the last loop's lda COLORTABLE2,x
        // is crossing a page boundary causing an extra cycle to be used
        // -------------------------------------------------------------------
PHASE3_LOOP:
        lda     COLORTABLE2,x
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
        nop                             // 22 NOPs = 44 cycles
        inx
        cpx     #20
        bne     PHASE3_LOOP

PHASE3_LOOP_B:
        lda     COLORTABLE2,x
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
		clc
		bcc *+2
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
        cpx     #PHASE3_SIZE
        bne     PHASE3_LOOP_B


        // -------------------------------------------------------
        // OFFSCREEN_WORK: runs when Phase 1 is skipped and Phase3 is active.
        // -------------------------------------------------------
OFFSCREEN_WORK:
        lda     #$00
        sta     VICBORDER
        sta     VICBGCOLOR

        jsr		DORASTERBARS
        //jsr     DOSCROLL
        jsr     UPDATESPEED

        //jsr     $180c               // SID player Bombo
        //jsr 	$A007	// Sid Player Ark Pandora
        jmp sid_done
    	lda SID_FRAMES_LEFT
    	bne skip_high_dec
    	dec SID_FRAMES_LEFT+1
skip_high_dec:
    	dec SID_FRAMES_LEFT
    	lda SID_FRAMES_LEFT
    	ora SID_FRAMES_LEFT+1
    	bne sid_done

    	lda #$40
    	sta SID_FRAMES_LEFT
    	lda #$14
    	sta SID_FRAMES_LEFT+1
    	lda #$01
    	jsr $b4c0
sid_done:

		// Check if leading bar is in Phase1 area -> switch to State B
        lda     PHASE_STATE
        bne     NO_SWITCH_A         // already in State B, skip
        lda     BAR_YPOS_HI         // leading bar (bar 0)
        bne     NO_SWITCH_A         // HI=1 means in Phase3 area, no switch
        lda     BAR_YPOS
        cmp     #BARTABLE_OFFSET
        bcs     NO_SWITCH_A         // >= BARTABLE_OFFSET means in Phase2 area, no switch
        // Switch to State B
        lda     #PHASE1_RASTER
        sta     VICRASTER
        lda     #<PHASE1_ACTIVE
        sta     IRQHANDLER+1
        lda     #>PHASE1_ACTIVE
        sta     IRQHANDLER+2
        lda     #<OFFSCREEN_WORK_SKIP
        sta     PHASE3_JMP+1
        lda     #>OFFSCREEN_WORK_SKIP
        sta     PHASE3_JMP+2
        lda     #1
        sta     PHASE_STATE
NO_SWITCH_A:
        // restore 25-row mode - re-arms open border trick for next frame
        lda     #$1b
        sta     VICICR
        rti

        // -------------------------------------------------------
        // OFFSCREEN_WORK_SKIP: runs when Phase 1 is active and Phase3 is skipped.
        // -------------------------------------------------------
OFFSCREEN_WORK_SKIP:
        lda     #$00
        sta     VICBORDER
        sta     VICBGCOLOR

		jsr		DORASTERBARS
        //jsr     DOSCROLL
        jsr     UPDATESPEED


        //jsr     $180c               // SID player Bombo
        //jsr 	$A007	// Sid Player Ark Pandora
		jmp sid_done2
        lda SID_FRAMES_LEFT
    	bne skip_high_dec2
    	dec SID_FRAMES_LEFT+1
skip_high_dec2:
    	dec SID_FRAMES_LEFT
    	lda SID_FRAMES_LEFT
    	ora SID_FRAMES_LEFT+1
    	bne sid_done2

    	lda #$40
    	sta SID_FRAMES_LEFT
    	lda #$14
    	sta SID_FRAMES_LEFT+1
    	lda #$01
    	jsr $b4c0
sid_done2:
        
        //inc     $d001
		// Check if leading bar has left Phase1 area -> switch to State A
        lda     PHASE_STATE
        beq     NO_SWITCH_B         // already in State A, skip
        lda     BAR_YPOS_HI         // leading bar (bar 0)
        bne     DO_SWITCH_A         // HI=1 means beyond index 255, definitely in Phase3
        lda     BAR_YPOS
        cmp     #PHASE3_START_IDX - (BAR_HEIGHT - 1)   // = 230
        bcc     NO_SWITCH_B         // bottom of bar not yet in Phase3, no switch
DO_SWITCH_A:
        // Switch to State A
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
        lda     #0
        sta     PHASE_STATE
NO_SWITCH_B:
        // restore 25-row mode - re-arms open border trick for next frame
        lda     #$1b
        sta     VICICR
        rti

PHASE_STATE:
        .byte 0     // 0 = State A: Phase1 skipped, Phase3 active
                    // 1 = State B: Phase1 active, Phase3 skipped

        // -------------------------------------------------------
        // DOSCROLL
        // -------------------------------------------------------
* = * "Scroll engine"
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
        .byte $01,$04,$07,$05,$01,$04,$07,$05,$01,$04,$07,$05,$01,$04,$07,$05
        .byte $01,$04,$07,$05,$01,$04,$07,$05,$01,$04,$07,$05,$01,$04
        .byte $07,$05,$01,$04,$07,$05,$01,$04,$07,$05,$01,$04,$07,$05,$01,$04
        .byte $07,$05,$01,$04,$07,$05,$01,$04,$07,$05,$01,$04,$07,$05
        .byte $01,$04,$07,$05,$01,$04,$07,$05,$01,$04,$07,$05,$01,$04,$07,$05
        .byte $01,$04,$07,$05,$01,$04,$07,$05,$01,$04,$07,$05,$01,$04
        .byte $07,$05,$01,$04,$07,$05,$01,$04,$07,$05,$01,$04,$07,$05,$01,$04
        .byte $07,$05,$01,$04,$07,$05,$01,$04,$07,$05,$01,$04,$07,$05
        .byte $01,$04,$07,$05,$01,$04,$07,$05,$01,$04,$07,$05,$01,$04,$07,$05
        .byte $01,$04,$07,$05,$01,$04,$07,$05,$01,$04,$07,$05,$01,$04
        .byte $07,$05,$01,$04,$07,$05,$01,$04,$07,$05,$01,$04,$07,$05,$01,$04
        .byte $07,$05,$01,$04,$07,$05,$01,$04,$07,$05,$01,$04,$07,$05
        .byte $01,$04,$07,$05,$01,$04,$07,$05,$01,$04,$07,$05,$01,$04,$07,$05
        .byte $01,$04,$07,$05,$01,$04,$07,$05,$01,$04,$07,$05,$01,$04
        .byte $07,$05,$01,$04,$07,$05,$01,$04,$07,$05,$01,$04,$07,$05,$01,$04
        .byte $07,$05,$01,$04,$07,$05,$01,$04,$07,$05,$01,$04,$07,$05
        .byte $01,$04,$07,$05,$01,$04,$07,$05,$01,$04,$07,$05,$01,$04,$07,$05
        .byte $01,$04,$07,$05,$01,$04,$07,$05,$01,$04,$07,$05,$01,$04
        .byte $07,$05,$01

* = $3000 "SCROLLBUF"
SCROLLBUF:
        .fill 256, $20

* = $3100 "SCROLLBUF2"
SCROLLBUF2:
        .fill 256, $20

* = $2800 "Character set"
.var charset = LoadBinary("ace2char.bin", BF_C64FILE)
.fill charset.getSize(), charset.get(i)

* = $3300 "SETUPSPRITE and stuff"

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
		sta     $07f9           // sprite 1 pointer
        sta     $07fa
		sta     $07fb           // sprite 1 pointer
        sta     $07fc
		sta     $07fd           // sprite 1 pointer
        sta     $07fe
		sta     $07ff           // sprite 1 pointer

        // Sprite color: light blue = $0e
        lda     #$01
        sta     $d027
        clc
		adc #1
        sta     $d028           // sprite 1 color        
        clc
		adc #1
        sta     $d029           // sprite 1 color        
        clc
		adc #1
        sta     $d02a           // sprite 1 color        
        clc
		adc #1
        sta     $d02b           // sprite 1 color        
        clc
		adc #1
        sta     $d02c           // sprite 1 color        
        clc
		adc #1
        sta     $d02d           // sprite 1 color        
        clc
		adc #1
        sta     $d02e           // sprite 1 color        

// X positions evenly distributed across screen
        lda     #24
        sta     $d000           // sprite 0 X = 24
        lda     #66
        sta     $d002           // sprite 1 X = 66
        lda     #108
        sta     $d004           // sprite 2 X = 108
        lda     #150
        sta     $d006           // sprite 3 X = 150
        lda     #192
        sta     $d008           // sprite 4 X = 192
        lda     #234
        sta     $d00a           // sprite 5 X = 234
        lda     #20             // 276 - 256 = 20
        sta     $d00c           // sprite 6 X low byte (full X = 276)
        lda     #62             // 318 - 256 = 62
        sta     $d00e           // sprite 7 X low byte (full X = 318)
        // Set MSB for sprites 6 and 7 (X >= 256)
        lda     #%11000000
        sta     $d010


        // Y position: straddling display/bottom border
        // Display ends around raster 250, sprite is 21 pixels tall
        // Y=241 puts it half in display half in border
        //lda		#$ff
        lda		#$17
        sta     $d001
        sta     $d003  
        sta     $d005
        sta     $d007  
        sta     $d009
        sta     $d00b  
        sta     $d00d
        sta     $d00f  

        // Enable sprite 0
        lda     #%11111111
        sta     $d015

        rts


// -------------------------------------------------------
// Labels used by bar system
// -------------------------------------------------------

.label BAR_COUNT        = 5
.label BAR_HEIGHT       = 7
.label RASTERBAR_TOP    = 51 // was 50
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

BAR_YPOS_HI:
        .byte 0,0,0,0,0

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
        .byte 3    // green
        .byte 4    // yellow

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


SINETABLE:
        .byte 132,135,139,142,145,148,151,155,158,161,164,167,170,174,177,180
        .byte 183,186,189,192,194,197,200,203,206,208,211,214,216,219,221,223
        .byte 226,228,230,232,234,236,238,240,242,244,246,247,249,250,252,253
        .byte 254,0,1,2,3,4,5,5,6,7,7,8,8,8,8,8
        .byte 9,8,8,8,8,8,7,7,6,5,5,4,3,2,1,0
        .byte 254,253,252,250,249,247,246,244,242,240,238,236,234,232,230,228
        .byte 226,223,221,219,216,214,211,208,206,203,200,197,194,192,189,186
        .byte 183,180,177,174,170,167,164,161,158,155,151,148,145,142,139,135
        .byte 132,129,125,122,119,116,113,109,106,103,100,97,94,90,87,84
        .byte 81,78,75,72,70,67,64,61,58,56,53,50,48,45,43,41
        .byte 38,36,34,32,30,28,26,24,22,20,18,17,15,14,12,11
        .byte 10,8,7,6,5,4,3,3,2,1,1,0,0,0,0,0
        .byte 0,0,0,0,0,0,1,1,2,3,3,4,5,6,7,8
        .byte 10,11,12,14,15,17,18,20,22,24,26,28,30,32,34,36
        .byte 38,41,43,45,48,50,53,56,58,61,64,67,70,72,75,78
        .byte 81,84,87,90,94,97,100,103,106,109,113,116,119,122,125,129

SINETABLE_HI:
        .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        .byte 0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
        .byte 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
        .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0




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
* = * "Raster bar engine"
DORASTERBARS:
        // ---- Step 1: Erase all bars (write black to old positions) ----
        lda     #BAR_COUNT-1
        sta     ZP_BARX

ERASE_BAR:
        ldx     ZP_BARX
        lda     BAR_YPOS,x
        sta     ZP_BARPTR
        lda     BAR_YPOS_HI,x
        clc
        adc     #>COLORTABLE
        sta     ZP_BARPTR+1

        lda     #$00
        ldy     #0
        sta     (ZP_BARPTR),y
        iny
        sta     (ZP_BARPTR),y
        iny
        sta     (ZP_BARPTR),y
        iny
        sta     (ZP_BARPTR),y
        iny
        sta     (ZP_BARPTR),y
        iny
        sta     (ZP_BARPTR),y
        iny
        sta     (ZP_BARPTR),y

        dec     ZP_BARX
        bpl     ERASE_BAR

        // ---- Step 2: Advance sine index ----
        lda     SINE_IDX
        clc
        adc     SINE_SPEED
        sta     SINE_IDX

// ---- Step 3: Update all bar positions first ----
        ldx     #0
UPDATEPOS_BAR:
        lda     SINE_IDX
        clc
        adc     BAR_PHASE,x
        tay
        lda     SINETABLE,y
        sta     BAR_YPOS,x
        lda     SINETABLE_HI,y
        sta     BAR_YPOS_HI,x
        inx
        cpx     #BAR_COUNT
        bne     UPDATEPOS_BAR

        // ---- Step 4: Paint bars in correct order ----
        lda     PHASE_STATE
        bne     PAINT_STATE_B

        // State A: paint bar 0 last (on top), count down
PAINT_STATE_A:
        ldx     #BAR_COUNT-1
PAINT_A_LOOP:
        stx     ZP_BARX
        jsr     PAINTBAR
        ldx     ZP_BARX
        dex
        bpl     PAINT_A_LOOP
        rts

        // State B: paint bar BAR_COUNT-1 last (on top), count up
PAINT_STATE_B:
        ldx     #0
PAINT_B_LOOP:
        stx     ZP_BARX
        jsr     PAINTBAR
        ldx     ZP_BARX
        inx
        cpx     #BAR_COUNT
        bne     PAINT_B_LOOP
        rts

        // ---- PAINTBAR: paints single bar at index ZP_BARX ----
PAINTBAR:
        ldx     ZP_BARX
        lda     BAR_YPOS,x
        sta     ZP_BARPTR
        lda     BAR_YPOS_HI,x
        clc
        adc     #>COLORTABLE
        sta     ZP_BARPTR+1

        lda     BAR_TYPE,x
        tay
        lda     BAR_COLOR_LO,y
        sta     $f9
        lda     BAR_COLOR_HI,y
        sta     $fa

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
        sta     (ZP_BARPTR),y
        rts
        
		//		clc
		//		bcc *+2

.print "SINETABLE = $"+toHexString(SINETABLE)
.print "COLORTABLE = $"+toHexString(COLORTABLE)

// Reserve the garbagebyte - nothing must ever be assembled here

* = $3FFF "Garbagebyte"
.byte $00    // garbagebyte - must stay $00 for open border trick

//.import binary "all_spr/uridium.spr"
//* = $1800
//.import binary "bombo.sid", 126

//* = $a000
//.import binary "Ark_Pandora.sid", 126
SID_FRAMES_LEFT:  .word 5200
