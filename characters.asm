* = $0801

.word next
.word 10
.byte $9e
.text "2064"
.byte 0
next: .word 0


* = $0810

.const SCREEN = $0400

start:
    lda #$1a
    sta $d018

    lda #0
    sta x
    sta row
    sta base


loop:

    lda base
    cmp #200
    bcs done

    lda x
    cmp #38
    bcc draw
    jmp newline


draw:

    lda row
    clc
    adc x
    tay

    lda base
    sta SCREEN,y

    clc
    adc #2
    sta SCREEN+1,y

    lda base
    clc
    adc #1
    sta SCREEN+40,y

    clc
    adc #2
    sta SCREEN+41,y

    lda base
    clc
    adc #4
    sta base

    lda x
    clc
    adc #2
    sta x

    jmp loop


newline:

    lda #0
    sta x

    lda row
    clc
    adc #80
    sta row

    jmp loop


done:
    jsr $ffcc
    rts


x:
    .byte 0

row:
    .byte 0

base:
    .byte 0


* = $2800
.var charset = LoadBinary("ace2char.bin", BF_C64FILE)
.fill charset.getSize(), charset.get(i)