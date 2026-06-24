// scroll_engine.asm
.label SCROLLROW       = 23
.label SCROLLRAM       = $0400 + SCROLLROW * 40
.label SCROLLRAM2      = $0400 + (SCROLLROW+1) * 40

        // -------------------------------------------------------
        // DOSCROLL
        // -------------------------------------------------------
* = * "Scroll engine"
DOSCROLL:
        lda     SCROLLX
        sec
        sbc     SCROLLSPEED
        bmi     NEEDCOARSELEFT
        cmp     #8
        bcs     NEEDCOARSERIGHT
        sta     SCROLLX
        jmp     WRITESCROLL

NEEDCOARSELEFT:
        clc
        adc     #8
        sta     SCROLLX
        jsr     COARSELEFT
        jmp     WRITESCROLL

NEEDCOARSERIGHT:
        sec
        sbc     #8
        sta     SCROLLX
        jsr     COARSERIGHT

WRITESCROLL:
        lda     VICXSCROLL
        and     #%11110000
        ora     SCROLLX
        sta     VICXSCROLL
        rts

        // -------------------------------------------------------
        // COARSELEFT
        // -------------------------------------------------------
COARSELEFT:
        inc     SCROLLBUFPTR

        lda     SCROLLBUFPTR
        clc
        adc     #39
        tay

        ldx     SCROLLCNT
        lda     SCROLLTEXT,x
        cmp     #$ff
        bne     GOTLEFT1
        ldx     #0
        lda     SCROLLTEXT,x
        ldx     #1
        stx     SCROLLCNT
        jmp     STORELEFT1
GOTLEFT1:
        inx
        stx     SCROLLCNT
STORELEFT1:
        sta     SCROLLBUF,y

        ldx     SCROLLCNT2
        lda     SCROLLTEXT2,x
        cmp     #$ff
        bne     GOTLEFT2
        ldx     #0
        lda     SCROLLTEXT2,x
        ldx     #1
        stx     SCROLLCNT2
        jmp     STORELEFT2
GOTLEFT2:
        inx
        stx     SCROLLCNT2
STORELEFT2:
        sta     SCROLLBUF2,y

        lda     SCROLLCNTL_RDY
        bne     ADVANCELEFT

        lda     SCROLLCNT
        cmp     #41
        bcc     SKIPCNTL
        lda     #1
        sta     SCROLLCNTL_RDY

ADVANCELEFT:
        ldx     SCROLLCNTL
        lda     SCROLLTEXT,x
        cmp     #$ff
        bne     ADVANCELEFT1
        ldx     #0
        stx     SCROLLCNTL
        jmp     ADVANCELEFT2
ADVANCELEFT1:
        inx
        stx     SCROLLCNTL
ADVANCELEFT2:
        ldx     SCROLLCNTL2
        lda     SCROLLTEXT2,x
        cmp     #$ff
        bne     ADVANCELEFT3
        ldx     #0
        stx     SCROLLCNTL2
        jmp     SKIPCNTL
ADVANCELEFT3:
        inx
        stx     SCROLLCNTL2

SKIPCNTL:
        ldx     SCROLLBUFPTR
        ldy     #0
COPYLEFT:
        lda     SCROLLBUF,x
        sta     SCROLLRAM,y
        lda     SCROLLBUF2,x
        sta     SCROLLRAM2,y
        inx
        iny
        cpy     #40
        bne     COPYLEFT
        rts

        // -------------------------------------------------------
        // COARSERIGHT
        // -------------------------------------------------------
COARSERIGHT:
        dec     SCROLLBUFPTR

        lda     SCROLLBUFPTR
        tay

        ldx     SCROLLCNTL
        dex
        cpx     #$ff
        bne     GOTRIGHT1
        ldx     #0
FINDEND1:
        lda     SCROLLTEXT,x
        cmp     #$ff
        beq     FOUNDEND1
        inx
        bne     FINDEND1
FOUNDEND1:
        dex
        cpx     #$ff
        bne     GOTRIGHT1
GOTRIGHT1:
        stx     SCROLLCNTL
        lda     SCROLLTEXT,x
        sta     SCROLLBUF,y

        ldx     SCROLLCNTL2
        dex
        cpx     #$ff
        bne     GOTRIGHT2
        ldx     #0
FINDEND2:
        lda     SCROLLTEXT2,x
        cmp     #$ff
        beq     FOUNDEND2
        inx
        bne     FINDEND2
FOUNDEND2:
        dex
        cpx     #$ff
        bne     GOTRIGHT2
GOTRIGHT2:
        stx     SCROLLCNTL2
        lda     SCROLLTEXT2,x
        sta     SCROLLBUF2,y

        ldx     SCROLLBUFPTR
        ldy     #0
COPYRIGHT:
        lda     SCROLLBUF,x
        sta     SCROLLRAM,y
        lda     SCROLLBUF2,x
        sta     SCROLLRAM2,y
        inx
        iny
        cpy     #40
        bne     COPYRIGHT
        rts

        // -------------------------------------------------------
        // UPDATESPEED
        // -------------------------------------------------------
