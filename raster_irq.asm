// raster_irq.asm
.label TABLESTART       = 16
.label TABLEND          = 288
.label TABLESIZE        = TABLEND - TABLESTART
.label DISPOFF_TOP      = 35
.label DISPON_LEN       = 200
.label PHASE3_START_IDX = 235 // was 236
.label COLORTABLE2 = COLORTABLE + 235 // Used in PHASE3_LOOP

// Raster line where PHASE1 starts (IRQ trigger when PHASE1 active)
.label PHASE1_RASTER   = TABLESTART - 2 // was TABLESTART - 1

// Raster line where PHASE2 starts (IRQ trigger when PHASE1 skipped)
//.label PHASE2_RASTER   = TABLESTART - 1 + DISPOFF_TOP
.label PHASE2_RASTER = 48 
//.label PHASE2_RASTER = PHASE1_RASTER + DISPOFF_TOP  // tune the +1 by testing
.label PHASE3_SIZE     = 37
.label RASTER_STATE_TOP_ACTIVE    = 1
.label RASTER_STATE_BOTTOM_ACTIVE = 0
.label RASTER_STATE_BOTH_ACTIVE   = 2

// ----------
// Subroutine
// ----------
* = * "Raster interrupt VIC and irq init"
INIT_VIC_AND_IRQ:
        sei

        // Clear pending VIC IRQ flags
        lda     #$ff
        sta     VICIRQFLAG
        
        // Clear high raster bit, enable display
        lda #DISPLAYON
		sta VICICR
        
        // Disable CIA1 timer IRQ entirely
        lda     #$7f
        sta     $dc0d
        lda     $dc0d
        
        // Disable all CIA2 NMI sources
        lda     #$7f
        sta     $dd0d
        lda     $dd0d
        
        // Point IRQ and NMI vectors
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

		//SetRasterStateBottomActive()
		//SetRasterStateTopActive()
		SetRasterStateBothActive()
        cli
        rts

// ----------------
// Raster Interrupt
// ----------------
.align 256
* = * "Raster interrupt code"

IRQ1:
    lda #<IRQ2
    sta $fffe
    lda #>IRQ2
    sta $ffff
    inc VICRASTER
    lda #$01                // acknowledge BEFORE cli
    sta VICIRQFLAG
    cli                     // NOW enable interrupts
    skla:
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    sei
    rti
IRQ2:
    lda		#<IRQ1
    sta		$fffe
    lda		#>IRQ1
    sta		$ffff
    dec		VICRASTER
    lda		#$01
    sta		VICIRQFLAG
	nops(11)
    // PAL stabilisation
    ldx		$d012               // 4 cycles → lands at 57 or 59
    cpx		$d012               // 4 cycles → lands at 61 or 63  ← straddles boundary
    beq		*+2                 // 2 or 3 cycles → equalises
    nops(21)
    bit		$02
    ldx		COLORTABLE+34		// This color will be used in the first raster line of phase2 is phase1 is skipped
PRELOAD_A:
    lda		COLORTABLE			// This color will be either used in the first raster line of phase1 or the second raster line of phase2
    						// It will, potentially, be modified every frame
IRQHANDLER:
    jmp		PHASE1_ACTIVE


        // -------------------------------------------------------
        // PHASE1 active: raster bars for top border area
        // -------------------------------------------------------
PHASE1_ACTIVE:
.for (var i = 0; i < 11; i++) {
        sta     VICBGCOLOR		// 4
		lda     COLORTABLE+i+1	// 4
        ldx     #D016_WIDE          // re-arm the right edge at the far position
        ldy     #D016_NARROW       // offsets 55-56  (2 cycles)
        nops(20)				// 48
        stx     VICXSCROLL          //  -> write lands on cycle 17
        sty     VICXSCROLL         // offsets 57-60  (4 cycles, write lands on cycle 56)
        bit     $02				// 3	Total = 63
}

SJASK: // LIN=27 ($1b), CYC=59
// This is where I test cycle compensation.
.for (var i = 11; i < 32; i++) {
        sta     VICBGCOLOR			// 4
        lda     COLORTABLE+i+1		// 4
        ldx     #D016_WIDE          // 2   re-arm the right edge at the far position
        ldy     #D016_NARROW        // 2   offsets 55-56  (2 cycles)
        nops(16)					//32
        bit		$02  				// 3
        stx     VICXSCROLL          // 4   -> write lands on cycle 17
        sty     VICXSCROLL          // 4   offsets 57-60  (4 cycles, write lands on cycle 56)
        bit		$02					// 3
}

