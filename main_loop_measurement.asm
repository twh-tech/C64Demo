.label MEASUREMENT_START = $5000
.label MEASUREMENT_END   = $9fff

INIT_MEASUREMENT:
        lda #<MEASUREMENT_START
        sta MAINLOOP_PTR
        lda #>MEASUREMENT_START
        sta MAINLOOP_PTR+1
        lda #0
        sta MAINLOOP_COUNT
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


* = MEASUREMENT_START "Measurement buffer"
.fill MEASUREMENT_END - MEASUREMENT_START + 1, 0