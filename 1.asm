BasicStub()

.label MAINLOOP_PTR    = $f7    // 2 bytes on zero page: $f7 (lo), $f8 (hi)

START:
		// This is for measuring how many cycles spent in MAINLOOP
		jsr		INIT_MEASUREMENT

        lda     #$35		
        sta     $01             // RAM under BASIC+KERNAL, I/O still visible

		InitSidPlayerArkPandora()

        jsr     SETUPSPRITES
        
        sei
        // Clear pending VIC IRQ flags
        lda     #$ff
        sta     VICIRQFLAG

        // VIC control: clear high raster bit, enable display
        lda     VICICR
        and     #$7f
        sta     VICICR
        lda     #DISPLAYON
        sta     VICICR

        // Disable CIA1 timer IRQ entirely
        lda     #$7f
        sta     $dc0d
        lda     $dc0d

        lda     #$7f
        sta     $dd0d       // disable all CIA2 NMI sources
        lda     $dd0d       // acknowledge any pending NMI

        lda     #<IRQ1
        sta     $fffe
        lda     #>IRQ1
        sta     $ffff

        lda     #<DUMMY_NMI
        sta     $fffa
        lda     #>DUMMY_NMI
        sta     $fffb

        // Enable VIC raster IRQ
        lda     #$01
        sta     VICIRQENABLE

		SetRasterStateTopActive()

		jsr		CLEARSCREEN
		jsr		CLEARCOLORRAM
		jsr		INITSCROLL
        cli

MAINLOOP:
        inc MAINLOOP_COUNT	// 6 cycles 
        jmp MAINLOOP		// 3 cycles

DUMMY_NMI:
        rti

RASTER_STATE:
        .byte RASTER_STATE_TOP_ACTIVE

* = $3FFF "Garbagebyte"
//.byte $55    // garbagebyte - must stay $00 for open border trick
.byte $00

SID_FRAMES_LEFT:  .word 5200
MAINLOOP_COUNT:   .byte 0

* = $5000 "Measurement buffer"
.fill $2000, 0

#import "print_address_labels.asm"
#import "helpers.asm"
#import "sprites.asm"
#import "raster_irq.asm"
#import "scroll_engine.asm"
#import "raster_bars.asm"        
#import "macros.asm"
#import "vic_registers.asm"
#import "main_loop_measurement.asm"
#import "sid_player.asm"
//* = $1800 "SID Player - Bombo"
//.import binary "bombo.sid", 126
//* = $a000
//.import binary "Ark_Pandora.sid", 126
//.import binary "all_spr/uridium.spr"