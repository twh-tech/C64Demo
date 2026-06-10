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

		SaveMainloopMeasurement()

//        jsr		DORASTERBARS
        jsr     DOSCROLL
        jsr     UPDATESPEED
		jsr		MOVESPRITES

//        jsr     $180c               // SID player Bombo
        //UpdateSidPlayerArkPandora()

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

		SaveMainloopMeasurement()

//		jsr		DORASTERBARS
        jsr     DOSCROLL
        jsr     UPDATESPEED
        jsr		MOVESPRITES

//        jsr     $180c               // SID player Bombo
        //UpdateSidPlayerArkPandora()
        
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

		// Trick to turn 4 or 6 cycles into 5
		//		clc
		//		bcc *+2