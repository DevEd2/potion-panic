section "Level map",wramx,bank[1]
def LEVEL_MAX_SCREENS = 1
def LEVEL_ROW_SIZE = 16
def LEVEL_COLUMN_SIZE = 16

def LEVEL_TIME_BETWEEN_ENEMY_SPAWNS = 20

def SIZEOF_LEVELMAP_RAM = (LEVEL_ROW_SIZE * LEVEL_COLUMN_SIZE) * LEVEL_MAX_SCREENS

Level_Map:  ds SIZEOF_LEVELMAP_RAM

section "Level RAM",wram0
Level_ID:               db

Level_BlockMapBank:     db
Level_BlockMapPtr:      dw
Level_ColMapBank:       db
Level_ColMapPtr:        dw
;Level_ColHeightBank:    db
;Level_ColHeightPtr:     dw
;Level_ColAnglePtr:      db
;Level_ColAngleBank:     db

Level_CameraX:          dw
Level_CameraY:          db
Level_CameraSubX:       db
Level_CameraSubY:       db
Level_CameraTargetX:    db
Level_CameraTargetY:    db
Level_CameraOffsetX:    db
Level_CameraOffsetY:    db
Level_CameraMaxX:       dw
Level_CameraMaxY:       db
Level_CameraXPrev:      db
Level_ScrollDir:        db
Level_ScreenShakePtr:   dw
Level_HitstopTimer:     db
Level_ResetFlag:        db
Level_Flags:            db  ; bit 0 = horizontaL/vertical
                            ; bit 1 = ???
                            ; bit 2 = ???
                            ; bit 3 = ???
                            ; bit 4 = ???
                            ; bit 5 = ???
                            ; bit 6 = ???
                            ; bit 7 = ???
Level_Size:             db  ; 0-15

Level_EnemyCount:       db
Level_EnemySpawnTimer:  db
Level_EnemyListBank:    db
Level_EnemyListPtr:     dw

Level_ClearTimer:       db

Level_Paused:           db

section "Level routines",rom0
GM_Level:
    call    LCDOff
    call    ClearScreen
    
    ; HACK
    xor     a
    ldh     [hPressedButtons],a
    
    ; clear level map
    ld      a,bank(Level_Map)
    ldh     [rSVBK],a
    ld      hl,Level_Map
    ld      bc,SIZEOF_LEVELMAP_RAM
    ld      e,0
    call    MemFill

    ; init player
    call    InitPlayer
    xor     a
    ldh     [rVBK],a
    ld      [Level_ClearTimer],a
    ld      [Level_Paused],a
    ld      [Level_HitstopTimer],a
    ld      [Level_ResetFlag],a

    ; get map pointer from ID
    ld      a,[Level_ID]
    ld      l,a
    ld      c,a
    ld      h,0
    ld      b,0
    add     hl,hl
    add     hl,bc
    ld      bc,Level_Pointers
    add     hl,bc
    ld      a,[hl+]
    bankswitch_to_a
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    ; level size
    ld      a,[hl+]
    ld      [Level_Size],a
    ; player start position
    ld      a,[hl]
    and     $f0
    ld      [Player_XPos],a
    ld      a,[hl+]
    swap    a
    and     $f0
    ;sub     16
    ld      [Player_YPos],a
    ; music
    pushbank
    ld      a,[hl+]
    push    hl
    call    GBM_LoadModule
    pop     hl
    popbank
    ; tileset
    ld      a,[hl+]
    ld      [Level_BlockMapBank],a
    ld      e,a
    ld      a,[hl+]
    push    hl
    ld      h,[hl]
    ld      l,a
    pushbank
    ld      a,e
    bankswitch_to_a
    call    LoadTileset
    popbank
    pop     hl
    inc     hl
    ; palette
    pushbank
    ld      a,[hl+]
    ld      e,a
    ld      a,[hl+]
    push    hl
    ld      h,[hl]
    ld      l,a
    ld      a,e
    bankswitch_to_a
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
    pop     hl
    inc     hl
    popbank
    ; object set
    ld      a,1
    ldh     [rVBK],a
    pushbank
    ld      a,[hl+]
    call    Level_LoadObjectGFXSet
    popbank
    
    ; enemy count
    ld      a,[hl+]
    ld      [Level_EnemyCount],a
    
    ; actual level layout
    ld      a,[hl+]
    push    hl
    ld      h,[hl]
    ld      l,a
    ld      a,bank(Level_Map)
    ldh     [rSVBK],a
    ld      de,Level_Map
    call    DecodeWLE
    pop     hl
    inc     hl
    ; object layout
    ld      a,[hl+]
    ld      [Level_EnemyListBank],a
    ld      a,[hl+]
    ld      [Level_EnemyListPtr],a
    ld      a,[hl+]
    ld      [Level_EnemyListPtr+1],a
    
    ld      a,200
    ld      [Level_EnemySpawnTimer],a
    
    ; fill background map with first 16 columns of level map
    xor     a
    ld      hl,Level_Map
