section union "Title screen RAM",wramx,align[8]
Title_BGTileBuffer:     ds  $800
Title_LogoBouncePtr:    dw
Title_MenuPtr:          dw
Title_MenuPos:          db
Title_MenuMax:          db
Title_MenuItemPos1:     db
Title_MenuItemPos2:     db
Title_MenuItemPos3:     db
Title_MenuSlideDir:     db
Title_EnableMenu:       db
Title_LogoYPos:         db

section "Game options",hram
hOptionsFlags:      db
rsreset
def OPTION_MUSIC_B  rb
def OPTION_SFX_B    rb

def OPTIONS_MUSIC_ON    equ 1 << OPTION_MUSIC_B
def OPTIONS_MUSIC_OFF   equ 0 << OPTION_MUSIC_B
def OPTIONS_SFX_ON      equ 1 << OPTION_SFX_B
def OPTIONS_SFX_OFF     equ 0 << OPTION_SFX_B

def MENU_ITEM_1_MOVE_DELAY  equ 0
def MENU_ITEM_2_MOVE_DELAY  equ 8
def MENU_ITEM_3_MOVE_DELAY  equ 16

rsreset
def MENU_DIR_NONE   rb  ; denotes unused menu option
def MENU_DIR_UP     rb  ; for menu options that do not have an on/off toggle
def MENU_DIR_LR     rb  ; for menu options that have an on/off toggle

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
    ld      [Title_MenuPos],a
    ld      [Title_MenuMax],a
    ld      [Title_MenuSlideDir],a
    ld      [Title_EnableMenu],a
    ld      [Title_LogoYPos],a
    ld      [Title_MenuItemPos1],a
    ld      a,-MENU_ITEM_2_MOVE_DELAY
    ld      [Title_MenuItemPos2],a
    ld      a,-MENU_ITEM_3_MOVE_DELAY
    ld      [Title_MenuItemPos3],a
    
    ld      a,low(Title_Menu_Main)
    ld      [Title_MenuPtr],a
    ld      a,high(Title_Menu_Main)
    ld      [Title_MenuPtr+1],a
    
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
    cp      63
    jr      nc,:+
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
    ld      a,[Title_LogoYPos]
    ldh     [rSCY],a

    pop     bc
    ret
:   ld      a,(SCRN_Y+8) -64
    ldh     [rSCY],a
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
    call    Title_UpdateMenu
    ld      a,[Title_EnableMenu]
    and     a
    jr      z,.skipmenu
    cp      2
    jr      z,.skipmenu
    ldh     a,[hPressedButtons]
    and     BTN_START | BTN_A
    jr      z,:+
    ld      a,-MENU_ITEM_3_MOVE_DELAY
    ld      [Title_MenuItemPos1],a
    ld      a,-MENU_ITEM_2_MOVE_DELAY
    ld      [Title_MenuItemPos2],a
    xor     a
    ld      [Title_MenuItemPos3],a
    inc     a
    ld      [Title_MenuSlideDir],a
    ld      e,SFX_MENU_SELECT_CH2
    call    DSFX_PlaySound
    ld      e,SFX_MENU_SELECT_CH1
    call    DSFX_PlaySound
    ld      a,low(Title_LogoSlideOutTable)
    ld      [Title_LogoBouncePtr],a
    ld      a,high(Title_LogoSlideOutTable)
    ld      [Title_LogoBouncePtr+1],a
    ld      a,2
    ld      [Title_EnableMenu],a
    jr      :++
:   ldh     a,[hPressedButtons]
    and     BTN_UP | BTN_DOWN | BTN_SELECT
    jr      z,.skipmenu
    ld      a,[Title_MenuPos]
    xor     1
    ld      [Title_MenuPos],a
    ld      e,SFX_MENU_CURSOR
    call    DSFX_PlaySound
.skipmenu
:   rst     WaitForVBlank
    ld      a,7
    ld      [rHDMA5],a
:   call    UpdatePalettes
    
    ld      a,[Title_EnableMenu]
    cp      2
    jr      z,:++
    ld      hl,Title_LogoBouncePtr
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    ld      a,[hl+]
    cp      $80
    jr      z,:++
    cp      $7f
    call    z,Title_LogoLand
    ld      [Title_LogoYPos],a
