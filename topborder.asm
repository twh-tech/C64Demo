.label scroly  = $d011
.label raster  = $d012
.label vicirq  = $d019
.label irqmsk  = $d01a
.label ciaicr  = $dc0d
.label ci2icr  = $dd0d
.label garbage = $3fff
*=$0801
        .byte $0c,$08,$0a,$00,$9e,$20,$32
        .byte $30,$36,$34,$00,$00,$00,$00,$00
lab2064:
        sei
        ldx #$7f
        stx ciaicr      // disable timer irq CIA 1
        stx ci2icr      // disable timer irq CIA 2
        ldx #$01
        stx irqmsk      // enable raster irq
        ldx #$1b
        stx scroly
        ldx #$fa		// valid values are $f8-$fa (248, 249, 250)
        stx raster      // first irq at raster $fa
        ldx #$7f
        stx garbage
        ldx #<irq1
        stx $fffe
        ldx #>irq1
        stx $ffff
        lda #$35
        sta $01         // RAM under BASIC+KERNAL, I/O still visible
        cli
loop:
        jmp loop

irq1:
        pha
        txa
        pha
        tya
        pha
        ldx #$13
        stx scroly      // switch to 24 rows - opens bottom border
        ldx #$f6		// valid raster line values are 0-$f6 but also $fc-ff
        stx raster      // second irq at raster $fc
        ldx #<irq2
        stx $fffe
        ldx #>irq2
        stx $ffff
        ldx #$01
        stx vicirq      // ack irq
        lda ciaicr      // clear pending CIA interrupt
        pla
        tay
        pla
        tax
        pla
        rti

irq2:
        pha
        txa
        pha
        tya
        pha
        ldx #$1b
        stx scroly      // switch back to 25 rows - arms top border opening
        ldx #$fa		// valid values are $f8-$fa (248, 249, 250)
        stx raster      // back to first irq raster
        ldx #<irq1
        stx $fffe
        ldx #>irq1
        stx $ffff
        ldx #$01
        stx vicirq      // ack irq
        lda ciaicr      // clear pending CIA interrupt
        pla
        tay
        pla
        tax
        pla
        rti