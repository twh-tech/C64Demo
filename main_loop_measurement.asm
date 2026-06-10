INIT_MEASUREMENT:
        lda #<$5000
        sta MAINLOOP_PTR
        lda #>$5000
        sta MAINLOOP_PTR+1
        lda #0
        sta MAINLOOP_COUNT
        rts

.macro SaveMainloopMeasurement() {
        lda MAINLOOP_COUNT
        ldy #0
        sta (MAINLOOP_PTR),y
        inc MAINLOOP_PTR
        bne !+
        inc MAINLOOP_PTR+1
!:      lda #0
        sta MAINLOOP_COUNT
}