section "GBCompo25 splash RAM",wram0
GBCompo25SplashRAMStart:
GBCompo25_SplashTimer:  dw
GBCompo25SplashRAMEnd:

def GBCOMPO25_SPLASH_TIME equ   5 * 60

section "GBCompo25 splash trampoline",rom0
_GM_GBCompo25Splash:
    ld      a,bank(GM_GBCompo25Splash)
    bankswitch_to_a
    jp      GM_GBCompo25Splash

section "GBCompo25 splash routines",romx
GM_GBCompo25Splash:
    call    LCDOff
    di
    
    xor     a
    ldh     [rVBK],a
    ld      b,GBCompo25SplashRAMEnd-GBCompo25SplashRAMStart
    ld      hl,GBCompo25SplashRAMStart
    call    MemFillSmall
    
    ; load gfx
    ld      hl,GFX_GBCompo25
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
    
    ld      a,low(GBCOMPO25_SPLASH_TIME)
    ld      [GBCompo25_SplashTimer],a
    ld      a,high(GBCOMPO25_SPLASH_TIME)
    ld      [GBCompo25_SplashTimer+1],a
    
    ld      a,LCDCF_ON | LCDCF_BGON | LCDCF_BLK01 | LCDCF_BG9800
    ldh     [rLCDC],a
    ld      a,IEF_VBLANK
    ldh     [rIE],a
    ei
    
GBCompo25SplashLoop:
    call    Pal_DoFade
    rst     WaitForVBlank
    call    UpdatePalettes
    
    ld      hl,GBCompo25_SplashTimer
    ld      d,h
    ld      e,l
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    dec     hl
    ld      a,l
    or      h
    jr      z,:+
    ld      a,l
    ld      [de],a
    inc     de
    ld      a,h
    ld      [de],a
    
    ldh     a,[hPressedButtons]
    bit     BIT_START,a
    jr      nz,:+
    
    jr      GBCompo25SplashLoop
    
:   call    PalFadeOutBlack
    ; fall through
:   call    Pal_DoFade
    rst     WaitForVBlank
    call    UpdatePalettes
    ld      a,[sys_FadeState]
    and     a
    jr      nz,:-
    jp      GM_Title

GFX_GBCompo25:  incbin  "GFX/gbcompo25.2bpp.wle"
Map_GBCompo25:  incbin  "GFX/gbcompo25.map"
Pal_GBCompo25:  incbin  "GFX/gbcompo25.pal"