:   ld      b,[hl]
    inc     l
    call    DrawMetatile
    inc     a
    jr      nz,:-
    
    ; load bigfont
    pushbank
    xor     a
    ldh     [rVBK],a
    farload hl,GFX_BigFont
    ld      de,_VRAM
    call    DecodeWLE
    ; ld      hl,Pal_BigFont
    ld      a,15
    call    LoadPal
    
    ; load puff of smoke and explosion graphics
    ; ld      hl,GFX_Explosion
    ld      de,_VRAM + ($60 * 16)
    call    DecodeWLE
    ; ld      hl,GFX_PuffOfSmoke
    call    DecodeWLE
    ; ld      hl,GFX_Fireball
    call    DecodeWLE
    ; ld      hl,Pal_Explosion
    ld      a,14
    call    LoadPal
    
    
    ; load HUD graphics
    ld      a,1
    ldh     [rVBK],a
    ld      de,_SCRN0-$260
    call    DecodeWLE
    ld      a,6
    call    LoadPal
    ld      a,7
    call    LoadPal
    
    ; load pause text graphics
    ld      de,$8e00
    call    DecodeWLE
    
    ; load potion graphics
    xor     a
    ldh     [rVBK],a
    ld      hl,GFX_Potion
    ld      de,$84a0
    call    DecodeWLE
    
    popbank
    
    ; screen setup
    ld      a,256-SCRN_Y
    ld      [Level_CameraMaxY],a
    
    ld      a,[Level_Size]
    ld      [Level_CameraMaxX+1],a
    ld      a,256-SCRN_X
    ld      [Level_CameraMaxX],a
    
    xor     a
    ldh     [rVBK],a
    ld      [Level_CameraTargetX],a
    ld      a,[Level_CameraMaxY]
    
    ldh     [rSCX],a
    ld      [Level_CameraX],a
    ld      [Level_CameraX+1],a
    ld      [Level_CameraSubX],a
    
    ldh     [rSCY],a
    ld      [Level_CameraY],a
    ld      [Level_CameraSubY],a
    
    ld      [Level_ScrollDir],a
    
    ld      a,256-SCRN_Y
    ld      [Level_CameraY],a
    ld      [Level_CameraTargetY],a
    
    call    DeleteAllObjects
    call    Potion_InitEffects
    ; create test object (TEMP REMOVE ME)
    ; ld      b,OBJID_Potion
    ; lb      de,140,140
    ; call    CreateObject
    
    ld      a,low(ScreenShake_Dummy)
    ld      [Level_ScreenShakePtr],a
    ld      a,high(ScreenShake_Dummy)
    ld      [Level_ScreenShakePtr+1],a
    
    ; create level intro text object
    ld      b,OBJID_BigText
    lb      de,0,0
    call    CreateObject
    inc     h
    ld      [hl],BIGTEXT_GET_READY
    
    call    CopyPalettes
    call    ConvertPals
    ;call    UpdatePalettes
    call    PalFadeInWhite
    
    ld      a,LCDCF_ON | LCDCF_BGON | LCDCF_OBJON | LCDCF_BLK21 | LCDCF_OBJ16 | LCDCF_WINON | LCDCF_WIN9C00
    ldh     [rLCDC],a
    ld      a,IEF_VBLANK | IEF_STAT
    ldh     [rIE],a
    ei
    
