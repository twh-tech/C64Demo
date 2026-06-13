// raster_irq.asm
.label TABLESTART       = 16
.label TABLEND          = 288
.label TABLESIZE        = TABLEND - TABLESTART
.label DISPOFF_TOP      = 35
.label DISPON_LEN       = 200
.label PHASE3_START_IDX = 235 // was 236
.label COLORTABLE2 = COLORTABLE + 235 // Used in PHASE3_LOOP

// Raster line where PHASE1 starts (IRQ trigger when PHASE1 active)
.label PHASE1_RASTER   = TABLESTART - 1

// Raster line where PHASE2 starts (IRQ trigger when PHASE1 skipped)
//.label PHASE2_RASTER   = TABLESTART - 1 + DISPOFF_TOP
.label PHASE2_RASTER = 50 
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
        lda     VICICR
        and     #$7f
        sta     VICICR
        lda     #DISPLAYON
        sta     VICICR
        
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

//		SetRasterStateBottomActive()
//		SetRasterStateTopActive()
		SetRasterStateBothActive()
        cli
        rts

// ----------------
// Raster Interrupt
// ----------------
.align 256
* = * "Raster interrupt code"
IRQ1:
        lda     VICIRQFLAG
        and     #$01
        bne     !is_raster+
        rti
!is_raster:
        lda     #$01
        sta     VICIRQFLAG
		nops(13)
IRQHANDLER:
        jmp     PHASE1_ACTIVE

        // -------------------------------------------------------
        // PHASE1 active: raster bars for top border area
        // -------------------------------------------------------
PHASE1_ACTIVE:
.for (var i = 0; i < DISPOFF_TOP; i++) {
        lda     COLORTABLE+i    // 4
        sta     VICBORDER       // 4
        sta     VICBGCOLOR      // 4
        nops(22)				// 44
        clc                     // 2
        bcc     *+2             // 3
        nop                     // 2	Total = 63
}


PHASE2_ENTRY:

.for (var row = 0; row < 24; row++) {

    // --- Bad line: first line of the row, 40 cycles stolen, 23 remain ---
    lda     COLORTABLE + DISPOFF_TOP + row*8	// 4
    sta     VICBORDER			// 4
    sta     VICBGCOLOR			// 4
    nops(4)						// 6
//    clc							// 2
//    bcc     *+2					// 3	// total = 23 (+40 stolen = 63)

    // --- Remaining 7 normal lines of this row ---
    .for (var line = 1; line < 8; line++) {
        lda     COLORTABLE + DISPOFF_TOP + row*8+line	// 4
        sta     VICBORDER				// 4
        sta     VICBGCOLOR				// 4
PAD0:   nops(3)					// 6
PAD1:   nops(3)					// 6
PAD2:   nops(3)					// 6
PAD3:   nops(3)					// 6
PAD4:   nops(3)					// 6
PAD5:   nops(3)					// 6
PAD6:   nops(3)					// 6
        nop						// 2
        nop						// 2
        clc						// 2
        bcc     *+2				// 3	total = 63
    }
}

// =========================================================
// Row 24 — special last row: 1 bad line, 4 normal lines, open-border line, 2 normal lines
// =========================================================

    // 1st raster line in 25th text row is a Bad line, 40 cycles stolen, 23 remain
    lda     COLORTABLE + DISPOFF_TOP + 24*8	// 4
    sta     VICBORDER			// 4
    sta     VICBGCOLOR			// 4
    nops(4)						// 8

.for (var line = 1; line < 5; line++) {
    lda     COLORTABLE + DISPOFF_TOP + 24*8+line	// 4
    sta     VICBORDER	// 4
    sta     VICBGCOLOR	// 4
PAD0:   nops(3)			// 6
PAD1:   nops(3)			// 6
PAD2:   nops(3)			// 6
PAD3:   nops(3)			// 6
PAD4:   nops(3)			// 6
PAD5:   nops(3)			// 6
PAD6:   nops(3)			// 6
        nop				// 2
        nop				// 2
        clc				// 2
        bcc     *+2     // 3	total = 63
}

// --- Third-last line: open border trick ---
PHASE2_OPENBORDER:
        lda     COLORTABLE + DISPOFF_TOP + 24*8+5	// 4	
        sta     VICBORDER	// 4
        sta     VICBGCOLOR	// 4
        lda     #$13		// 2
        sta     VICICR		// 4
