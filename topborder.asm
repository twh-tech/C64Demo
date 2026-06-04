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
        ldx #<nearend
        stx $0314
        ldx #>nearend
        stx $0315       // set handler
        ldx #$1b
        stx scroly      // 25 rows
        ldx #$f9
        stx raster      // irq at raster $f9
        ldx #$00
        stx garbage     // clear garbage byte
        cli
        rts

nearend:
        ldx #$13
        stx scroly      // switch to 24 rows - opens bottom border
delay:
        inx
        bne delay       // waste time until we are past raster $fa
        ldx #$1b
        stx scroly      // switch back to 25 rows - arms top border opening
        ldx #$01
        stx vicirq      // ack irq
        jmp $ea31       // continue via KERNAL handler