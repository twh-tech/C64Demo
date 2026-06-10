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

* = * "Bar data tables"
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

* = * "SINETABLE"
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
        // Paint order depends on which border area is active this frame
        // TOP_ACTIVE: bar 0 painted last (on top), count down
        // BOTTOM_ACTIVE: bar BAR_COUNT-1 painted last (on top), count up
        lda     RASTER_STATE
        bne     PAINT_STATE_B

        // State A: paint bar 0 last (on top), count down
PAINT_STATE_A:
        ldx     #BAR_COUNT-1
!:
        stx     ZP_BARX
        jsr     PAINTBAR
        ldx     ZP_BARX
        dex
        bpl     !-
        rts

        // State B: paint bar BAR_COUNT-1 last (on top), count up
PAINT_STATE_B:
        ldx     #0
!:
        stx     ZP_BARX
        jsr     PAINTBAR
        ldx     ZP_BARX
        inx
        cpx     #BAR_COUNT
        bne     !-
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

.align 256
* = * "COLORTABLE"
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