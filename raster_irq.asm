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
        lda #DISPLAYOFF
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
		SetRasterStateTopActive()
		//SetRasterStateBothActive()
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
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
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
.for (var i = 0; i < 9; i++) {
//        sta     VICBORDER		// 4
        sta     VICBGCOLOR		// 4
        sta     VICBGCOLOR		// 4
		lda     COLORTABLE+i+1	// 4

        nops(23)				// 46
        clc						// 2
        bcc     *+2				// 3	Total = 63
}


//        sta     VICBORDER		// 4
        sta     VICBGCOLOR		// 4
        sta     VICBGCOLOR		// 4
		lda     COLORTABLE+9+1	// 4

        nops(23)				// 46
        clc						// 2
        bcc     *+2				// 3	Total = 63



//        sta     VICBORDER		// 4
        sta     VICBGCOLOR		// 4
		lda     COLORTABLE+10+1	// 4

        nops(22)				// 46
//        lda #$00
        //bit $02
        nop
        clc						// 2
        bcc     *+2				// 3	Total = 63


SJASK: // LIN=27 ($1b), CYC=59
// This is where I test cycle compensation.
.for (var i = 11; i < 32; i++) {
//        sta     VICBORDER
        sta     VICBGCOLOR		// 4
        sta     VICBGCOLOR
        lda     COLORTABLE+i+1

		// no sprites
		nops(20)
		//bit		$02
        ldy     #D016_NARROW       // offsets 55-56  (2 cycles)
        //sty     VICXSCROLL         // offsets 57-60  (4 cycles, write lands on cycle 56)
        nops(2)
//        nop

}
TJUK:
.for (var i = 32; i < (DISPOFF_TOP-1-1); i++) {
        sta     VICBORDER
        sta     VICBGCOLOR		// 4
        lda     COLORTABLE+i+1
        nops(24)
        bit		$02
}
		// This is the last rasterline in Phase1 before the screen area
        sta     VICBORDER
        sta     VICBGCOLOR		// 4
//        sta     VICBGCOLOR
        lda     COLORTABLE+34+1	// this is used in the raster line after the next raster line
        ldx		COLORTABLE+34 // this is for the next raster line
        nops(22)
		bit		$02
		//ldx #$00
	
        



PHASE2_ENTRY:
.for (var row = 0; row < 24; row++) {
	    // --- Bad line: first line of the row, 40 cycles stolen, 23 remain ---
TJEK:
	    stx     VICBORDER			// 4
	    stx     VICBGCOLOR			// 4
		nops(3)						// 6
		nops(3)						// 6	Total = 20 (+40 stolen = 60)
		
//		nops(20)	// These two lines can be used if we blank the screen and have no bad lines
//	    bit		$02
	
    // --- Next 6 raster lines are normal lines of this row ---
    .for (var line = 1; line < 7; line++) {
        sta     VICBORDER				// 4
        sta     VICBGCOLOR				// 4
        lda     COLORTABLE + DISPOFF_TOP + row*8+line	// 4   
		nops(3)					// 6
		nops(3)					// 6
		nops(3)					// 6
		nops(3)					// 6
		nops(3)					// 6
		nops(3)					// 6
		nops(3)					// 6
		nops(3)						// 2
        bit $02//bcc     *+2				// 3	total = 63
    }
    	// This is the last raster line in each of the 25 character rows
        sta     VICBORDER				// 4
        sta     VICBGCOLOR				// 4
        lda     COLORTABLE + DISPOFF_TOP + row*8+7+1	// 4
        ldx		COLORTABLE + DISPOFF_TOP + row*8+7+0	// 4
		nop
		nops(3)					// 6
		nops(3)					// 6
		nops(3)					// 6
		nops(3)					// 6
		nops(3)					// 6
		nops(3)					// 6
		nops(3)						// 2
        bit $02//bcc     *+2				// 3	total = 63

}

// =========================================================
// Row 24 — special last row: 1 bad line, 4 normal lines, open-border line, 2 normal lines
// =========================================================

    // 1st raster line in 25th text row is a Bad line, 40 cycles stolen, 23 remain
    stx     VICBORDER			// 4
    stx     VICBGCOLOR			// 4
    nops(3)						// 6
    nops(3)						// 6