LevelLoop:
    ; pause logic
    ld      a,[Level_Paused]
    and     a
    jp      nz,.alreadypaused
    ld      a,[sys_FadeState]
    and     a
    jp      nz,.nopause
    ldh     a,[hPressedButtons]
    bit     BIT_START,a
    jp      z,.nopause
    ld      a,1
    ld      [Level_Paused],a
    ld      a,[Player_AnimFrame]
    ld      [Player_PauseTempFrame],a
    ; disable and re-enable sound to kill hanging notes
    ld      hl,rNR52
    ld      [hl],0
    ld      [hl],$80
    dec     l
    ld      [hl],%11111111
    dec     l
    ld      [hl],$77
    ld      a,-1
    ld      [GBM_ForceWaveRetrig],a    ; force wave channel retrigger on resume
    ; play pause sound effect
    ld      e,SFX_PAUSE_CH1
    call    DSFX_PlaySound
    ld      e,SFX_PAUSE_CH2
    call    DSFX_PlaySound
    ld      e,SFX_PAUSE_CH3
    call    DSFX_PlaySound
    ; load palette
    farload hl,Pal_PauseText
    push    hl
    call    Math_Random
    pop     hl
    cp      $fc ; 1/64 chance of getting rare palette
    jr      c,:+
    call    .pausesetwandanim
    ld      bc,Pal_PauseTextRare-Pal_PauseText
    add     hl,bc
:   rst     WaitForVBlank   ; wait one frame to avoid one-frame palette corruption
    ld      [hSP],sp
    di
    ld      sp,hl
    ld      a,$80
    ldh     [rOCPS],a
    ld      hl,rOCPD
    rept    4
        pop     de
        ld      [hl],e
        ld      [hl],d
        pop     de
        ld      [hl],e
        ld      [hl],d
        pop     de
        ld      [hl],e
        ld      [hl],d
        pop     de
        ld      [hl],e
        ld      [hl],d
    endr
    ld      hl,hSP
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    ld      sp,hl
    ei
    jr      :+ ; skip unpause logic so we don't immediately unpause
.alreadypaused
    ldh     a,[hPressedButtons]
    bit     BIT_START,a
    jr      z,:+
    ; unpause
    xor     a
    ld      [Level_Paused],a
    rst     WaitForVBlank
    ld      c,0
    call    DSFX_KillChannel
    inc     c
    call    DSFX_KillChannel
    inc     c
    call    DSFX_KillChannel
    call    UpdatePalettes  ; restore palettes
    call    .unpausesetanim
    jp      .nopause
:   ; set pause OAM
    farload hl,PauseTextOAM
    ld      b,(PauseTextOAM.end-PauseTextOAM)/4
    ld      de,OAMBuffer
:   ; y pos
    ld      a,[hl+]
    add     SCRN_Y/2
    push    bc
    ld      b,a
    push    bc
    ld      a,[hGlobalTick]
    add     a
    ld      b,a
    add     a
    add     b
    add     [hl]
    add     [hl]
    add     [hl]
    push    hl
    push    de
    call    Math_SinCos
    add     hl,hl
    ld      a,h
    pop     de
    pop     hl
    pop     bc
    add     b
    pop     bc
    ld      [de],a
    inc     e
    ; x pos
    ld      a,[hl+]
    add     SCRN_X/2
    ld      [de],a
    inc     e
    ; tile
    ld      a,[hl+]
    ld      [de],a
    inc     e
    ; attributes
    ld      a,[hl+]
    ld      [de],a
    inc     e
    dec     b
    jr      nz,:-
    call    DSFX_Update
    rst     WaitForVBlank
    ld      a,LCDCF_ON | LCDCF_BGON | LCDCF_OBJON | LCDCF_BLK21 | LCDCF_OBJ16 | LCDCF_WINON | LCDCF_WIN9C00
    ldh     [rLCDC],a
    jp      LevelLoop
.pausesetwandanim
    ; when rare palette is selected, briefly show wand animation
    push    hl
    ld      a,[Player_Flags]
    bit     BIT_PLAYER_DIRECTION,a
    jr      z,.pright
.pleft
    bit     BIT_PLAYER_FAT,a
    jr      nz,.pfat1
    bit     BIT_PLAYER_TINY,a
    jr      nz,.ptiny1
.pnormal1
    ld      a,frame_wand_left
    jr      .psetanim
.pfat1
    ld      a,frame_fat_wand_left
    jr      .psetanim
.ptiny1
    ld      a,frame_tiny_wand
    jr      .psetanim
