.var SID_ENABLED = 0
SID_FRAMES_LEFT:  .word 5200	// This is for the SID tune Ark Pandora

.macro UpdateSidPlayerArkPandora() {
    .if (SID_ENABLED == 1) {
        jsr     $A007   // Play Ark Pandora
        lda SID_FRAMES_LEFT
        bne !+
        dec SID_FRAMES_LEFT+1
!:      dec SID_FRAMES_LEFT
        lda SID_FRAMES_LEFT
        ora SID_FRAMES_LEFT+1
        bne !+
        lda #$40
        sta SID_FRAMES_LEFT
        lda #$14
        sta SID_FRAMES_LEFT+1
        lda #$01
        jsr $b4c0       // Restart Ark Pandora tune
!:
    }
}

.macro InitSidPlayerArkPandora() {
    .if (SID_ENABLED == 1) {
        lda     #$01
        jsr     $b4c0   // Init the SID tune Ark Pandora
    }
}