:   ld      a,l
    ld      [Title_LogoBouncePtr],a
    ld      a,h
    ld      [Title_LogoBouncePtr+1],a
    jr      :++
:   call    Pal_DoFade
:   call    GBM_Update
    call    DSFX_Update    
    jp      TitleLoop

Title_UpdateMenu:
    ld      a,[Title_EnableMenu]
    cp      2
    jr      z,:+
    ld      a,[sys_FadeState]
    and     a
    ret     nz
    jr      .skip
:   ld      hl,Title_LogoBouncePtr
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    ld      a,[hl+]
    cp      $80
    jr      z,:+
    ld      [Title_LogoYPos],a
    ld      a,l
    ld      [Title_LogoBouncePtr],a
    ld      a,h
    ld      [Title_LogoBouncePtr+1],a
:   ld      a,[Title_MenuItemPos1]
    cp      20
    jr      nz,.skip
    ld      a,[sys_FadeState]
    and     a
    jr      z,Title_ExecuteMenuItem
    ret
.skip
    ld      hl,Title_MenuItemPos1
    lb      bc,3,0
.loop
    ld      a,[hl]
    bit     7,a
    jr      z,:+
    xor     a
:   ld      e,a
    ld      d,0
    ld      a,[Title_MenuSlideDir]
    and     a
    push    hl
    ld      hl,Title_MenuItemScrollInTable
    jr      z,:+
    ld      hl,Title_MenuItemScrollOutTable
:   add     hl,de
    ld      a,[hl]
    cp      $80
    jr      nz,:+
    inc     hl
    ld      a,[hl-]
    push    bc
    call    Title_DrawMenuItem
    pop     bc
    pop     hl
    inc     hl
    inc     c
    dec     b
    jr      nz,.loop
    ld      hl,Title_EnableMenu
    ld      a,[hl]
    cp      2
    jr      z,:++
    ld      [hl],1
    ret
:   push    bc
    call    Title_DrawMenuItem
    pop     bc
    pop     hl
    inc     [hl]
    inc     hl
    inc     c
    dec     b
    jr      nz,.loop
    ret
:   ld      a,[Title_MenuItemPos1]
    cp      20
    ret     nz
    ld      a,[sys_FadeState]
    and     a
    jr      nz,Title_ExecuteMenuItem
    ld      a,low(IntS_Dummy)
    ldh     [hSTATPointer],a
    ld      a,high(IntS_Dummy)
    ldh     [hSTATPointer+1],a
    ld      a,(SCRN_VY-24)-SCRN_Y
    ldh     [rSCY],a
    jp      PalFadeOutWhite

Title_ExecuteMenuItem:
    ld      a,[Title_MenuPos]
    and     7
    rla
    rla
    rla
    ld      e,a
    ld      d,0
    ld      hl,Title_MenuPtr
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    add     hl,de
    ld      de,5
    add     hl,de
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    rst     CallHL
    ret

Title_DrawMenuItem:
    ldh     [hTemp1],a
    ld      a,c
    and     3
    rla
    rla
    rla
    ld      e,a
    ld      d,0
    ld      hl,Title_MenuPtr
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    add     hl,de
    ld      a,[hl+]
    and     a   ; MENU_DIR_NONE
    ret     z
    ; dec     a   ; MENU_DIR_UP
    ; jr      nz,.slidelr
    ; fall through
.slideup
    ld      a,[Title_MenuPos]
    cp      c
    call    .getpointer
    ldh     a,[hOAMPos]
    ld      e,a
    ld      d,high(OAMBuffer)
:   ld      a,[hl+]
    cp      -1
    jr      z,:+
    ld      b,a
    ldh     a,[hTemp1]
    add     b
    ld      [de],a
    inc     e
    rept    3
        ld      a,[hl+]
        ld      [de],a
        inc     e
    endr
    jr      :-
:   ld      a,e
    ldh     [hOAMPos],a
    ret