.pright
    bit     BIT_PLAYER_FAT,a
    jr      nz,.pfat2
    bit     BIT_PLAYER_TINY,a
    jr      nz,.ptiny2
.pnormal2
    ld      a,frame_wand_right
    jr      .psetanim
.pfat2
    ld      a,frame_fat_wand_right
    jr      .psetanim
.ptiny2
    ld      a,frame_tiny_wand
.psetanim
    ld      [Player_AnimFrame],a
    rst     WaitForVBlank
    pushbank
    call    DrawPlayer
    ; player must be visible for 2 frames in order for sprite to display properly
    ld      a,LCDCF_ON | LCDCF_BGON | LCDCF_OBJON | LCDCF_BLK21 | LCDCF_OBJ16 | LCDCF_WINON | LCDCF_WIN9C00
    ldh     [rLCDC],a
    rst     WaitForVBlank
    ld      a,LCDCF_ON | LCDCF_BGON | LCDCF_OBJON | LCDCF_BLK21 | LCDCF_OBJ16 | LCDCF_WINON | LCDCF_WIN9C00
    ldh     [rLCDC],a
    popbank
    pop     hl
    ret
.unpausesetanim
    ld      a,[Player_PauseTempFrame]
    ld      [Player_AnimFrame],a
    push    hl
    jr      .psetanim
.nopause
    ; level clear logic
    ld      a,[Level_HitstopTimer]
    and     a
    jr      nz,.noclear
    ld      a,[Level_EnemyCount]
    and     a
    jr      nz,.noclear
    ld      a,[Player_LockControls]
    and     a
    jr      nz,:+
    ld      a,1
    ld      [Player_LockControls],a
    xor     a
    ld      [ObjList],a ; delete existing bigtext object
    ld      b,OBJID_BigText
    lb      de,0,0
    call    CreateObject
    inc     h
    ld      [hl],BIGTEXT_WELL_DONE
:   ; TODO: fadeout + load next level
    jp      .doproc

.noclear
    ; spawn enemies
    ld      a,[Level_HitstopTimer]
    and     a
    jr      nz,:+
    ld      a,[Level_EnemySpawnTimer]
    dec     a
    ld      [Level_EnemySpawnTimer],a
    jr      nz,:+
    ld      a,[Level_EnemyListBank]
    bankswitch_to_a
    ld      hl,Level_EnemyListPtr
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    ld      a,[hl+] ; read object ID
    cp      -1      ; end of list reached?
    jr      z,:+    ; if yes, skip
    ld      c,a     ; save for later
    inc     hl      ; skip dummy byte
    ld      a,[hl+] ; read object X position
    ld      d,a
    ld      a,[hl+] ; read object Y position
    ld      e,a
    push    hl
    ; create puff of smoke object
    ld      b,OBJID_PuffOfSmoke
    call    CreateObject
    ; actually spawn the enemy
    ld      b,c
    call    CreateObject
    ; save pointer
    pop     hl
    ld      a,l
    ld      [Level_EnemyListPtr],a
    ld      a,h
    ld      [Level_EnemyListPtr+1],a
    ld      a,LEVEL_TIME_BETWEEN_ENEMY_SPAWNS
    ld      [Level_EnemySpawnTimer],a
:   ; debug builds only: noclip logic
    if BUILD_DEBUG
        ldh     a,[hPressedButtons]
        bit     BIT_SELECT,a
        jr      z,:+       
        ld      a,[Player_Flags]
        xor     1 << BIT_PLAYER_NOCLIP
        ld      [Player_Flags],a
    endc
:   ; make camera follow player
    ld      a,[Player_YPos]
    sub     SCRN_Y/2+8
    ld      [Level_CameraTargetY],a
    ; left clamp
    ld      a,[Player_XPos]
    ld      l,a
    ; ld      a,[Player_XPos+2]
    ld      h,0
    ld      bc,-(SCRN_X/2)
    add     hl,bc
    jr      c,:+
    ld      hl,0
:   ; right clamp
    ld      a,[Level_CameraMaxX]
    cp      l
    jr      c,:+
    ld      a,l
:   ld      [Level_CameraTargetX],a
    ld      a,h
    ld      [Level_CameraX+1],a
    
    ld      a,[Level_CameraX]    
    ld      b,a
    ld      [Level_CameraXPrev],a

    ld      a,[Level_CameraTargetX]
    ld      [Level_CameraX],a
    
    sub     b
    jr      z,:+
    jr      nc,.scrollright
