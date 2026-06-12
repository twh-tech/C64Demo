.macro BasicStub() {
        *=$0801 "Basic Stub"
        .byte   $0b,$08
        .byte   $0a,$00
        .byte   $9e
        .byte   $20
        .text   "2064"
        .byte   $00,$00,$00
}