section "Copyright splash RAM",wram0
CopyrightSplashRAMStart:
Copyright_Timer:  dw
CopyrightSplashRAMEnd:

def COPYRIGHT_TIME equ   5 * 60

section "Copyright splash routines",romx
GM_Copyright:
    call    LCDOff
    di
    
    xor     a
    ldh     [rVBK],a
    ld      b,CopyrightSplashRAMEnd-CopyrightSplashRAMStart
    ld      hl,CopyrightSplashRAMStart
    call    MemFillSmall
    
    ; load gfx
    ld      hl,GFX_Copyright
    ld      de,_VRAM
    call    DecodeWLE
    ; ld      hl,Map_Copyright
    ld      de,_SCRN0
    lb      bc,SCRN_X_B,SCRN_Y_B
    call    LoadTilemapAttr
    ; ld      hl,Pal_Copyright
    xor     a
    call    LoadPal
    ; ld      a,1
    ; call    LoadPal
    ; ld      a,2
    ; call    LoadPal
    ; ld      a,3
    ; call    LoadPal
    ; ld      a,4
    ; call    LoadPal
    ; ld      a,5
    ; call    LoadPal
    ; ld      a,6
    ; call    LoadPal
    ; ld      a,7
    ; call    LoadPal
    call    PalFadeInWhite
    
    ld      a,low(COPYRIGHT_TIME)
    ld      [Copyright_Timer],a
    ld      a,high(COPYRIGHT_TIME)
    ld      [Copyright_Timer+1],a
    
    ld      a,LCDCF_ON | LCDCF_BGON | LCDCF_BLK01 | LCDCF_BG9800
    ldh     [rLCDC],a
    ld      a,IEF_VBLANK
    ldh     [rIE],a
    ei
    
CopyrightLoop:
    call    Pal_DoFade
    rst     WaitForVBlank
    call    UpdatePalettes
    
    ld      hl,Copyright_Timer
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
    
    jr      CopyrightLoop
    
:   call    PalFadeOutWhite
    ; fall through
:   call    Pal_DoFade
    rst     WaitForVBlank
    call    UpdatePalettes
    ld      a,[sys_FadeState]
    and     a
    jr      nz,:-
    jp      _GM_GBCompo25Splash

GFX_Copyright:  incbin  "GFX/copyright.2bpp.wle"
Map_Copyright:  incbin  "GFX/copyright.map"
Pal_Copyright:  incbin  "GFX/copyright.pal"