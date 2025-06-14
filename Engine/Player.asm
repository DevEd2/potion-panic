section "Player RAM",wram0

def PLAYER_ACCEL            = $080
def PLAYER_DECEL            = $060
def PLAYER_WALK_SPEED       = $200
def PLAYER_RUN_SPEED        = $300
def PLAYER_JUMP_HEIGHT      = $300
def PLAYER_GRAVITY          = $040

def PLAYER_WIDTH            = 6
def PLAYER_HEIGHT           = 27

Player_RAMStart:
Player_XPos:    ds  3   ; x position (Q16.8)
Player_YPos:    ds  2   ; y position (Q8.8)
Player_XVel:    ds  2   ; added to xpos each frame
Player_YVel:    ds  2   ; added to ypos each frame
Player_Grav:    ds  2   ; added to yvel each frame
Player_Flags:   db      ; bit 0: direction player is facing (0 = right, 1 = left)
                        ; bit 1: whether player is airborne (set) or grounded (unset)
                        ; bit 2: whether player is standing (unset) or crouching/crawling (set)
                        ; bit 3:
                        ; bit 4:
                        ; bit 5:
                        ; bit 6:
                        ; bit 7: noclip
Player_HorizColSensorTop:       db
Player_HorizColSensorBottom:    db
Player_VertColSensorLeft:       db
Player_VertColSensorRight:      db
Player_VertColSensorCenter:     db
Player_RAMEnd:

def BIT_PLAYER_DIRECTION    = 0
def BIT_PLAYER_AIRBORNE     = 1
def BIT_PLAYER_CROUCHING    = 2 
def BIT_PLAYER_UNUSED3      = 3
def BIT_PLAYER_UNUSED4      = 4
def BIT_PLAYER_UNUSED5      = 5
def BIT_PLAYER_UNUSED6      = 6
def BIT_PLAYER_NOCLIP       = 7

section "Player routines",rom0

InitPlayer:
    ; clear player RAM
    ld      hl,Player_RAMStart
    ld      b,Player_RAMEnd-Player_RAMStart
    xor     a
    call    MemFillSmall
    ; load player GFX
    ld      a,1
    ldh     [rVBK],a
    farload hl,PlayerTiles
    ld      de,_VRAM
    call    DecodeWLE
    ; hl = PlayerPalette
    ld      a,8
    jp      LoadPal

ProcessPlayer:
    ld      a,[Player_Flags]
    bit     BIT_PLAYER_NOCLIP,a
    call    nz,Player_Noclip
    
    call    Player_CheckCollisionHorizontal
    call    Player_CheckCollisionVertical
    ; TODO
    ret

Player_CheckCollisionVertical:
    ld      a,[Player_YVel+1]
    bit     7,a ; is player moving up?
    ld      a,[Player_YPos]
    jr      z,.goingup
    ; fall through
.goingdown
    ; TODO: check if player is crouching
    add     16-PLAYER_HEIGHT
    jr      :+
    ret
.goingup
    add     15
    ; fall through
:   and     $f0
    swap    a
    ld      c,a
    ; get left collision point
    ld      a,[Player_XPos+2]
    ld      e,a
    ld      a,[Player_XPos]
    sub     PLAYER_WIDTH
    jr      nc,:+
    dec     e
:   and     $f0
    or      c
    ld      b,e
    call    GetTile
    ld      [Player_VertColSensorLeft],a
    ; get right collision point
    ld      a,[Player_XPos+2]
    ld      e,a
    ld      a,[Player_XPos]
    add     PLAYER_WIDTH
    jr      nc,:+
    inc     e
:   and     $f0
    or      c
    ld      b,e
    call    GetTile
    ld      [Player_VertColSensorRight],a
    ; get center collision point
    ld      a,[Player_XPos+2]
    ld      e,a
    ld      a,[Player_XPos]
    and     $f0
    or      c
    ld      b,e
    call    GetTile
    ld      [Player_VertColSensorCenter],a
    ret

; Check for collision using two sensors - one at player Y - 8 pixels, one at player Y + 8 pixels, both at (X + 6) * [direction]
; Returns carry if a collision is found
Player_CheckCollisionHorizontal:
    ld      d,0
    ; check top sensor
    ld      a,[Player_XPos+2]
    ld      e,a
    ld      hl,Player_Flags
    bit     BIT_PLAYER_DIRECTION,[hl]
    jr      z,.ur
