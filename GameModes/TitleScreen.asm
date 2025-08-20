section union "Title screen RAM",wramx,align[8]
Title_BGTileBuffer:     ds  $800
Title_LogoBouncePtr:    dw
Title_MenuID:           db
Title_MenuPos:          db
Title_MenuMax:          db

section "Game options",hram
hOptionsFlags:      db
rsreset
def OPTION_MUSIC_B  rb
def OPTION_SFX_B    rb

def OPTIONS_MUSIC_ON    equ 1 << OPTION_MUSIC_B
def OPTIONS_MUSIC_OFF   equ 0 << OPTION_MUSIC_B
def OPTIONS_SFX_ON      equ 1 << OPTION_SFX_B
def OPTIONS_SFX_OFF     equ 0 << OPTION_SFX_B


section "Title screen routines",rom0
GM_Title:
    call    LCDOff
    call    ClearScreen
    call    InitPalBuffers
    ; decrunch background animation
    farload hl,GFX_TitleBG
    ld      de,Title_BGTileBuffer
    call    DecodeWLE
    ; ld      hl,GFX_TitleLogo
    ld      de,_VRAM+$1000
    call    DecodeWLE
    ; ld      hl,Map_TitleBG
    ld      de,_SCRN0
    call    DecodeWLE
    ld      a,1
    ldh     [rVBK],a
    ; ld      hl,Attr_TitleBG
    ld      de,_SCRN0
    call    DecodeWLE
    ld      hl,Pal_TitleBG
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
    ; ld      hl,Pal_TitleMenu
    ld      a,8
    call    LoadPal
    ; ld      hl,GFX_TitleMenu_StartGame
    ld      de,$8000
    call    DecodeWLE
    ; ld      hl,GFX_TitleMenu_Options
    call    DecodeWLE
    ; ld      hl,GFX_OptionsMenu_Music
    call    DecodeWLE
    ; ld      hl,GFX_OptionsMenu_SFX
    call    DecodeWLE
    ; ld      hl,GFX_OptionsMenu_Credits
    call    DecodeWLE
    ; ld      hl,GFX_OptionsMenu_OnOff
    call    DecodeWLE
    
    xor     a
    ldh     [rVBK],a
    ld      [Title_MenuID],a
    ld      [Title_MenuPos],a
    ld      [Title_MenuMax],a
    
    ld      a,low(Title_LogoBounceTable)
    ld      [Title_LogoBouncePtr],a
    ld      a,high(Title_LogoBounceTable)
    ld      [Title_LogoBouncePtr+1],a
    
    call    CopyPalettes
    call    UpdatePalettes
    call    PalFadeInBlack
    call    UpdatePalettes
    
    call    DeleteAllObjects
    
    call    DSFX_Init
    
    ; ld      a,bank(Mus_LostInTranslation)-1 ; TODO: Proper title screen music
    ; call    GBM_LoadModule    
    
    ; TODO: Remaining init stuff
    
    ld      a,low(IntS_Title)
    ldh     [hSTATPointer],a
    ld      a,high(IntS_Title)
    ldh     [hSTATPointer+1],a
    ld      a,STATF_MODE00
    ldh     [rSTAT],a
    
    ld      a,LCDCF_ON | LCDCF_BGON | LCDCF_BG8800 | LCDCF_OBJON | LCDCF_OBJ16
    ldh     [rLCDC],a
    ld      a,IEF_VBLANK | IEF_STAT
    ldh     [rIE],a
    ld      a,bank(TitleLoop)
    bankswitch_to_a
    jp      TitleLoop

IntS_Title:
    ldh     a,[rLY]
    cp      72
    ret     nc
    push    bc
    ld      b,a
    ldh     a,[hGlobalTick]
    push    af
    push    bc
    rra
    add     b
    and     $f
    add     a
    ld      l,a
    ld      h,high(Title_GoldTable)
    ld      a,$3c | BGPIF_AUTOINC
    ldh     [rBCPS],a
    
    ld      a,[hl+]
    ldh     [rBCPD],a
    ld      a,[hl+]
    ldh     [rBCPD],a
    pop     bc
    pop     af
    cpl
    rra
    add     b
    and     $f
    add     a
    ld      l,a
    
    ld      a,[hl+]
    ldh     [rBCPD],a
    ld      a,[hl+]
    ldh     [rBCPD],a

    pop     bc
    ret
    
section "Title screen loop",romx
TitleLoop:
    xor     a
    ldh     [hOAMPos],a
    ldh     a,[hGlobalTick]
    rra
    rra
    and     15
    ld      h,a
    ld      l,0
    srl     h
    rr      l
    ld      bc,Title_BGTileBuffer
    add     hl,bc
    
    ld      a,h
    ldh     [rHDMA1],a
    ld      a,l
    ldh     [rHDMA2],a
    ld      a,high(_VRAM+$800)
    ldh     [rHDMA3],a
    xor     a
    ldh     [rHDMA4],a
    rst     WaitForVBlank
    ld      a,7
    ld      [rHDMA5],a
    call    UpdatePalettes
    
    ld      hl,Title_LogoBouncePtr
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    ld      a,[hl+]
    cp      $80
    jr      z,:++
    cp      $7f
    call    z,Title_LogoLand
    ldh     [rSCY],a   