.scrollleft
    ld      a,-1
    ld      [Level_ScrollDir],a
    jr      :+
.scrollright
    ld      a,1
    ld      [Level_ScrollDir],a
:   ld      a,[Level_CameraY]
    ld      h,a
    ld      a,[Level_CameraSubY]
    ld      l,a
    push    hl
    ld      a,[Level_CameraTargetY]
    cpl
    ld      b,a
    ld      c,0
    add     hl,bc
    bit     7,h
    jr      z,.negativeY
.positiveY
    call    Math_Neg16
    srl     h
    rr      l
    srl     h
    rr      l
    srl     h
    rr      l
    jr      :+
.negativeY
    srl     h
    rr      l
    srl     h
    rr      l
    srl     h
    rr      l
    call    Math_Neg16
    dec     hl
:   ld      b,h
    ld      c,l
    pop     hl
    add     hl,bc
    bit     7,h
    jr      z,:+
    ld      hl,0
    ld      a,h
    jr      :++
:   ld      a,h
    cp      256-SCRN_Y
    jr      c,:+
    ld      a,256-SCRN_Y
:   ld      [Level_CameraY],a
    ld      a,l
    ld      [Level_CameraSubY],a
    
    ; level redraw logic
;    ld      a,[Level_ScrollDir]
;    ld      e,a
;    ld      a,[Level_CameraX]
;    and     $f0
;    ld      b,a
;    ld      a,[Level_CameraXPrev]
;    inc     a
;    and     $f0
;    cp      b
;    ;jr      z,.skipredraw
;    ld      h,high(Level_Map)
;    ld      a,[Level_CameraX]
;    and     $f0
;    add     $b0
;    ld      l,a
;    jr      nc,:+
;    inc     h
;    
;:   ld      a,[Level_CameraX+1]
;    add     h
;    ld      h,a
;    
;    bit     7,e
;    jr      z,:+
;    dec     h
;    ld      a,l
;    add     $40
;    ld      l,a
;    jr      nc,:+
;    inc     h
;    
;:   ld      a,l
;    ld      c,16
;:   ld      b,[hl]
;    call    DrawMetatile
;    inc     l
;    inc     a
;    dec     c
;    jr      nz,:-
;.skipredraw
.doproc
    pushbank
    
    ld      a,[Level_HitstopTimer]
    and     a
    jr      nz,:+
    farcall ProcessPlayer
    
    ld      a,[Level_ResetFlag]
    and     a
    jp      nz,GM_Level
    
    call    Player_ProcessProjectiles
:   call    ProcessObjects
    call    GBM_Update
    call    DSFX_Update
    popbank
    
    call    Pal_DoFade
    rst     WaitForSTAT
    rst     WaitForVBlank
    ld      a,LCDCF_ON | LCDCF_BGON | LCDCF_OBJON | LCDCF_BLK21 | LCDCF_OBJ16 | LCDCF_WINON | LCDCF_WIN9C00
    ldh     [rLCDC],a
    ld      a,[sys_FadeState]
    and     a
    call    nz,UpdatePalettes
    
    ld      a,[sys_PalFadeDone]
    and     a
    jr      z,:+
    xor     a
    ld      [sys_PalFadeDone],a
    call    UpdatePalettes
:   call    DrawPlayer
    call    DrawPlayerLayers
    call    Player_DrawProjectiles
    
    ; do hitstop
    xor     a
    ld      [FreezeObjects],a
    ld      a,[Level_HitstopTimer]
    and     a
    jr      z,:+
    dec     a
    ld      [Level_HitstopTimer],a
    ld      a,1
    ld      [FreezeObjects],a
:
    
    ; do screen shake
    ld      hl,Level_ScreenShakePtr
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    ld      a,[hl+]
    cp      $80
    jr      z,:+
    ld      [Level_CameraOffsetX],a
    ld      a,[hl+]
    ld      [Level_CameraOffsetY],a
    ld      a,l
    ld      [Level_ScreenShakePtr],a
    ld      a,h
    ld      [Level_ScreenShakePtr+1],a
