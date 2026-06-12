.const COLOR0 = $CE00  // Place for color bar 0
.const COLOR1 = $CF00  // Place for color bar 1
.const RASTER = $FA    // Line for the raster interrupt
.const DUMMY  = $CFFF  // Timing variable

*= $C000
        sei             // Disable interrupts
        lda #$7F        // Disable timer interrupts
        sta $DC0D
        lda #$01        // Enable raster interrupts
        sta $D01A
        sta $D015       // Enable Sprite 0
        lda #<IRQ       // Init interrupt vector
        sta $0314
        lda #>IRQ
        sta $0315
        lda #$1B
        sta $D011
        lda #RASTER     // Set interrupt position (inc. 9th bit)
        sta $D012
        lda #RASTER-20  // Sprite will just reach the interrupt position
        sta $D001       //  when it is positioned 20 lines earlier
        ldx #51
        ldy #0
        sta $D017       // No Y-enlargement
LOOP0:  lda COL,x       // Create color bars
        pha
        and #15
        sta COLOR0,x
        sta COLOR0+52,y
        sta COLOR0+104,x
        sta COLOR0+156,y
        pla
        lsr
        lsr
        lsr
        lsr
        sta COLOR1,x
        sta COLOR1+52,y
        sta COLOR1+104,x
        sta COLOR1+156,y
        iny
        dex
        bpl LOOP0
        cli             // Enable interrupts
        rts             // Return

IRQ:    nop             // Wait a bit
        nop
        nop
        nop
        ldy #103        // 104 lines of colors (some of them not visible)
                        // Reduce for NTSC, 55 ?
        inc DUMMY       // Handles the synchronization with the help of the
        dec DUMMY       //  sprite and the 6-clock instructions
                        // Add a NOP for NTSC
FIRST:  ldx COLOR0,y   // Do the color effects
SECOND: lda COLOR1,y
        sta $D020
        stx $D020
        sta $D020
        stx $D020
        sta $D020
        stx $D020
        sta $D020
        stx $D020
        sta $D020
        stx $D020
        sta $D020
        stx $D020
                        // Add a NOP for NTSC (one line = 65 cycles)
        lda #0          // Throw away 2 cycles (total loop = 63 cycles)
        dey
        bpl FIRST       // Loop for 104 lines
        sta $D020
        lda #103        // For subtraction
        dec FIRST+1     // Move the bars
        bpl OVER
        sta FIRST+1
OVER:   sec
        sbc FIRST+1
        sta SECOND+1
        lda #1          // Ack the raster interrupt
        sta $D019
        jmp $EA31       // Jump to the standard irq handler

COL:    .byte $09,$90,$09,$9B,$00,$99,$2B,$08,$90,$29,$8B,$08,$9C,$20,$89,$AB
        .byte $08,$9C,$2F,$80,$A9,$FB,$08,$9C,$2F,$87,$A0,$F9,$7B,$18,$0C,$6F
        .byte $07,$61,$40,$09,$6B,$48,$EC,$0F,$67,$41,$E1,$30,$09,$6B,$48,$EC
        .byte $3F,$77,$11,$11
                        // Two color bars