;.slidelr
;    ld      a,[Title_MenuPos]
;    cp      c
;    call    .getpointer
;    ldh     a,[hOAMPos]
;    ld      e,a
;    ld      d,high(OAMBuffer)
;:   ld      a,[hl+]
;    cp      -1
;    jr      z,:+
;    ld      [de],a
;    inc     e
;    ldh     a,[hTemp1]
;    sub     [hl]
;    ld      [de],a
;    inc     e
;    rept    2
;        ld      a,[hl+]
;        ld      [de],a
;        inc     e
;    endr
;    jr      :-
;:   ld      hl,hTempPtr1
;    ld      a,[hl+]
;    ld      h,[hl]
;    ld      l,a
;    ld      a,[Title_MenuPos]
;    cp      c
;    call    .getpointer
;    ldh     a,[hOAMPos]
;    ld      e,a
;    ld      d,high(OAMBuffer)
;:   ld      a,[hl+]
;    cp      -1
;    jr      z,:+
;    ld      [de],a
;    inc     e
;    ldh     a,[hTemp1]
;    add     [hl]
;    ld      [de],a
;    inc     e
;    rept    2
;        ld      a,[hl+]
;        ld      [de],a
;        inc     e
;    endr
;    jr      :-
;:   ld      a,e
;    ldh     [hOAMPos],a
;    ret
.getpointer
    jr      nz,.unselected
.selected
    ld      a,[hl+]
    ld      d,[hl]
    ld      e,a
    inc     hl
    inc     hl
    inc     hl
    ld      a,l
    ldh     [hTempPtr1],a
    ld      a,h
    ldh     [hTempPtr1+1],a
    ld      h,d
    ld      l,e
    ret
.unselected
    inc     hl
    inc     hl
    ld      a,[hl+]
    ld      d,[hl]
    ld      e,a
    inc     hl
    ld      a,l
    ldh     [hTempPtr1],a
    ld      a,h
    ldh     [hTempPtr1+1],a
    ld      h,d
    ld      l,e
    ret    

Title_StartGame:
    rst     WaitForVBlank
    xor     a
    ldh     [rLCDC],a
    ld      a,1
    ld      [Level_ID],a
    jp      GM_Level
    jr      @

Title_GotoOptionsMenu:
    ; TODO
    jr      @

Title_ToggleMusic:
    ; TODO
    jr      @

Title_ToggleSFX:
    ; TODO
    jr      @

Title_GotoCredits:
    ; TODO
    jr      @

Title_DummyOption:
    ; TODO
    ret

macro menu_entry
    db  \1  ; appear/disappear animation (or dummy if zero)
    dw  \2  ; selected OAM pointer
    dw  \3  ; unselected OAM pointer
;    dw  \4  ; on selected OAM pointer
;    dw  \5  ; on unselected OAM pointer
;    dw  \6  ; off selected OAM pointer
;    dw  \7  ; off unselected OAM pointer
    dw  \4  ; selection routine pointer
    db  0   ; padding
endm

Title_Menu_Main:
    menu_entry  MENU_DIR_UP,   Title_StartGameSelectedOAM, Title_StartGameUnselectedOAM, Title_StartGame
    menu_entry  MENU_DIR_UP,     Title_OptionsSelectedOAM,   Title_OptionsUnselectedOAM, Title_GotoOptionsMenu
    menu_entry  MENU_DIR_NONE,             Title_DummyOAM,               Title_DummyOAM, Title_DummyOption

;Title_Menu_Options:
;    menu_entry  MENU_DIR_LR,   Title_MusicSelectedOAM,   Title_MusicUnselectedOAM, Title_MusicOnSelectedOAM, Title_MusicOnUnselectedOAM, Title_MusicOffSelectedOAM, Title_MusicOffUnselectedOAM, Title_ToggleMusic
;    menu_entry  MENU_DIR_LR,     Title_SFXSelectedOAM,     Title_SFXUnselectedOAM,   Title_SFXOnSelectedOAM,   Title_SFXOnUnselectedOAM,   Title_SFXOffSelectedOAM,   Title_SFXOffUnselectedOAM, Title_ToggleSFX
;    menu_entry  MENU_DIR_UP, Title_CreditsSelectedOAM, Title_CreditsUnselectedOAM,           Title_DummyOAM,             Title_DummyOAM,            Title_DummyOAM,              Title_DummyOAM, Title_GotoCredits

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
    db  $7f
    db   -4,-4, 3, 3,-3,-2, 2, 2,-2,-2, 2, 2,-1,-1, 1, 1,-1,-1, 1, 1,-1,-1, 1, 1,-1,-1
    db   0, 0, 0, 0, 0, 0, 0, 0
    db   0, 0, 0, 0, 0, 0, 0, 0
    db   0, 0, 0, 0, 0, 0, 0, 0
    db  $80

