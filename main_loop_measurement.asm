.label MEASUREMENT_START = $5000
.label MEASUREMENT_END   = $9fff

INIT_MEASUREMENT:
        lda #<MEASUREMENT_START
        sta MAINLOOP_PTR
        lda #>MEASUREMENT_START
        sta MAINLOOP_PTR+1
        lda #0
        sta MAINLOOP_COUNT
        tay
!:      sta (MAINLOOP_PTR),y
        iny
        bne !-
        inc MAINLOOP_PTR+1
        ldx MAINLOOP_PTR+1
        cpx #>MEASUREMENT_END+1
        bne !-
        // Reset pointer to start
        lda #<MEASUREMENT_START
        sta MAINLOOP_PTR
        lda #>MEASUREMENT_START
        sta MAINLOOP_PTR+1
        rts

.macro SaveMainloopMeasurement() {
        lda MAINLOOP_COUNT
        ldy #0
        sta (MAINLOOP_PTR),y

        // Advance pointer
        inc MAINLOOP_PTR
        bne !+
        inc MAINLOOP_PTR+1

        // Wrap around if we reached MEASUREMENT_END
!:      lda MAINLOOP_PTR+1
        cmp #>MEASUREMENT_END
        bne !+
        lda MAINLOOP_PTR
        cmp #<MEASUREMENT_END
        bne !+
        lda #<MEASUREMENT_START
        sta MAINLOOP_PTR
        lda #>MEASUREMENT_START
        sta MAINLOOP_PTR+1

!:      lda #0
        sta MAINLOOP_COUNT
}

