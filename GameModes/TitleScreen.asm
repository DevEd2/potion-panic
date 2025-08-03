section union "Title screen RAM",wramx,align[8]
Title_BGTileBuffer: ds  $800

section "Title screen routines",rom0
GM_Title:
    call    LCDOff
    call    ClearScreen
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
    ; ld      hl,Pal_TitleBG
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
    
    xor     a
    ldh     [rVBK],a    
    
    call    CopyPalettes
    call    UpdatePalettes
    call    DeleteAllObjects
    
    ld      a,bank(Mus_WorldMap)-1 ; TODO: Proper title screen music
    call    GBM_LoadModule    
    
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
    ei

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
    ld      a,7 | HDMA5F_MODE_HBL
    ld      [rHDMA5],a
:   ldh     a,[rLY]
    cp      SCRN_Y/2
    jr      nz,:-
    call    GBM_Update
    
    jr      TitleLoop

IntS_Title:
    ldh     a,[rLY]
    cp      64
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
    ld      a,((7 * 2) * 4) + 2 | BGPIF_AUTOINC
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

section "Title gold table",rom0,align[8]
Title_GoldTable:
    rgb8 223,198, 86
    rgb8 206,183, 74
    rgb8 190,168, 62
    rgb8 174,152, 49
    rgb8 158,137, 37
    rgb8 141,122, 25
    rgb8 125,107, 13
    rgb8 109, 92,  1
    rgb8 125,107, 13
    rgb8 141,122, 25
    rgb8 158,137, 37
    rgb8 174,152, 49
    rgb8 190,168, 62
    rgb8 206,183, 74
    rgb8 223,198, 86
    rgb8 239,213, 98

; ================================================================

section "Title screen GFX",romx
GFX_TitleBG:    incbin  "GFX/menubg.2bpp.wle"
GFX_TitleLogo:  incbin  "GFX/logo.2bpp.wle"
Map_TitleBG:    incbin  "GFX/menubg.map.wle"
Attr_TitleBG:   incbin  "GFX/menubg.atr.wle"

Pal_TitleBG:
    for n,7
        rgb     0, (0*(7-n))/2, (0*(7-n))
        rgb     0, (2*(7-n))/2, (2*(7-n))
        rgb     0, (3*(7-n))/2, (3*(7-n))
        rgb     0, (4*(7-n))/2, (4*(7-n))
    endr
    rgb      0, 0, 0
    rgb     31,31,31
    rgb      0, 0,31
    rgb     31, 0,31
