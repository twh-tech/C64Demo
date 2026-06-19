// demo.asm

BasicStub()

.label MAINLOOP_PTR    = $f7    // 2 bytes on zero page: $f7 (lo), $f8 (hi)
* = $0810 "Start"
START:
		// This is for measuring how many cycles spent in MAINLOOP
		jsr		INIT_MEASUREMENT
		jsr		CLEARSCREEN
		jsr		CLEARCOLORRAM
		jsr		INITSCROLL
		
		// Bank switching: RAM visible at $A000-$BFFF and $E000-$FFFF
        // instead of BASIC ROM and KERNAL ROM.
        // I/O registers ($D000-$DFFF) remain visible.
		lda     #$35
        sta     $01

		InitSidPlayerArkPandora()

        jsr     SETUPSPRITES
        jsr		INIT_VIC_AND_IRQ

MAINLOOP:
        inc MAINLOOP_COUNT	// 6 cycles 
        jmp MAINLOOP		// 3 cycles

DUMMY_NMI:
        rti

RASTER_STATE:
        .byte RASTER_STATE_TOP_ACTIVE

* = $3FFF "Garbagebyte"
//.byte $55    // garbagebyte - must stay $00 for open border trick
.byte $55

MAINLOOP_COUNT:   .byte 0

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
#import "sprite_data.asm"
//* = $1800 "SID Player - Bombo"
//.import binary "bombo.sid", 126
//* = $a000
//.import binary "Ark_Pandora.sid", 126
//.import binary "all_spr/uridium.spr"