:   ld      a,[Level_CameraX]
    ld      b,a
    ld      a,[Level_CameraOffsetX]
    add     b
    ldh     [rSCX],a
    ld      a,[Level_CameraY]
    ld      b,a
    ld      a,[Level_CameraOffsetY]
    add     b
    ldh     [rSCY],a
    jp      LevelLoop
    
LoadTileset:
    ; load GFX
    ld      a,[hl+]
    push    hl
    ld      h,[hl]
    ld      l,a
    ld      de,_VRAM+$800
    call    DecodeWLE
    pop     hl
    inc     hl
    ld      a,[hl+]
    or      [hl]
    jr      z,:+
    push    hl
    ld      h,[hl]
    ld      l,a
    ld      a,1
    ldh     [rVBK],a
    ld      de,_VRAM+$800
    call    DecodeWLE
    pop     hl
:   inc     hl
    ; set block map pointer
    ld      a,[hROMB0]
    ld      [Level_BlockMapBank],a
    ld      a,[hl+]
    ld      [Level_BlockMapPtr],a
    ld      a,[hl+]
    ld      [Level_BlockMapPtr+1],a
    ; set collision map pointer
    ld      a,[hROMB0]
    ld      [Level_ColMapBank],a
    ld      a,[hl+]
    ld      [Level_ColMapPtr],a
    ld      a,[hl+]
    ld      [Level_ColMapPtr+1],a
    ; set collision height pointer
    ; ld      a,[hROMB0]
    ; ld      [Level_ColHeightBank],a
    ; ld      a,[hl+]
    ; ld      [Level_ColHeightPtr],a
    ; ld      a,[hl+]
    ; ld      [Level_ColHeightPtr+1],a
    ; set collision height pointer
    ; ld      a,[hROMB0]
    ; ld      [Level_ColAngleBank],a
    ; ld      a,[hl+]
    ; ld      [Level_ColAnglePtr],a
    ; ld      a,[hl+]
    ; ld      [Level_ColAnglePtr+1],a
    
    ret

ScreenShake_Dummy:
    db  0,0
    db  $80
    
ScreenShake_Fat_HitEnemy:
    db   2, 0
    db   2, 0
    db   2, 0
    db  -2, 0
    db  -2, 0
    db  -2, 0
    db   1, 0
    db   1, 0
    db   1, 0
    db  -1, 0
    db  -1, 0
    db  -1, 0
    db   0, 0
    db  $80

; =============================================================================

macro gfxdef
    db      bank(ObjGFX_\1)
    db      OBJID_\1
    db      \2
    dw      ObjGFX_\1
endm

macro paldef
    for n,\3
        db      bank(ObjPal_\2)
        db      \1 + n
        dw      ObjPal_\2 + (n * (2 * 4))
    endr
endm

; INPUT:    a = object graphics set ID
; OUTPUT:   none
; DESTROYS:
Level_LoadObjectGFXSet:
    push    hl
    push    af
    ; load object tile data set
    ld      l,a
    ld      h,0
    ld      b,h
    ld      c,l
    add     hl,hl   ; x2
    add     hl,hl   ; x4
    add     hl,bc   ; x5
    ld      bc,Level_ObjectGFXSetPointers
    add     hl,bc
:   ; bank
    ld      a,[hl+]
    and     a
    jr      z,:+    ; bank=0 marks end of list
    bankswitch_to_a
    ; VRAM address
    ld      a,[hl+]
    ld      e,a
    ld      a,[hl+]
    push    hl
    ld      b,a
    ld      l,e
    ld      h,0
    ld      de,ObjectGFXPositions
    add     hl,de
    inc     hl
    ld      [hl],b
    pop     hl
    push    hl
    ld      l,a
    ld      h,0
    add     hl,hl   ; x2
    add     hl,hl   ; x4
    add     hl,hl   ; x8
    add     hl,hl   ; x16
    ld      de,_VRAM
    add     hl,de
    ld      d,h
    ld      e,l
    ; tile data pointer
    pop     hl
    ld      a,[hl+]
    push    hl
    ld      h,[hl]
    ld      l,a
    call    DecodeWLE
    pop     hl
    inc     hl
    jr      :-
:   pop     af
    ; load object palette set
    ld      l,a
    ld      h,0
    add     hl,hl   ; x2
    add     hl,hl   ; x4
    ld      bc,Level_ObjectPaletteSetPointers
    add     hl,bc