// Last two raster lines of Phase1
.for (var i = 32; i < (DISPOFF_TOP-1-1); i++) {
        sta     VICBGCOLOR		// 4
        lda     COLORTABLE+i+1	// 4
        ldx     #D016_WIDE      // 2   re-arm the right edge at the far position
        ldy     #D016_NARROW    // 2   offsets 55-56  (2 cycles)
        nops(20)				// 40
        stx     VICXSCROLL      // 4   -> write lands on cycle 17
        sty     VICXSCROLL      // 4   offsets 57-60  (4 cycles, write lands on cycle 56)
        bit		$02				// 3
}
		// This is the last rasterline in Phase1 before the screen area
        sta     VICBGCOLOR		// 4
        lda     COLORTABLE+34+1	// 4   this is used in the raster line after the next raster line
        ldx		COLORTABLE+34   // 4   this is for the next raster line
        
		ldy     #$18            // 2  ADD
        sty     VICICR          // 4  ADD — prime YSCROLL=0 before PHASE2_ENTRY
        nops(18)                // 36 
        bit     $02             // 3 = 63
PHASE2_ENTRY:
.for (var row = 0; row < 22; row++) {
    .for (var line = 0; line < 8; line++) {
        .var isArm = (row == 21 && line == 7)
        .var d011 = isArm ? $1B : ($18 | (line == 5 ? 1 : 0))

        .if (line == 0) {
        stx     VICBGCOLOR
        ldy     #d011
        sty     VICICR
        nops(25)
        bit     $02
        } else { .if (line < 7) {
        sta     VICBGCOLOR
        ldy     #d011
        sty     VICICR
        lda     COLORTABLE + DISPOFF_TOP + row*8+line
        nops(23)
        bit     $02
        } else {
        sta     VICBGCOLOR
        ldy     #d011
        sty     VICICR
        lda     COLORTABLE + DISPOFF_TOP + row*8+7+1
        ldx     COLORTABLE + DISPOFF_TOP + row*8+7+0
        nops(17)
        ldy     SCROLLX
        sty     VICXSCROLL
        bit     $02
        } }
    }
}
// =========================================================
// Row 22: 7 normal lines and one that enables screen (in row 22)
// =========================================================
ROW22:
    .for (var line = 0; line < 8; line++) {
        .var isArm = (line == 7)
        .var d011 = isArm ? $1B : ($18 | (line == 5 ? 1 : 0))

        .if (line == 0) {
        stx     VICBGCOLOR
        ldy     #d011
        sty     VICICR
        nops(25)
        bit     $02
        } else { .if (line < 7) {
        sta     VICBGCOLOR
        ldy     #d011
        sty     VICICR
        lda     COLORTABLE + DISPOFF_TOP + 22*8+line
        nops(23)
        bit     $02
        } else {
        sta     VICBGCOLOR
        ldy     #d011
        sty     VICICR
        lda     COLORTABLE + DISPOFF_TOP + 22*8+7+1
        ldx     COLORTABLE + DISPOFF_TOP + 22*8+7+0
        nops(17)
        ldy     SCROLLX
        sty     VICXSCROLL
        bit     $02
        } }
    }

// =========================================================
// Row 23: 1 bad line, 7 normal lines (in row 23)
// =========================================================
ROW23:
		// This is the bad line
	    stx     VICBGCOLOR			// 4
		nops(8)						// 6

		// These are 6 normal lines (in row 23)
    .for (var line = 1; line < 7; line++) {
        sta     VICBGCOLOR				// 4
        lda     COLORTABLE + DISPOFF_TOP + 23*8+line	// 4   
		nops(26)						// 52
        bit $02							// 3	total = 63
    }

		// This is the last raster line in row 23
        sta     VICBGCOLOR				// 4
        lda     COLORTABLE + DISPOFF_TOP + 23*8+7+1	// 4
        ldx		COLORTABLE + DISPOFF_TOP + 23*8+7+0	// 4
		nops(20)				// 4
		ldy		SCROLLX			// 4
        sty     VICXSCROLL		// 4

        bit $02					// 3	total = 63



