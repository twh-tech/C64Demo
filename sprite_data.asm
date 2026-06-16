// ============================================================
// C64 Sprite Data: Digits 0-7
// ============================================================
// Each sprite is 24x21 pixels (single colour, hires mode).
// Pixels are inverted: solid white box with black digit cutout.
// Source: C64 character ROM digits, top 7 rows (row 8 blank, dropped).
// Scaled 3x horizontally (8->24 px) and 3x vertically (7->21 rows).
// Each block is 64 bytes: 63 bytes sprite data + 1 byte padding.
//
// Usage: point $07F8-$07FF (sprite pointers) at the right 64-byte
// block. If you place this at e.g. $3000, then:
//   sprite 0 pointer = $3000/64 = $C0
//   sprite 1 pointer = $3040/64 = $C1  ... etc.
//
// Visual preview (# = lit pixel, . = dark):
//
// Digit 0:              Digit 1:              Digit 2:
// ######....######      #########..#########  ######....######
// ###....######....###  ######.....#########  ###....######....###
// ###....###.......###  #########..#########  ###############....###
// ###.......###....###  (stem, 6px wide)      ############......######
// ###....######....###                        #########....#########
// ######....######      ###..................  ######....############
//                       ###..................  ###..................###
//
// (See full 21-row previews in the comment blocks below each sprite)
// ============================================================

// Align sprites to a 64-byte boundary in your code like:
//   .align 64
// or place this file at a known $xx00 address.
* = $0900 "Sprite data"
.align 64
SpriteData:
sprite_0:
    .byte $FC,$00,$3F
    .byte $FC,$00,$3F
    .byte $FC,$00,$3F
    .byte $E0,$7E,$07
    .byte $E0,$7E,$07
    .byte $E0,$7E,$07
    .byte $E0,$70,$07
    .byte $E0,$70,$07
    .byte $E0,$70,$07
    .byte $E0,$0E,$07
    .byte $E0,$0E,$07
    .byte $E0,$0E,$07
    .byte $E0,$7E,$07
    .byte $E0,$7E,$07
    .byte $E0,$7E,$07
    .byte $E0,$7E,$07
    .byte $E0,$7E,$07
    .byte $E0,$7E,$07
    .byte $FC,$00,$3F
    .byte $FC,$00,$3F
    .byte $FC,$00,$3F
    .byte $00           // padding

sprite_1:
    .byte $FF,$81,$FF
    .byte $FF,$81,$FF
    .byte $FF,$81,$FF
    .byte $FC,$01,$FF
    .byte $FC,$01,$FF
    .byte $FC,$01,$FF
    .byte $FF,$81,$FF
    .byte $FF,$81,$FF
    .byte $FF,$81,$FF
    .byte $FF,$81,$FF
    .byte $FF,$81,$FF
    .byte $FF,$81,$FF
    .byte $FF,$81,$FF
    .byte $FF,$81,$FF
    .byte $FF,$81,$FF
    .byte $FF,$81,$FF
    .byte $FF,$81,$FF
    .byte $FF,$81,$FF
    .byte $E0,$00,$07
    .byte $E0,$00,$07
    .byte $E0,$00,$07
    .byte $00           // padding

sprite_2:
    .byte $FC,$00,$3F
    .byte $FC,$00,$3F
    .byte $FC,$00,$3F
    .byte $E0,$7E,$07
    .byte $E0,$7E,$07
    .byte $E0,$7E,$07
    .byte $FF,$FE,$07
    .byte $FF,$FE,$07
    .byte $FF,$FE,$07
    .byte $FF,$F0,$3F
    .byte $FF,$F0,$3F
    .byte $FF,$F0,$3F
    .byte $FF,$81,$FF
    .byte $FF,$81,$FF
    .byte $FF,$81,$FF
    .byte $FC,$0F,$FF
    .byte $FC,$0F,$FF
    .byte $FC,$0F,$FF
    .byte $E0,$00,$07
    .byte $E0,$00,$07
    .byte $E0,$00,$07
    .byte $00           // padding

