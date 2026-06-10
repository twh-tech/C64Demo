CLEARSCREEN:
        lda     #$20
        ldx     #$00
!:      sta     $0400,x
        sta     $0500,x
        sta     $0600,x
        sta     $06e8,x
        inx
        bne     !-
        rts

CLEARCOLORRAM:
        lda     #$00
        ldx     #$00
!:      sta     $d800,x
        sta     $d900,x
        sta     $da00,x
        sta     $dae8,x
        inx
        bne     !-
        rts