OB_PAD0: nops(3)	// 6
OB_PAD1: nops(3)	// 6
OB_PAD2: nops(3)	// 6
OB_PAD3: nops(3)	// 6
OB_PAD4: nops(3)	// 6
OB_PAD5: nops(3)	// 6
OB_PAD6: nops(5)	// 6
        //bit     $02	// 3	total = 63

// --- Penultimate line: normal ---
PHASE2_PENULTIMATE:
        lda     COLORTABLE + DISPOFF_TOP + 24*8+6
        sta     VICBORDER
        sta     VICBGCOLOR
PU_PAD0: nops(3)
PU_PAD1: nops(3)
PU_PAD2: nops(3)
PU_PAD3: nops(3)
PU_PAD4: nops(3)
PU_PAD5: nops(3)
PU_PAD6: nops(3)
        nop
        clc
        bcc     *+2
        nop                 // total = 63

// --- Last line: normal ---
PHASE2_LAST:
        lda     COLORTABLE + DISPOFF_TOP + 24*8+7	// 4
        sta     VICBORDER			// 4
        sta     VICBGCOLOR			// 4
LA_PAD0: nops(3)					// 6
LA_PAD1: nops(3)					// 6
LA_PAD2: nops(3)					// 6
LA_PAD3: nops(3)					// 6
LA_PAD4: nops(3)					// 6
LA_PAD5: nops(3)					// 6
LA_PAD6: nops(3)					// 6
        nop							// 2
//        nop							// 2
        clc							// 2
        bcc     *+2					// 3
PHASE3_JMP:        
        jmp     PHASE3_LOOP			// 3	Total = 63

        // -------------------------------------------------------------------
        // PHASE3: raster bars for main display area
        // PHASE3 is split into two loops as the last loop's lda COLORTABLE2,x
        // is crossing a page boundary causing an extra cycle to be used
        // -------------------------------------------------------------------

PHASE3_LOOP:
.for (var i = 0; i < 37; i++) {
        lda     COLORTABLE2+i
        sta     VICBORDER
        sta     VICBGCOLOR
line_sec0:
        nop
        nop
        nop
line_sec1:
        nop
        nop
        nop
line_sec2:
        nop
        nop
        nop
line_sec3:
        nop
        nop
        nop
line_sec4:        
		nop
		nop
		nop
line_sec5:
		nop
		nop
		nop
line_sec6:
		nop
		nop
		nop
        
        nop
        clc
        bcc     *+2
        inx //nop // was inx
} // 20+17 =37 raster lines


		// -------------------------------------------------------
        // Runs directly after Phase3 (bottom border raster bars).
        // -------------------------------------------------------
OFFSCREEN_WORK_AFTER_PHASE3:
        lda     #$01
        sta     VICBORDER
        sta     VICBGCOLOR
        
        SaveMainloopMeasurement()
        
        //jsr		DORASTERBARS
        jsr     DOSCROLL
        jsr     UPDATESPEED
        //jsr     MOVESPRITES
        
        //UpdateSidPlayerArkPandora()
     	
        // running when bottom active, watch for bar entering top
        ActivateTopIfBarEntersTop()
        
        // Write $1b to VICICR to restore 25-row mode each frame,
        // which is what keeps the bottom border open (open border trick)
        lda     #$1b
        sta     VICICR
        rti

        // ---------------------------------------------
        // Runs after Phase2
        // Phase3 (bottom border) is skipped this frame.
        // ---------------------------------------------
OFFSCREEN_WORK_AFTER_PHASE2:
        lda     #$01
        sta     VICBORDER
        sta     VICBGCOLOR
        
        SaveMainloopMeasurement()
		//jsr		DORASTERBARS
        jsr     DOSCROLL
        jsr     UPDATESPEED
        //jsr     MOVESPRITES
        
        //UpdateSidPlayerArkPandora()
		
		// running when top active, watch for bar entering bottom
		ActivateBottomIfBarEntersBottom()

        // Write $1b to VICICR to restore 25-row mode each frame,
        // which is what keeps the bottom border open (open border trick)
        lda     #$1b
        sta     VICICR
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