.label TABLESTART      = 16
.label TABLEND         = 288
.label TABLESIZE       = TABLEND - TABLESTART
//.label DISPOFF_TOP     = 36
.label DISPOFF_TOP = 35   // was 36, compensate for TABLESTART moving from 15 to 16
.label DISPON_LEN      = 200
.label PHASE3_START_IDX = 235 // was 236
.label COLORTABLE2 = COLORTABLE + 235 // Used in PHASE3_LOOP

// Raster line where PHASE1 starts (IRQ trigger when PHASE1 active)
.label PHASE1_RASTER   = TABLESTART - 1

// Raster line where PHASE2 starts (IRQ trigger when PHASE1 skipped)
//.label PHASE2_RASTER   = TABLESTART - 1 + DISPOFF_TOP
.label PHASE2_RASTER = 50 
.label PHASE3_SIZE     = 37
.label RASTER_STATE_TOP_ACTIVE    = 0
.label RASTER_STATE_BOTTOM_ACTIVE = 1

IRQ1:
        lda     VICIRQFLAG
        and     #$01
        bne     IS_RASTER
        rti

IS_RASTER:
        lda     #$01
        sta     VICIRQFLAG
		nops(12)
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
		nops(22)
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
        nops(4)
        inx
        bne     PHASE2_N1

PHASE2_N1:
        lda     COLORTABLE,x
        sta     VICBORDER
        sta     VICBGCOLOR
        nops(23)
        inx
        bne     PHASE2_N2

PHASE2_N2:
        lda     COLORTABLE,x
        sta     VICBORDER
        sta     VICBGCOLOR
        nops(23)
        inx
        bne     PHASE2_N3

PHASE2_N3:
        lda     COLORTABLE,x
        sta     VICBORDER
        sta     VICBGCOLOR
        nops(23)
        inx
        bne     PHASE2_N4

PHASE2_N4:
        lda     COLORTABLE,x
        sta     VICBORDER
        sta     VICBGCOLOR
        nops(23)
        inx
        bne     PHASE2_N5

PHASE2_N5:
        lda     COLORTABLE,x
        sta     VICBORDER
        sta     VICBGCOLOR
        nops(23)
        inx
        bne     PHASE2_N6

PHASE2_N6:
        lda     COLORTABLE,x
        sta     VICBORDER
        sta     VICBGCOLOR
        cpy     #1                      // 2 cycles - check if last iteration
        beq     PHASE2_LAST             // 3 cycles taken / 2 cycles not taken
        nops(21)
        inx
        bne     PHASE2_N7


PHASE2_N7:
        lda     COLORTABLE,x
        sta     VICBORDER
        sta     VICBGCOLOR
        nops(19)
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
        nops(17)
        inx                             // crosses into last raster line
        lda     COLORTABLE,x
        sta     VICBORDER
        sta     VICBGCOLOR
        nops(23)
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
        nops(22)
        inx
        cpx     #20
        bne     PHASE3_LOOP

PHASE3_LOOP_B:
        lda     COLORTABLE2,x
        sta     VICBORDER
        sta     VICBGCOLOR
        nops(19)
		clc
		bcc *+2
        inx
        cpx     #PHASE3_SIZE
        bne     PHASE3_LOOP_B


// -------------------------------------------------------
        // OFFSCREEN_WORK: runs after Phase3 (bottom border raster bars).
        // Phase1 (top border) is skipped this frame.
        // -------------------------------------------------------
OFFSCREEN_WORK:
        lda     #$00
        sta     VICBORDER
        sta     VICBGCOLOR
        
        SaveMainloopMeasurement()
        
        jsr		DORASTERBARS
        jsr     DOSCROLL
        jsr     UPDATESPEED
        jsr     MOVESPRITES
        
        //UpdateSidPlayerArkPandora()

        ActivateBottomIfBarEntersBottom()
        
        // Write $1b to VICICR to restore 25-row mode each frame,
        // which is what keeps the bottom border open (open border trick)
        lda     #$1b
        sta     VICICR
        rti

        // -------------------------------------------------------
        // OFFSCREEN_WORK_SKIP: runs after Phase1 (top border raster bars).
        // Phase3 (bottom border) is skipped this frame.
        // -------------------------------------------------------
OFFSCREEN_WORK_SKIP:
        lda     #$00
        sta     VICBORDER
        sta     VICBGCOLOR
        
        SaveMainloopMeasurement()
		jsr		DORASTERBARS
        jsr     DOSCROLL
        jsr     UPDATESPEED
        jsr     MOVESPRITES
        
        //UpdateSidPlayerArkPandora()

		ActivateTopIfBarEntersTop()

        // Write $1b to VICICR to restore 25-row mode each frame,
        // which is what keeps the bottom border open (open border trick)
        lda     #$1b
        sta     VICICR
        rti

// ------
// MACROS
// ------
.macro SetRasterStateTopActive() {
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
        lda     #RASTER_STATE_TOP_ACTIVE
        sta     RASTER_STATE
}

.macro SetRasterStateBottomActive() {
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
        lda     #RASTER_STATE_BOTTOM_ACTIVE
        sta     RASTER_STATE
}

.macro ActivateTopIfBarEntersTop() {
        lda     RASTER_STATE
        cmp     #RASTER_STATE_TOP_ACTIVE
        beq     !skip+
        lda     BAR_YPOS_HI
        bne     !switch+
        lda     BAR_YPOS
        cmp     #PHASE3_START_IDX - (BAR_HEIGHT - 1)
        bcc     !skip+
!switch:
        SetRasterStateTopActive()
!skip:
}

.macro ActivateBottomIfBarEntersBottom() {
        lda     RASTER_STATE
        cmp     #RASTER_STATE_BOTTOM_ACTIVE
        beq     !skip+
        lda     BAR_YPOS_HI
        bne     !skip+
        lda     BAR_YPOS
        cmp     #BARTABLE_OFFSET
        bcs     !skip+
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