// =========================================================
// Row 24 — special last row: 1 bad line, 4 normal lines, open-border line, 2 normal lines
// =========================================================

    // 1st raster line in 25th text row is a Bad line, 43 cycles stolen, 20 remain
    stx     VICBGCOLOR			// 4
    nops(8)						// 16

.for (var line = 1; line < 5; line++) {
	sta     VICBGCOLOR								// 4
    lda     COLORTABLE + DISPOFF_TOP + 24*8+line	// 4
    nops(26)										// 52
    bit $02											// 3
}

// --- Third-last line: open border trick ---
PHASE2_OPENBORDER:
        sta     VICBGCOLOR	// 4
        
        // Open top/bottom border trick should on raster lines 248-250
        lda     #$13		// 2
        sta     VICICR		// 4
        lda     COLORTABLE + DISPOFF_TOP + 24*8+5	// 4	
		nops(23)		// 46
		bit		$02		// 3

// --- Penultimate line: normal ---
PHASE2_PENULTIMATE:
        sta     VICBGCOLOR							// 4
        lda     COLORTABLE + DISPOFF_TOP + 24*8+6	// 4
		nops(26) // 52
		bit		$02

// --- Last line: normal ---
PHASE2_LAST:
        sta     VICBGCOLOR			// 4
		nops(23)					// 46

		// disable sprites to avoid ghost lines in the bottom
        lda     #%00000000							// 2
        sta     VIC_SPRITE_ENABLE					// 4
        lda     COLORTABLE + DISPOFF_TOP + 24*8+7	// 4

PHASE3_JMP:        
        jmp     PHASE3_LOOP		// 3	Total = 62

        // -------------------------------------------------------------------
        // PHASE3: raster bars for bottom border area
        // -------------------------------------------------------------------

PHASE3_LOOP:
.for (var i = 0; i < 37; i++) {
        sta     VICBGCOLOR
        lda     COLORTABLE + DISPOFF_TOP + 25*8+i
        ldx     #D016_WIDE          // re-arm the right edge at the far position
        ldy     #D016_NARROW       // offsets 55-56  (2 cycles)
        nops(20)				// 48
        stx     VICXSCROLL          //  -> write lands on cycle 17
        sty     VICXSCROLL         // offsets 57-60  (4 cycles, write lands on cycle 56)
//        ldy		COLORTABLE + DISPOFF_TOP + 25*8+i	// Just a test to get rid of a small "overwrite"
        bit		$02

}




		// -------------------------------------------------------
        // Runs directly after Phase3 (bottom border raster bars).
        // -------------------------------------------------------
OFFSCREEN_WORK_AFTER_PHASE3:
        ldy     #$00
        sty     VICBORDER
        sty     VICBGCOLOR
        
//        SaveMainloopMeasurement()
        
        jsr     DOSCROLL
        //jsr     UPDATESPEED
        jsr     MOVESPRITES
        //jsr		DORASTERBARS
        
        //UpdateSidPlayerArkPandora()
     	
        // running when bottom active, watch for bar entering top
        ActivateTopIfBarEntersTop()
/*
    ldx #$80
delay1:
    dex
    bne delay1
*/
        // Write $1b to VICICR to restore 25-row mode each frame,
        // which is what keeps the bottom border open (open border trick)
        lda     #$1b
        sta     VICICR

		// re-enable sprite visibility
        lda     #%00100000
        sta     VIC_SPRITE_ENABLE

		// As Phase1 will be skipped, we need to preload X and A with raster line colors  
TUST:
        ldx		COLORTABLE+34 // this is for the first raster line in Phase2
        lda     COLORTABLE+34+1	// this is for the second raster line in Phase2

        rti

        // ---------------------------------------------
        // Runs after Phase2
        // Phase3 (bottom border) is skipped this frame.
        // ---------------------------------------------
OFFSCREEN_WORK_AFTER_PHASE2:
        ldy     #$00
        sty     VICBORDER
        sty     VICBGCOLOR
        
