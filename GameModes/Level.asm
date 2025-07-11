section "Level map",wramx,bank[1]
def LEVEL_MAX_SCREENS = 16
def LEVEL_ROW_SIZE = 16
def LEVEL_COLUMN_SIZE = 16

def SIZEOF_LEVELMAP_RAM = (LEVEL_ROW_SIZE * LEVEL_COLUMN_SIZE) * LEVEL_MAX_SCREENS

Level_Map:  ds SIZEOF_LEVELMAP_RAM

section "Level RAM",wram0
Level_ID:               db

Level_LayoutBank:       db
Level_LayoutPtr:        dw
Level_ObjectsBank:      db
Level_ObjectsPtr:       db

Level_BlockMapBank:     db
Level_BlockMapPtr:      dw
Level_ColMapBank:       db
Level_ColMapPtr:        dw
Level_ColHeightBank:    db
Level_ColHeightPtr:     dw
Level_ColAnglePtr:      db
Level_ColAngleBank:     db

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

Level_Flags:            db  ; bit 0 = horizontaL/vertical
                            ; bit 1 = ???
                            ; bit 2 = ???
                            ; bit 3 = ???
                            ; bit 4 = ???
                            ; bit 5 = ???
                            ; bit 6 = ???
                            ; bit 7 = ???
Level_Size:             db  ; 0-15
 
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

    ; load test level - TEMP HACK, remove later
    farload hl,Map_testlevel
    ; level size
    ld      a,[hl+]
    ld      [Level_Size],a
    inc     a
    ld      b,a
    ; player start position
    ld      a,[hl]
    and     $f0  
    ld      [Player_XPos],a
    ld      a,[hl+]
    swap    a
    and     $f0
    ;sub     16
    ld      [Player_YPos],a
    ; music - TODO, skip and play placeholder music for now
    ld      a,[hl+]
    ld      a,[hl+]
    ld      a,[hl+]
    push    hl
    push    bc
    push    de
    pushbank
    ld      a,bank(Mus_LostInTranslation)-1
    call    GBM_LoadModule
    popbank
    pop     de
    pop     bc
    pop     hl
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
    call    CopyPalettes
    call    UpdatePalettes
    pop     hl
    inc     hl
    popbank
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
    ; object layout - TODO, skip for now
    ld      a,[hl+]
    ld      a,[hl+]
    
    ; fill background map with first 16 columns of level map
    xor     a
    ld      hl,Level_Map
:   ld      b,[hl]
    inc     l
    call    DrawMetatile
    inc     a
    jr      nz,:-
    
    ; screen setup
    ld      a,256-SCRN_Y
    ld      [Level_CameraMaxY],a
    
    ld      a,[Level_Size]
    ld      [Level_CameraMaxX+1],a
    ld      a,256-SCRN_X
    ld      [Level_CameraMaxX],a
    
    xor     a
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
    
    ; create test object
    call    DeleteAllObjects
    ;lb      bc,OBJID_Test,0
    ;lb      de,$12,$34
    ;call    CreateObject
    
    ld      a,LCDCF_ON | LCDCF_BGON | LCDCF_OBJON | LCDCF_BLK21 | LCDCF_OBJ16
    ldh     [rLCDC],a
    ld      a,IEF_VBLANK
    ldh     [rIE],a
    ei
    
LevelLoop:
    if BUILD_DEBUG
        ; toggle noclip flag
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
    
    ld      a,[Player_XPos]
    ld      l,a
    ld      a,[Player_XPos+2]
    ld      h,a
    ld      bc,-(SCRN_X/2)
    add     hl,bc
    jr      c,:+
    ld      hl,0
:   ; TODO: right clamp
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
    call    ProcessPlayer
    call    ProcessObjects
    pushbank
    call    GBM_Update
    popbank
    rst     WaitForVBlank    
    call    DrawPlayer
    ld      a,[Level_CameraX]
    ldh     [rSCX],a
    ld      a,[Level_CameraY]
    ldh     [rSCY],a
    
    jp      LevelLoop
.up
    dec     [hl]
    ret
.down
    inc     [hl]
    ret
.left
    ld      a,[hl]
    sub     1   ; apparently dec doesn't affect carry so I *have* to do this
    ld      [hl],a
    ret     nc
    inc     hl
    dec     [hl]
    ret
.right
    ld      a,[hl]
    add     1   ; apparently inc doesn't affect carry so I *have* to do this
    ld      [hl],a
    ret     nc
    inc     hl
    inc     [hl]
    ret
    
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
    ld      a,[hROMB0]
    ld      [Level_ColHeightBank],a
    ld      a,[hl+]
    ld      [Level_ColHeightPtr],a
    ld      a,[hl+]
    ld      [Level_ColHeightPtr+1],a
    ; set collision height pointer
    ld      a,[hROMB0]
    ld      [Level_ColAngleBank],a
    ld      a,[hl+]
    ld      [Level_ColAnglePtr],a
    ld      a,[hl+]
    ld      [Level_ColAnglePtr+1],a
    
    ret

section "Test tileset",romx
Tileset_Test:
    dw  .tiles
    dw  0               ; special case: if this is set to 0, second tileset load is skipped
    dw  .blocks
    dw  .colmap
    dw  .colheights
    dw  .colangles

.tiles          incbin "Tilesets/TestTileset.2bpp.wle"
.blocks         incbin "Tilesets/TestTileset.blk"
.colmap         incbin "Tilesets/TestTileset_Collision.bin"
.colheights     incbin "Tilesets/TestTileset_CollisionHeights.bin"
.colangles      incbin "Tilesets/TestTileset_CollisionAngles.bin"

Pal_TestTileset:    incbin  "Tilesets/TestTileset.pal"

; TEMP HACK REMOVE ME
MUSIC_NONE: db "TEMP HACK REMOVE ME"

    include "Levels/testlevel.inc"

; =============================================================================

    include "Engine/Player.asm"