.ul
    ld      a,[Player_XPos]
    sub     PLAYER_WIDTH
    jr      nc,:+
    dec     e
    jr      :+
.ur
    ld      a,[Player_XPos]
    add     PLAYER_WIDTH
    jr      nc,:+
    inc     e
:   and     $f0
    ld      b,a
    ld      a,[Player_YPos]
    sub     8
    and     $f0
    swap    a
    or      b
    ld      b,e
    call    GetTile
    ld      [Player_HorizColSensorTop],a
.nocol1
    ; check bottom sensor
    ld      a,[Player_XPos+2]
    ld      e,a
    ld      hl,Player_Flags
    bit     BIT_PLAYER_DIRECTION,[hl]
    jr      z,.br
.bl
    ld      a,[Player_XPos]
    sub     PLAYER_WIDTH
    jr      nc,:+
    dec     e
    jr      :+
.br
    ld      a,[Player_XPos]
    add     PLAYER_WIDTH
    jr      nc,:+
    inc     e
:   and     $f0
    ld      b,a
    ld      a,[Player_YPos]
    add     8
    and     $f0
    swap    a
    or      b
    ld      b,e
    call    GetTile
    ld      [Player_HorizColSensorBottom],a
    ret

Player_Noclip:
    ld      e,2    
    ld      hl,hHeldButtons
    bit     BIT_B,[hl]
    jr      z,:+
    ld      e,8
:   bit     BIT_UP,[hl]
    call    nz,.up
    bit     BIT_DOWN,[hl]
    call    nz,.down
    bit     BIT_LEFT,[hl]
    call    nz,.left
    bit     BIT_RIGHT,[hl]
    call    nz,.right
    ret
.up
    ld      a,-1
    ld      [Player_YVel],a
    ld      [Player_YVel+1],a
    ld      a,[Player_YPos]
    sub     e
    ld      [Player_YPos],a
    ret
.down
    xor     a
    ld      [Player_YVel],a
    ld      [Player_YVel+1],a
    ld      a,[Player_YPos]
    add     e
    ld      [Player_YPos],a
    ret
.left
    push    hl
    ld      hl,Player_Flags
    set     BIT_PLAYER_DIRECTION,[hl]
    ld      a,[Player_XPos]
    sub     e
    ld      [Player_XPos],a
    jr      nc,:+
    ld      hl,Player_XPos+2
    dec     [hl]
:   pop     hl
    ret
.right
    push    hl
    ld      hl,Player_Flags
    res     BIT_PLAYER_DIRECTION,[hl]
    ld      a,[Player_XPos]
    add     e
    ld      [Player_XPos],a
    jr      nc,:+
    ld      hl,Player_XPos+2
    inc     [hl]
:   pop     hl
    ret

DrawPlayer:
    ld      hl,.sprite
    ld      de,OAMBuffer
    ld      b,(.sprite_end-.sprite)/4
:   ; y position
    ld      a,[hl+]
    ld      c,a
    ld      a,[Player_YPos]
    add     c
    ld      c,a
    ld      a,[Level_CameraY]
    cpl
    inc     a
    add     c
    ld      [de],a
    inc     e
    ; x position
    ld      a,[hl+]
    ld      c,a
    ld      a,[Player_XPos]
    add     c
    ld      c,a
    ld      a,[Level_CameraX]
    cpl
    inc     a
    add     c
    ld      [de],a
    inc     e
    ; sprite
    ld      a,[hl+]
    ld      [de],a
    inc     e
    ; attribute
    ld      a,[hl+]
    ld      [de],a
    inc     e
    dec     b
    jr      nz,:-
    
    ret
.sprite
    db -16+16, 8 -16, 0, 8
    db -16+16, 8 - 8, 2, 8
    db -16+16, 8 + 0, 4, 8
    db -16+16, 8 + 8, 6, 8
    db   0+16, 8 -16, 8, 8
    db   0+16, 8 - 8,10, 8
    db   0+16, 8 + 0,12, 8
    db   0+16, 8 + 8,14, 8
.sprite_end

section "Player GFX",romx

PlayerTiles:    incbin  "GFX/player_placeholder.2bpp.wle"
PlayerPalette:  incbin  "GFX/player_placeholder.pal"