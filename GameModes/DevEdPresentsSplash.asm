section "DevEdPresents splash RAM",wram0
DevEdPresentsSplashRAMStart:
DevEdPresents_SplashTimer:  dw
DevEdPresentsSplashRAMEnd:

def DEVED_SPLASH_SPLASH_TIME equ   5 seconds

section "DevEdPresents splash trampoline",rom0
_GM_DevEdPresentsSplash:
    ld      a,bank(GM_DevEdPresentsSplash)
    bankswitch_to_a
    jp      GM_DevEdPresentsSplash

section "DevEdPresents splash routines",romx
GM_DevEdPresentsSplash:
    call    LCDOff
    di
    
    xor     a
    ldh     [rVBK],a
    ld      b,DevEdPresentsSplashRAMEnd-DevEdPresentsSplashRAMStart
    ld      hl,DevEdPresentsSplashRAMStart
    call    MemFillSmall
    
    ; load gfx
    ld      hl,GFX_DevEdPresents
    ld      de,_VRAM
    call    DecodeWLE
    ; ld      hl,Map_DevEdPresents
    ld      de,_SCRN0
    lb      bc,SCRN_X_B,SCRN_Y_B
    call    LoadTilemapAttr
    ; ld      hl,Pal_DevEdPresents
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
    
    ld      a,low(DEVED_SPLASH_SPLASH_TIME)
    ld      [DevEdPresents_SplashTimer],a
    ld      a,high(DEVED_SPLASH_SPLASH_TIME)
    ld      [DevEdPresents_SplashTimer+1],a
    
    ld      a,LCDCF_ON | LCDCF_BGON | LCDCF_BLK01 | LCDCF_BG9800
    ldh     [rLCDC],a
    ld      a,IEF_VBLANK
    ldh     [rIE],a
    ei
    
DevEdPresentsSplashLoop:
    call    Pal_DoFade
    rst     WaitForVBlank
    call    UpdatePalettes
    
    ld      hl,DevEdPresents_SplashTimer
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
    
    jr      DevEdPresentsSplashLoop
    
:   call    PalFadeOutBlack
    ; fall through
:   call    Pal_DoFade
    rst     WaitForVBlank
    call    UpdatePalettes
    ld      a,[sys_FadeState]
    and     a
    jr      nz,:-
    jp      GM_Title

GFX_DevEdPresents:  incbin  "GFX/DevEdPresents.2bpp.wle"
Map_DevEdPresents:  incbin  "GFX/DevEdPresents.map"
Pal_DevEdPresents:  incbin  "GFX/DevEdPresents.pal"