:   ; bank
    ld      a,[hl+]
    and     a
    jr      z,:+    ; bank=0 marks end of list
    bankswitch_to_a
    ; palette number
    ld      a,[hl+]
    ld      c,a
    ; palette data pointer
    ld      a,[hl+]
    push    hl
    ld      h,[hl]
    ld      l,a
    ld      a,c
    add     8
    call    LoadPal
    pop     hl
    inc     hl
    jr      :-
:   pop     hl
    ret
    
Level_ObjectGFXSetPointers:
    gfxdef  Frog,$30
    gfxdef  JackOLantern,$46
    gfxdef  Imp,$56
    gfxdef  Slime,$66
    db      0
    
Level_ObjectPaletteSetPointers:
    paldef  3,Frog,1
    paldef  4,JackOLantern,1
    db      0


; =============================================================================

; Must be in ROM0!
; INPUT:    b = 0
;           c = tile X,Y
; OUTPUT:   b = collision index
; DESTROYS: af hl
GetCollisionIndex:
    pushbank
    ld      a,[Level_ColMapBank]
    bankswitch_to_a
    ld      hl,Level_ColMapPtr
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    add     hl,bc
    ld      b,[hl]
    popbank
    ret

; =============================================================================

Level_Pointers:
    dwbank  Map_testlevel
    dwbank  Map_DarkForest1

; =============================================================================

section "Misc GFX",romx

GFX_BigFont:        incbin  "GFX/bigfont.2bpp.wle"
Pal_BigFont:        incbin  "GFX/bigfont.pal"

GFX_Explosion:      incbin  "GFX/explosion.2bpp.wle"
GFX_PuffOfSmoke:    incbin  "GFX/puffofsmoke.2bpp.wle"
GFX_Fireball:       incbin  "GFX/fireball.2bpp.wle"
Pal_Explosion:      incbin  "GFX/explosion.pal" ; also used for puff of smoke and fireball

GFX_HUD:            incbin  "GFX/hud.2bpp.wle"
Pal_HUD:            incbin  "GFX/hud.pal"

GFX_PauseText:      incbin  "GFX/pausetext.2bpp.wle"
Pal_PauseText:      incbin  "GFX/pausetext.pal"         ; default palette (rainbow)
Pal_PauseTextRare:  incbin  "GFX/pausetext_rare.pal"    ; rare pause text (lesbian pride flag colors)

GFX_Potion:         incbin  "GFX/potion.2bpp.wle"

PauseTextOAM:
    db  8,-16 + (0 * 8),$e0,$8
    db  8,-16 + (1 * 8),$e2,$8
    db  8,-16 + (2 * 8),$e4,$9
    db  8,-16 + (3 * 8),$e6,$a
    db  8,-16 + (4 * 8),$e8,$b
    db  8,-16 + (5 * 8),$ea,$b
.end

; =============================================================================

section "Dark forest tileset",romx
Tileset_DarkForest:
    dw  .tiles
    dw  0
    dw  .blocks
    dw  .colmap

.tiles          incbin  "Tilesets/DarkForest.2bpp.wle"
.blocks         incbin  "Tilesets/DarkForest.blk"
.colmap
    db  0,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0
    db  0,1,1,1,1,1,2,2,0,0,0,0,0,0,0,0
    db  0,1,1,1,1,1,2,2,2,2,2,2,2,2,0,0
    db  0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0
    db  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

Pal_DarkForest:     incbin  "Tilesets/DarkForest.pal"

section "Test tileset",romx
Tileset_Test:
    dw  .tiles
    dw  0               ; special case: if this is set to 0, second tileset load is skipped
    dw  .blocks
    dw  .colmap
;    dw  .colheights
;    dw  .colangles

.tiles          incbin "Tilesets/TestTileset.2bpp.wle"
.blocks         incbin "Tilesets/TestTileset.blk"
.colmap         incbin "Tilesets/TestTileset_Collision.bin"
;.colheights     incbin "Tilesets/TestTileset_CollisionHeights.bin"
;.colangles      incbin "Tilesets/TestTileset_CollisionAngles.bin"

Pal_TestTileset:    incbin  "Tilesets/TestTileset.pal"

    include "Levels/testlevel.inc"
    include "Levels/DarkForest1.inc"

; =============================================================================

    include "Engine/Player.asm"