:   ld      a,l
    ld      [Title_LogoBouncePtr],a
    ld      a,h
    ld      [Title_LogoBouncePtr+1],a
    jr      :++
:   call    Pal_DoFade
:   call    GBM_Update
    call    DSFX_Update
    
    jr      TitleLoop

Title_LogoLand:
    push    hl
    ld      e,SFX_BIG_BUMP_CH2
    call    DSFX_PlaySound
    ld      e,SFX_BIG_BUMP_CH4
    call    DSFX_PlaySound
    pop     hl
    ld      a,[hl+]
    ret

Title_LogoBounceTable:
    db  112,112,112,112,112,112,112,112
    db  112,112,112,112,112,112,112,112
    db  112, 104, 96, 88, 80, 72
    db  64, 56, 48, 40, 32, 24, 16, 8, 0
    cp  $7f
    db  -8,  -2,   5,  -2,  -2,   3,  -1,  -2
    db   2,   0,  -2,   1,   0,  -1,   1,   1,  -1,   0
    db   1,  -1,   0,   1,  -1,   0,   1,   0,   0,   1
    db   0,   0,   1,   0,  -1,   0,   0,  -1,   0,   0
    db   0,   0,   0,   0,   0,   0,   0,   0,   0,   0
    db   0,   0,   0,   0,   0,   0,   0,   0,   0,   0
    db   0,   0,   0,   0
    db  $80





section "Title gold table",rom0,align[8]
Title_GoldTable:
    rgb8    223,198, 86
    rgb8    206,183, 74
    rgb8    190,168, 62
    rgb8    174,152, 49
    rgb8    158,137, 37
    rgb8    141,122, 25
    rgb8    125,107, 13
    rgb8    109, 92,  1
    rgb8    125,107, 13
    rgb8    141,122, 25
    rgb8    158,137, 37
    rgb8    174,152, 49
    rgb8    190,168, 62
    rgb8    206,183, 74
    rgb8    223,198, 86
    rgb8    239,213, 98

Title_OptionFlashTable:
    rgb8    $ff,$ff,$00
    rgb8    $ff,$ff,$22
    rgb8    $ff,$ff,$44
    rgb8    $ff,$ff,$66
    rgb8    $ff,$ff,$88
    rgb8    $ff,$ff,$aa
    rgb8    $ff,$ff,$cc
    rgb8    $ff,$ff,$ee
    rgb8    $ff,$ff,$ff
    rgb8    $ff,$ff,$ee
    rgb8    $ff,$ff,$cc
    rgb8    $ff,$ff,$aa
    rgb8    $ff,$ff,$88
    rgb8    $ff,$ff,$66
    rgb8    $ff,$ff,$44
    rgb8    $ff,$ff,$22

; ================================================================

section "Title screen GFX",romx
GFX_TitleBG:        incbin  "GFX/menubg.2bpp.wle"
GFX_TitleLogo:      incbin  "GFX/logo.2bpp.wle"
Map_TitleBG:        incbin  "GFX/menubg.map.wle"
Attr_TitleBG:       incbin  "GFX/menubg.atr.wle"

def r1 equ 0
def r2 equ 0
def r3 equ 0
def r4 equ 0
def g1 equ 0
def g2 equ 0
def g3 equ 0
def g4 equ 0
def b1 equ 0
def b2 equ 0
def b3 equ 0
def b4 equ 0

Pal_TitleBG:
    ; if I don't do it like this rgbasm complains about "value is not 16-bit" for no discernable reason
    for n,7
        redef r1 equ 0
        redef r2 equ 0
        redef r3 equ 0
        redef r4 equ 0
        redef g1 equ 40 + (0*(8-n))/2
        redef g2 equ 40 + (5*(8-n))/2
        redef g3 equ 40 + (10*(8-n))/2
        redef g4 equ 40 + (15*(8-n))/2
        redef b1 equ 80 + (0*(8-n))
        redef b2 equ 80 + (5*(8-n))
        redef b3 equ 80 + (10*(8-n))
        redef b4 equ 80 + (15*(8-n))
        rgb8 r1, g1, b1
        rgb8 r2, g2, b2
        rgb8 r3, g3, b3
        rgb8 r4, g4, b4
    endr
    purge r1, g1, b1, r2, g2, b2, r3, g3, b3, r4, g4, b4
    rgb      0, 0, 0
    rgb8     0,40,80
    rgb      0, 0,31
    rgb     31,31,31

Pal_TitleMenu:              incbin  "GFX/titlemenu.pal"
GFX_TitleMenu_StartGame:    incbin  "GFX/startgame.2bpp.wle"
GFX_TitleMenu_Options:      incbin  "GFX/options.2bpp.wle"
GFX_OptionsMenu_Music:      incbin  "GFX/music.2bpp.wle"
GFX_OptionsMenu_SFX:        incbin  "GFX/sfx.2bpp.wle"
GFX_OptionsMenu_Credits:    incbin  "GFX/credits.2bpp.wle"
GFX_OptionsMenu_OnOff:      incbin  "GFX/onoff.2bpp.wle"