//        SaveMainloopMeasurement()
        jsr     DOSCROLL
        //jsr     UPDATESPEED
        jsr     MOVESPRITES
		//jsr		DORASTERBARS
        
        //UpdateSidPlayerArkPandora()
		
		// running when top active, watch for bar entering bottom
		ActivateBottomIfBarEntersBottom()


    ldx #$10
delay2:
    dex
    bne delay2


        // Write $1b to VICICR to restore 25-row mode each frame,
        // which is what keeps the bottom border open (open border trick)
        lda     #$1b
        sta     VICICR

		// re-enable sprite visibility
        lda     #%00100000
        sta     VIC_SPRITE_ENABLE

        rti

// ------
// MACROS
// ------
.macro SetRasterStateBottomActive() {
        lda     #PHASE2_RASTER
        sta     VICRASTER
        lda     #<PHASE2_ENTRY        // was PHASE2_ENTRY_SKIP
        sta     IRQHANDLER+1
        lda     #>PHASE2_ENTRY        // was PHASE2_ENTRY_SKIP
        sta     IRQHANDLER+2
        lda     #<(COLORTABLE+34+1)
        sta     PRELOAD_A+1
        lda     #>(COLORTABLE+34+1)
        sta     PRELOAD_A+2
        lda     #<PHASE3_LOOP
        sta     PHASE3_JMP+1
        lda     #>PHASE3_LOOP
        sta     PHASE3_JMP+2
        lda     #RASTER_STATE_BOTTOM_ACTIVE
        sta     RASTER_STATE
}

.macro SetRasterStateTopActive() {
        lda     #PHASE1_RASTER
        sta     VICRASTER
        lda     #<PHASE1_ACTIVE
        sta     IRQHANDLER+1
        lda     #>PHASE1_ACTIVE
        sta     IRQHANDLER+2
        lda     #<COLORTABLE
        sta     PRELOAD_A+1
        lda     #>COLORTABLE
        sta     PRELOAD_A+2
        lda     #<OFFSCREEN_WORK_AFTER_PHASE2
        sta     PHASE3_JMP+1
        lda     #>OFFSCREEN_WORK_AFTER_PHASE2
        sta     PHASE3_JMP+2
        lda     #RASTER_STATE_TOP_ACTIVE
        sta     RASTER_STATE
}

.macro SetRasterStateBothActive() {
        lda     #PHASE1_RASTER
        sta     VICRASTER
        lda     #<PHASE1_ACTIVE
        sta     IRQHANDLER+1
        lda     #>PHASE1_ACTIVE
        sta     IRQHANDLER+2
        lda     #<COLORTABLE
        sta     PRELOAD_A+1
        lda     #>COLORTABLE
        sta     PRELOAD_A+2
        lda     #<PHASE3_LOOP       // don't skip Phase3
        sta     PHASE3_JMP+1
        lda     #>PHASE3_LOOP
        sta     PHASE3_JMP+2
        lda     #RASTER_STATE_BOTH_ACTIVE
        sta     RASTER_STATE
}

.macro ActivateTopIfBarEntersTop() {
        lda     RASTER_STATE
        cmp     #RASTER_STATE_TOP_ACTIVE
        beq     !skip+
        cmp     #RASTER_STATE_BOTH_ACTIVE   // add this
        beq     !skip+                       // add this
        lda     BAR_YPOS_HI
        bne     !skip+
        lda     BAR_YPOS
        cmp     #BARTABLE_OFFSET
        bcs     !skip+
        SetRasterStateTopActive()
!skip:
}

.macro ActivateBottomIfBarEntersBottom() {
        lda     RASTER_STATE
        cmp     #RASTER_STATE_BOTTOM_ACTIVE
        beq     !skip+
        cmp     #RASTER_STATE_BOTH_ACTIVE   // add this
        beq     !skip+                       // add this
        lda     BAR_YPOS_HI
        bne     !switch+
        lda     BAR_YPOS
        cmp     #PHASE3_START_IDX - (BAR_HEIGHT - 1)
        bcc     !skip+
!switch:
        SetRasterStateBottomActive()
!skip:
}

.macro nops(count) {
    .for (var i = 0; i < count; i++) {
        nop
    }
}
		// Trick to turn 4 or 6 cycles into 5
		//		clc
		//		bcc *+2