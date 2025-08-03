; =============================================================================
; Error handler    
; =============================================================================

section "Error handler memory",hram
hAF:        dw
hBC:        dw
hDE:        dw
hHL:        dw
hSP:        dw
hErrType:   db

section "Error handler routines",rom0
ErrorScreen:
    di
    ld      [hSP],sp
    ld      sp,hl
    ld      [hHL],sp
    ld      sp,$fffe
    push    af
    pop     hl
    ld      a,l
    ldh     [hAF],a
    ld      a,h
    ldh     [hAF+1],a
    ld      a,c
    ldh     [hBC],a
    ld      a,b
    ldh     [hBC+1],a
    ld      a,e
    ldh     [hDE],a
    ld      a,d
    ldh     [hDE+1],a
    ldh     a,[rLCDC]
    bit     LCDCB_ON,a
    jr      z,:++
:   ldh     a,[rLY]
    cp      SCRN_Y
    jr      nz,:-
    xor     a
    ldh     [rLCDC],a
:   ; clear VRAM
    ld      a,1
    ldh     [rVBK],a
    ld      hl,_VRAM
    ld      bc,_SRAM-_VRAM
    ld      e,0
    call    MemFill
    xor     a
    ldh     [rVBK],a
    ld      hl,_VRAM
    ld      bc,_SRAM-_VRAM
    ld      e,0
    call    MemFill
    
    ld      a,bank(Font)
    ld      [rROMB0],a
    ld      hl,Font
    ld      de,_VRAM
    ld      bc,Font.end-Font
    call    CopyTiles1BPP
        
    ld      hl,Font
    ld      de,_VRAM+$800
    ld      bc,Font.end-Font
    call    CopyTiles1BPPInverted
    
    ld      hl,_SCRN0
    ld      bc,_SCRN1-_SCRN0
    ld      e,0
    call    MemFill
        
    ld      de,_SCRN0+6
    ld      hl,str_ErrorHeader
    call    PrintStringInverted
    
    ld      a,[hErrType]
    cp      NUM_ERROR_STRINGS
    ld      hl,ErrorStrings.unknown
    jr      nc,:+

    ld      c,a
    ld      b,0
    ld      hl,ErrorStringPointers
    add     hl,bc
    add     hl,bc
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
:   ld      de,_SCRN0+$40
    call    PrintString    
    ld      hl,str_AF
    ld      de,_SCRN0+$81
    call    PrintString
    ld      de,_SCRN0+$8c
    call    PrintString
    ld      de,_SCRN0+$a1
    call    PrintString
    ld      de,_SCRN0+$ac
    call    PrintString
    ld      de,_SCRN0+$c1
    call    PrintString
    ld      de,_SCRN0+$cc
    call    PrintString
    ld      de,_SCRN0+$e1
    call    PrintString
    ld      de,_SCRN0+$ec
    call    PrintString
    
    ld      de,_SCRN0+$120
    call    PrintString
    
    ld      hl,_SCRN0+$144
    ld      bc,$20
    ld      [hl],":"-" "
    add     hl,bc
    ld      [hl],":"-" "
    add     hl,bc
    ld      [hl],":"-" "
    add     hl,bc
    ld      [hl],":"-" "
    add     hl,bc
    ld      [hl],":"-" "
    add     hl,bc
    ld      [hl],":"-" "
    add     hl,bc
    ld      [hl],":"-" "
    add     hl,bc
    ld      [hl],":"-" "
    
    ld      de,$9884
    ld      hl,hAF+1
    ld      a,[hl-]
    call    PrintHex
    ld      a,[hl]
    call    PrintHex
    ld      de,$988f
    ld      hl,hBC+1
    ld      a,[hl-]
    call    PrintHex
    ld      a,[hl]
    call    PrintHex
    
    ld      de,$98a4
    ld      hl,hDE+1
    ld      a,[hl-]
    call    PrintHex
    ld      a,[hl]
    call    PrintHex
    ld      de,$98af
    ld      hl,hHL+1
    ld      a,[hl-]
    call    PrintHex
    ld      a,[hl]
    call    PrintHex
    
    ld      de,$98c4
    ld      hl,hSP+1
    ld      a,[hl-]
    call    PrintHex
    ld      a,[hl]
    call    PrintHex
    ld      de,$98cf
    ldh     a,[rIE]
    call    PrintHex
    
    ld      de,$98e4
    ldh     a,[hROMB0]
    call    PrintHex
    ld      de,$98ef
    ldh     a,[hIsGBC]
    call    PrintHex
    ldh     a,[hIsGBA]
    call    PrintHex
    
    ld      hl,hSP
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    push    hl
    ld      de,$9940
    ld      b,8
