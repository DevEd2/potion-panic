section "Credits splash RAM",wram0
CreditsRAMStart:
Credits_CurrentSlide:   db
CreditsRAMEnd:

section "Credits trampoline",rom0
_GM_Credits:
    ld      a,bank(GM_Credits)
    bankswitch_to_a
    jp      GM_Credits

section "Credits routines",romx
GM_Credits:
    call    LCDOff
    di
    
    xor     a
    ldh     [rVBK],a
    ld      b,CreditsRAMEnd-CreditsRAMStart
    ld      hl,CreditsRAMStart
    call    MemFillSmall
    
    ; load gfx
    ld      hl,GFX_EndOfDemo
    ld      de,_VRAM
    call    DecodeWLE
    ; ld      hl,Map_GBCompo25
    ld      de,_SCRN0
    lb      bc,SCRN_X_B,SCRN_Y_B
    call    LoadTilemapAttr
    ; ld      hl,Pal_GBCompo25
    xor     a
    call    LoadPal
    ld      a,1
    call    LoadPal
    ld      a,2
    call    LoadPal
    ld      a,3
    call    LoadPal
    ld      a,4
    call    LoadPal
    ld      a,5
    call    LoadPal
    ld      a,6
    call    LoadPal
    ld      a,7
    call    LoadPal
    call    PalFadeInWhite
    
    ld      a,LCDCF_ON | LCDCF_BGON | LCDCF_BLK01 | LCDCF_BG9800
    ldh     [rLCDC],a
    ld      a,IEF_VBLANK
    ldh     [rIE],a
    ei
    
CreditsLoop:
    call    Pal_DoFade
    rst     WaitForVBlank
    call    UpdatePalettes
    
    ldh     a,[hPressedButtons]
    and     BTN_A | BTN_START
    jr      z,CreditsLoop
    call    PalFadeOutWhite
:   call    Pal_DoFade
    rst     WaitForVBlank
    call    UpdatePalettes
    ld      a,[sys_FadeState]
    and     a
    jr      nz,:-
    call    LCDOff
    xor     a
    ldh     [rVBK],a
    ld      a,[Credits_CurrentSlide]
    cp      NUM_CREDITS_SLIDES
    jr      z,.reset
    ld      b,a
    add     a
    ld      l,a
    ld      h,0
    ld      de,CreditsScreens
    add     hl,de
    ld      a,b
    inc     a
    ld      [Credits_CurrentSlide],a
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    ld      de,_VRAM
    call    DecodeWLE
    ld      de,_SCRN0
    lb      bc,SCRN_X_B,SCRN_Y_B
    call    LoadTilemapAttr
    xor     a
    call    LoadPal
    ld      a,1
    call    LoadPal
    ld      a,2
    call    LoadPal
    ld      a,3
    call    LoadPal
    ld      a,4
    call    LoadPal
    ld      a,5
    call    LoadPal
    ld      a,6
    call    LoadPal
    ld      a,7
    call    LoadPal
    call    PalFadeInWhite
    
    ld      a,LCDCF_ON | LCDCF_BGON | LCDCF_BLK01 | LCDCF_BG9800
    ldh     [rLCDC],a
    ld      a,IEF_VBLANK
    ldh     [rIE],a
    ei
    jr      CreditsLoop

.reset
    ldh     a,[hIsGBA]
    ld      b,a
    ldh     a,[hIsGBC]
    jp      ProgramStart

CreditsScreens:
    dw      GFX_Credits1
    dw      GFX_Credits2
    dw      GFX_Credits3
    dw      GFX_Credits4
def NUM_CREDITS_SLIDES = (@ - CreditsScreens) / 2

GFX_EndOfDemo:  incbin  "GFX/endofdemo.2bpp.wle"
Map_EndOfDemo:  incbin  "GFX/endofdemo.map"
Pal_EndOfDemo:  incbin  "GFX/endofdemo.pal"

GFX_Credits1:   incbin  "GFX/credits1.2bpp.wle"
Map_Credits1:   incbin  "GFX/credits1.map"
Pal_Credits1:   incbin  "GFX/credits1.pal"

GFX_Credits2:   incbin  "GFX/credits2.2bpp.wle"
Map_Credits2:   incbin  "GFX/credits2.map"
Pal_Credits2:   incbin  "GFX/credits2.pal"

GFX_Credits3:   incbin  "GFX/credits3.2bpp.wle"
Map_Credits3:   incbin  "GFX/credits3.map"
Pal_Credits3:   incbin  "GFX/credits3.pal"

GFX_Credits4:   incbin  "GFX/credits4.2bpp.wle"
Map_Credits4:   incbin  "GFX/credits4.map"
Pal_Credits4:   incbin  "GFX/credits4.pal"