sprite_3:
    .byte $FC,$00,$3F
    .byte $FC,$00,$3F
    .byte $FC,$00,$3F
    .byte $E0,$7E,$07
    .byte $E0,$7E,$07
    .byte $E0,$7E,$07
    .byte $FF,$FE,$07
    .byte $FF,$FE,$07
    .byte $FF,$FE,$07
    .byte $FF,$80,$3F
    .byte $FF,$80,$3F
    .byte $FF,$80,$3F
    .byte $FF,$FE,$07
    .byte $FF,$FE,$07
    .byte $FF,$FE,$07
    .byte $E0,$7E,$07
    .byte $E0,$7E,$07
    .byte $E0,$7E,$07
    .byte $FC,$00,$3F
    .byte $FC,$00,$3F
    .byte $FC,$00,$3F
    .byte $00           // padding

sprite_4:
    .byte $FF,$FE,$07
    .byte $FF,$FE,$07
    .byte $FF,$FE,$07
    .byte $FF,$F0,$07
    .byte $FF,$F0,$07
    .byte $FF,$F0,$07
    .byte $FF,$80,$07
    .byte $FF,$80,$07
    .byte $FF,$80,$07
    .byte $E0,$7E,$07
    .byte $E0,$7E,$07
    .byte $E0,$7E,$07
    .byte $E0,$00,$00
    .byte $E0,$00,$00
    .byte $E0,$00,$00
    .byte $FF,$FE,$07
    .byte $FF,$FE,$07
    .byte $FF,$FE,$07
    .byte $FF,$FE,$07
    .byte $FF,$FE,$07
    .byte $FF,$FE,$07
    .byte $00           // padding

sprite_5:
    .byte $E0,$00,$07
    .byte $E0,$00,$07
    .byte $E0,$00,$07
    .byte $E0,$7F,$FF
    .byte $E0,$7F,$FF
    .byte $E0,$7F,$FF
    .byte $E0,$00,$3F
    .byte $E0,$00,$3F
    .byte $E0,$00,$3F
    .byte $FF,$FE,$07
    .byte $FF,$FE,$07
    .byte $FF,$FE,$07
    .byte $FF,$FE,$07
    .byte $FF,$FE,$07
    .byte $FF,$FE,$07
    .byte $E0,$7E,$07
    .byte $E0,$7E,$07
    .byte $E0,$7E,$07
    .byte $FC,$00,$3F
    .byte $FC,$00,$3F
    .byte $FC,$00,$3F
    .byte $00           // padding

sprite_6:
    .byte $FC,$00,$3F
    .byte $FC,$00,$3F
    .byte $FC,$00,$3F
    .byte $E0,$7E,$07
    .byte $E0,$7E,$07
    .byte $E0,$7E,$07
    .byte $E0,$7F,$FF
    .byte $E0,$7F,$FF
    .byte $E0,$7F,$FF
    .byte $E0,$00,$3F
    .byte $E0,$00,$3F
    .byte $E0,$00,$3F
    .byte $E0,$7E,$07
    .byte $E0,$7E,$07
    .byte $E0,$7E,$07
    .byte $E0,$7E,$07
    .byte $E0,$7E,$07
    .byte $E0,$7E,$07
    .byte $FC,$00,$3F
    .byte $FC,$00,$3F
    .byte $FC,$00,$3F
    .byte $00           // padding

sprite_7:
    .byte $E0,$00,$07
    .byte $E0,$00,$07
    .byte $E0,$00,$07
    .byte $E0,$7E,$07
    .byte $E0,$7E,$07
    .byte $E0,$7E,$07
    .byte $FF,$F0,$3F
    .byte $FF,$F0,$3F
    .byte $FF,$F0,$3F
    .byte $FF,$81,$FF
    .byte $FF,$81,$FF
    .byte $FF,$81,$FF
    .byte $FF,$81,$FF
    .byte $FF,$81,$FF
    .byte $FF,$81,$FF
    .byte $FF,$81,$FF
    .byte $FF,$81,$FF
    .byte $FF,$81,$FF
    .byte $FF,$81,$FF
    .byte $FF,$81,$FF
    .byte $FF,$81,$FF
    .byte $00           // padding