//    nops(20)
//    bit		$02 

.for (var line = 1; line < 5; line++) {
    sta     VICBORDER	// 4
	sta     VICBGCOLOR	// 4
    lda     COLORTABLE + DISPOFF_TOP + 24*8+line	// 4
	nops(3)			// 6
	nops(3)			// 6
	nops(3)			// 6
	nops(3)			// 6
	nops(3)			// 6
	nops(3)			// 6
	nops(3)			// 6
    nop				// 2
    nop				// 2
    clc				// 2
    bcc     *+2     // 3	total = 63
}

// --- Third-last line: open border trick ---
PHASE2_OPENBORDER:
        sta     VICBORDER	// 4
        sta     VICBGCOLOR	// 4
        lda     #$13		// 2
        sta     VICICR		// 4
        lda     COLORTABLE + DISPOFF_TOP + 24*8+5	// 4	
		nops(3)	// 6
		nops(3)	// 6
		nops(3)	// 6
		nops(3)	// 6
		nops(3)	// 6
		nops(3)	// 6
		nop	// 2
		clc
		bcc		*+2
		nop
		//lda		#$00	

        //bit     $02	// 3	total = 63

// --- Penultimate line: normal ---
PHASE2_PENULTIMATE:
        sta     VICBORDER							// 4
        sta     VICBGCOLOR							// 4
        lda     COLORTABLE + DISPOFF_TOP + 24*8+6	// 4
		nops(3) // 6
		nops(3) // 6
		nops(3) // 6
		nops(3) // 6
		nops(3) // 6
		nops(3) // 6
		nops(3) // 6
		//nops(3) // 6
		clc
		bcc		*+2
        nop		// 2
        nop		// 2	Total = 64 

// --- Last line: normal ---
PHASE2_LAST:
        sta     VICBORDER			// 4
        sta     VICBGCOLOR			// 4
		nops(3)					// 6
		nops(3)					// 6
		nops(3)					// 6
		nops(3)					// 6
		nops(3)					// 6
		nops(3)					// 6
		nops(3)					// 6

		//nops(3)					// 6
		// disable sprites to avoid ghost lines in the bottom
        lda     #%00000000
        sta     VIC_SPRITE_ENABLE
        lda     COLORTABLE + DISPOFF_TOP + 24*8+7	// 4

//        clc						// 2
//        bcc     *+2				// 3
PHASE3_JMP:        
        jmp     PHASE3_LOOP		// 3	Total = 62

        // -------------------------------------------------------------------
        // PHASE3: raster bars for bottom border area
        // -------------------------------------------------------------------

PHASE3_LOOP:
.for (var i = 0; i < 37; i++) {
        sta     VICBORDER
        sta     VICBGCOLOR
        lda     COLORTABLE + DISPOFF_TOP + 25*8+i
        nops(3)
        nops(3)
        nops(3)
        nops(3)
        nops(3)
        nops(3)
        nops(3)
        nops(1)
        ldy		COLORTABLE + DISPOFF_TOP + 25*8+i	// Just a test to get rid of a small "overwrite"
        bit		$02

} // 20+17 =37 raster lines


		// -------------------------------------------------------
        // Runs directly after Phase3 (bottom border raster bars).
        // -------------------------------------------------------
OFFSCREEN_WORK_AFTER_PHASE3:
        ldy     #$00
        sty     VICBORDER
        sty     VICBGCOLOR
        
//        SaveMainloopMeasurement()
        
        //jsr     DOSCROLL
        //jsr     UPDATESPEED
        //jsr     MOVESPRITES
        //jsr		DORASTERBARS
        
        //UpdateSidPlayerArkPandora()
     	
        // running when bottom active, watch for bar entering top
        ActivateTopIfBarEntersTop()
/*        
        inc		$d000
        dec		$d002        
        inc		$d004
        inc		$d004
        dec		$d006
        dec		$d006
*/
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
        lda		#ONESPRITE
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
        //jsr     DOSCROLL
        //jsr     UPDATESPEED
        //jsr     MOVESPRITES
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
        lda		#ONESPRITE
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