Title_LogoSlideOutTable:
    db    1
    db    1,     2,     4,     6,     7,    10,    12
    db   15,    18,    22,    25,    29,    33,    37
    db   42,    47,    52,    57,    62,    64
    db  $80

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

Title_MenuItemScrollInTable:
    db      127,121,115,108,101, 95, 88, 82, 76, 70, 64, 58, 53, 47, 42, 37
    db       33, 29, 24, 21, 17, 14, 11,  9,  6,  4,  3,  2,  1,  0,  0,  0
    db      $80,0
Title_MenuItemScrollOutTable:
    db         0, 0,  1,  2,  3,  4,  6,  9, 11, 14, 17, 21, 24, 29, 33, 37
    db       42, 47, 53, 58, 64, 70, 76, 82, 88, 95,101,108,115,121,127,127
    db      $80,127

Title_DummyOAM:
    db      -1

Title_StartGameSelectedOAM:
    for n,10
        oam_entry    92, 40+(n*8), $00+(n*2), OAMF_BANK1
    endr
    db      -1
Title_StartGameUnselectedOAM:
    for n,10
        oam_entry    92, 40+(n*8), $14+(n*2), OAMF_BANK1
    endr
    db      -1

Title_OptionsSelectedOAM:
    for n,8
        oam_entry   115, 48+(n*8), $28+(n*2), OAMF_BANK1
    endr
    db      -1
Title_OptionsUnselectedOAM:
    for n,8
        oam_entry   115, 48+(n*8), $38+(n*2), OAMF_BANK1
    endr
    db      -1

Title_MusicSelectedOAM:
    for n,5
        oam_entry    72, 16+(n*8), $48+(n*2), OAMF_BANK1
    endr
    db      -1
Title_MusicUnselectedOAM:
    for n,5
        oam_entry    72, 16+(n*8), $52+(n*2), OAMF_BANK1
    endr
    db      -1
Title_MusicOnSelectedOAM:
    for n,3
        oam_entry    72,120+(n*8), $88+(n*2), OAMF_BANK1
    endr
Title_MusicOnUnselectedOAM:
    for n,3
        oam_entry    72,120+(n*8), $8e+(n*2), OAMF_BANK1
    endr
    db      -1
Title_MusicOffSelectedOAM:
    for n,3
        oam_entry    72,120+(n*8), $94+(n*2), OAMF_BANK1
    endr
    db      -1
Title_MusicOffUnselectedOAM:
    for n,3
        oam_entry    72,120+(n*8), $9a+(n*2), OAMF_BANK1
    endr
    db      -1

Title_SFXSelectedOAM:
    for n,4
        oam_entry    96, 16+(n*8), $5c+(n*2), OAMF_BANK1
    endr
    db      -1
Title_SFXUnselectedOAM:
    for n,4
        oam_entry    96, 16+(n*8), $64+(n*2), OAMF_BANK1
    endr
    db      -1
Title_SFXOnSelectedOAM:
    for n,3
        oam_entry    96,120+(n*8), $88+(n*2), OAMF_BANK1
    endr
    db      -1
Title_SFXOnUnselectedOAM:
    for n,3
        oam_entry    96,120+(n*8), $8e+(n*2), OAMF_BANK1
    endr
    db      -1
Title_SFXOffSelectedOAM:
    for n,3
        oam_entry    96,120+(n*8), $94+(n*2), OAMF_BANK1
    endr
    db      -1
Title_SFXOffUnselectedOAM:
    for n,3
        oam_entry    96,120+(n*8), $9a+(n*2), OAMF_BANK1
    endr
    db      -1
    
Title_CreditsSelectedOAM:
    for n,4
        oam_entry    120, 52+(n*8), $6c+(n*2), OAMF_BANK1
    endr
    db      -1
Title_CreditsUnselectedOAM:
    for n,7
        oam_entry    120, 52+(n*8), $7a+(n*2), OAMF_BANK1
    endr
    db      -1

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