UPDATESPEED:
        inc     SPEEDDELAY
        lda     SPEEDDELAY
        cmp     #6
        bne     SPEEDDONE
        lda     #0
        sta     SPEEDDELAY
        ldx     SPEEDIDX
        lda     SPEEDTABLE,x
        sta     SCROLLSPEED
        inx
        cpx     #SPEEDTABLE_SIZE
        bne     SAVEIDX
        ldx     #0
SAVEIDX:
        stx     SPEEDIDX

        lda     SCROLLSPEED
        bmi     SPEED_IS_NEG

        lda     SCROLLSIGN
        beq     SPEEDDONE
        lda     #0
        sta     SCROLLSIGN
        jsr     ALIGNFORRIGHT
        jmp     SPEEDDONE

SPEED_IS_NEG:
        lda     SCROLLSIGN
        bne     SPEEDDONE
        lda     #1
        sta     SCROLLSIGN
        jsr     ALIGNFORLEFT

SPEEDDONE:
        rts

        // -------------------------------------------------------
        // ALIGNFORLEFT
        // -------------------------------------------------------
ALIGNFORLEFT:
        lda     SCROLLCNT
        sec
        sbc     #40
        bcs     ALIGNFORLEFT_STORE
        clc
        adc     #<TEXTLENGTH
ALIGNFORLEFT_STORE:
        sta     SCROLLCNTL
        sta     SCROLLCNTL2
        rts

        // -------------------------------------------------------
        // ALIGNFORRIGHT
        // -------------------------------------------------------
ALIGNFORRIGHT:
        lda     SCROLLCNTL
        clc
        adc     #40
        tax
        cpx     #<TEXTLENGTH
        bcc     ALIGNFORRIGHT_STORE
        txa
        sec
        sbc     #<TEXTLENGTH
        tax
ALIGNFORRIGHT_STORE:
        stx     SCROLLCNT
        stx     SCROLLCNT2
        rts

        // -------------------------------------------------------
        // Variables
        // -------------------------------------------------------
SCROLLSPEED:
        .byte 1
SCROLLX:
        .byte 7
SCROLLCNT:
        .byte 0
SCROLLCNT2:
        .byte 0
SCROLLCNTL:
        .byte 0
SCROLLCNTL2:
        .byte 0
SCROLLCNTL_RDY:
        .byte 0
SCROLLBUFPTR:
        .byte 0
SCROLLSIGN:
        .byte 0
SPEEDIDX:
        .byte 0
SPEEDDELAY:
        .byte 0
DBG_CNTL:
        .byte 0
DBG_BUFPTR:
        .byte 0
DBG_CNT:
        .byte 0

.align 256
SCROLLTEXT:
        .import binary "scroll_top.bin"
        .byte $ff
.label TEXTLENGTH = * - SCROLLTEXT - 1

.align 256
SCROLLTEXT2:
        .import binary "scroll_bot.bin"
        .byte $ff

.align 256
SCROLLBND:
        .import binary "scroll_bnd.bin"
        .byte $ff

SPEEDTABLE:
        .byte 1,1,1,2,2,2,3,3,3,4,4,4,5,5,5
        .fill 30, 5
        .byte 4,4,4,3,3,3,2,2,2,1,1,1,0,0,0
        .byte $ff,$ff,$ff,$fe,$fe,$fe,$fd,$fd,$fd,$fc,$fc,$fc,$fb,$fb,$fb
        .fill 10, $fb
        .byte $fc,$fc,$fc,$fd,$fd,$fd,$fe,$fe,$fe,$ff,$ff,$ff,0,0,0
.label SPEEDTABLE_END = *
.label SPEEDTABLE_SIZE = SPEEDTABLE_END - SPEEDTABLE

INITSCROLL:
        // Fill scroll screen rows with spaces
        lda     #$20
        ldx     #39
!:      sta     SCROLLRAM,x
        sta     SCROLLRAM2,x
        dex
        bpl     !-

		// Color of top scroll line
        lda     #$0c            // medium gray
        ldx     #39
!:      sta     $d800 + SCROLLROW * 40,x
        dex
        bpl     !-

		// Color of bottom scroll line
        lda     #$0b            // dark gray
        ldx     #39
!:      sta     $d800 + (SCROLLROW+1) * 40,x
        dex
        bpl     !-

        // Set fine scroll to 7, 38 column mode (bit 3 = 0)
        lda     VICXSCROLL
        and     #%11110000
        ora     #7
        sta     VICXSCROLL

        // Init scroll variables
        lda     #0
        sta     SCROLLCNT
        sta     SCROLLCNT2
        sta     SCROLLCNTL
        sta     SCROLLCNTL2
        sta     SCROLLCNTL_RDY
        sta     SCROLLBUFPTR
        sta     SCROLLSIGN          // start scrolling left
        lda     #7
        sta     SCROLLX

        // Point VIC to charset at $2800
        lda     #%00011010
        sta     VICMEMCTRL
        rts

* = $2800 "Character set"
.var charset = LoadBinary("ace2char.bin", BF_C64FILE)
.fill charset.getSize(), charset.get(i)

* = $3000 "SCROLLBUF"
SCROLLBUF:
        .fill 256, $20

* = $3100 "SCROLLBUF2"
SCROLLBUF2:
        .fill 256, $20