SETUPSPRITES:
        // Create a solid sprite at $3800
        // In VIC bank 0, sprite pointer value = $3800/64 = $e0
        lda     #$ff
        ldx     #0
!:
        sta     $3800,x
        inx
        cpx     #63
        bne     !-
        lda     #$00
        sta     $3840

        // Point sprite 0 to $3800
        lda     #$e0
        sta     $07f8
		sta     $07f9           // sprite 1 pointer
        sta     $07fa
		sta     $07fb           // sprite 1 pointer
        sta     $07fc
		sta     $07fd           // sprite 1 pointer
        sta     $07fe
		sta     $07ff           // sprite 1 pointer

        // Sprite color: light blue = $0e
        lda     #$01
        sta     $d027
        clc
		adc #1
        sta     $d028           // sprite 1 color        
        clc
		adc #1
        sta     $d029           // sprite 1 color        
        clc
		adc #1
        sta     $d02a           // sprite 1 color        
        clc
		adc #1
        sta     $d02b           // sprite 1 color        
        clc
		adc #1
        sta     $d02c           // sprite 1 color        
        clc
		adc #1
        sta     $d02d           // sprite 1 color        
        clc
		adc #1
        sta     $d02e           // sprite 1 color        

// X positions evenly distributed across screen
        lda     #24
        sta     $d000           // sprite 0 X = 24
        lda     #66
        sta     $d002           // sprite 1 X = 66
        lda     #108
        sta     $d004           // sprite 2 X = 108
        lda     #150
        sta     $d006           // sprite 3 X = 150
        lda     #192
        sta     $d008           // sprite 4 X = 192
        lda     #234
        sta     $d00a           // sprite 5 X = 234
        lda     #20             // 276 - 256 = 20
        sta     $d00c           // sprite 6 X low byte (full X = 276)
        lda     #62             // 318 - 256 = 62
        sta     $d00e           // sprite 7 X low byte (full X = 318)
        // Set MSB for sprites 6 and 7 (X >= 256)
        lda     #%11000000
        sta     $d010


        // Y position: straddling display/bottom border
        // Display ends around raster 250, sprite is 21 pixels tall
        // Y=241 puts it half in display half in border
        //lda		#$ff
        //lda		#$17
		lda		#$fc                
        sta     $d001
        sta     $d003  
        sta     $d005
        sta     $d007  
        lda		#$17
        sta     $d009
        sta     $d00b  
        sta     $d00d
        sta     $d00f  

        // Enable sprite 0
//        lda     #%11111111
        lda     #%00011000
        lda     #%00001000
        sta     $d015
		rts

MOVESPRITES:
        //inc     $d001
        //inc     $d003  
        //inc     $d005
        inc     $d007  
        dec     $d009
        //inc     $d00b  
        //inc     $d00d
        //inc     $d00f 
        rts
