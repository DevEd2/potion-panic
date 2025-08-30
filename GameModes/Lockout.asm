section "Lockout trampoline",rom0
GM_Lockout:
    ld      a,bank(_GM_Lockout)
    bankswitch_to_a
    jp      _GM_Lockout

section "Lockout  routines",romx
_GM_Lockout:
    ld      b,b
:   ldh     a,[rLY]
    cp      $90
    jr      nz,:-
    xor     a
    ldh     [rLCDC],a
    di
    
    ld      hl,GFX_LockoutLogo
    ld      de,_VRAM
    call    DecodeWLE
    ld      de,_SCRN0
    lb      bc,SCRN_X_B,8
    call    LoadTilemap
    xor     a
    call    LoadPal
    call    CopyPalettes
    call    UpdatePalettes
    ld      a,%00011011
    ldh     [rBGP],a
    
    ldh     a,[hIsGBC]
    cp      $11
    jr      nz,.dmg
.emu
    ld      hl,GFX_EmuLockout
    jr      :+
.dmg
    ld      hl,GFX_DMGLockout
:   ld      de,_VRAM+$800
    call    DecodeWLE
    ld      de,_SCRN0 + (8 * 32)
    lb      bc,SCRN_X_B,SCRN_Y_B-8
    call    LoadTilemap    
        
    ld      a,LCDCF_ON | LCDCF_BGON | LCDCF_BLK01 | LCDCF_BG9800
    ldh     [rLCDC],a
    ld      a,IEF_VBLANK
    ldh     [rIE],a
    ei
    
LockoutLoop:
    rst     WaitForVBlank
    jr      LockoutLoop

GFX_LockoutLogo:    incbin  "GFX/logo_mono.2bpp.wle"
Map_LockoutLogo:    incbin  "GFX/logo_mono.map"
Pal_LockoutLogo:    incbin  "GFX/logo_mono.pal"

GFX_DMGLockout:     incbin  "GFX/dmglockout.2bpp.wle"
Map_DMGLockout:     incbin  "GFX/dmglockout.map"

GFX_EmuLockout:     incbin  "GFX/emulockout.2bpp.wle"
Map_EmuLockout:     incbin  "GFX/emulockout.map"