:   push    bc
    push    de
    ld      a,h
    call    PrintHex
    ld      a,l
    call    PrintHex
    pop     de
    ld      a,e
    add     $20
    ld      e,a
    jr      nc,:+
    inc     d
:   ld      bc,6
    add     hl,bc
    pop     bc
    dec     b
    jr      nz,:--
    pop     hl
    di
    ld      sp,hl
    ld      b,8
    ld      de,$9946
.loop
    rept    3
        pop     hl
        ; calling PrintHex here trashes the stack so we need to inline it for both h and l
        ld      a,h
        swap    a
        and     $f
        cp      $a
        jr      nc,:+
        add     "0"-" "
        jr      :++
:       add     "A"-" "-$a
:       ld      [de],a
        inc     e
        ld      a,h
        and     $f
        cp      $a
        jr      nc,:+
        add     "0"-" "
        jr      :++
:       add     "A"-" "-$a
:       ld      [de],a
        inc     e
        ld      a,l
        swap    a
        and     $f
        cp      $a
        jr      nc,:+
        add     "0"-" "
        jr      :++
:       add     "A"-" "-$a
:       ld      [de],a
        inc     e
        ld      a,l
        and     $f
        cp      $a
        jr      nc,:+
        add     "0"-" "
        jr      :++
:       add     "A"-" "-$a
:       ld      [de],a
        inc     e
        inc     de ; advance one char
    endr
    ld      hl,(($9946 + (6 * 3))-$9946)-1
    add     hl,de
    ld      d,h
    ld      e,l
    dec     b
    jp      nz,.loop
    
    ld      sp,$fffe
    
    ; GBC palette
    ld      hl,Pal_DebugMenu
    ld      a,$80
    ldh     [rBCPS],a
    rept    8
    ld      a,[hl+]
    ldh     [rBCPD],a
    endr
    ; DMG palette (just in case)
    ld      a,%00011011
    ldh     [rBGP],a
    
    xor     a
    ldh     [rNR52],a

    ld      a,LCDCF_ON | LCDCF_BGON | LCDCF_BG8000
    ldh     [rLCDC],a
    
    xor     a
    ldh     [rSCX],a
    ldh     [rSCY],a
    
    ld      a,IEF_VBLANK
    ldh     [rIE],a
    ei
    
ErrLoop:
    halt
    jr      ErrLoop

str_ErrorHeader:        db  "=ERROR!=",0
str_AF:                 db  "AF=",0
str_BC:                 db  "BC=",0
str_DE:                 db  "DE=",0
str_HL:                 db  "HL=",0
str_SP:                 db  "SP=",0
str_IE:                 db  "IE=",0
str_RB:                 db  "RB=",0
str_Console:            db  "GB=",0
str_StackTrace:         db  "Stack trace:",0

rsreset
def ERR_TRAP                rb
def ERR_DIV_ZERO            rb
def ERR_JP_HL_OUTSIDE_ROM   rb
def ERR_MANUAL_TRIG         rb

ErrorStringPointers:
ErrorStrings:
    dw      .trap
    dw      .divbyzero
    dw      .jphloutsiderom
    dw      .manualtrig
def NUM_ERROR_STRINGS = (@ - ErrorStringPointers) / 2
    
.trap ;  ####################
    db  "RST $38 trap",0
.divbyzero
    db  "Division by zero",0
.jphloutsiderom
    db  "JP HL outside ROM",0
.manualtrig
    db  "Test crash",0
.unknown
    db  "Unknown error",0
    ;    ####################
    
