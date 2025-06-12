section "Player RAM",wram0

def PLAYER_ACCEL        = $080
def PLAYER_DECEL        = $060
def PLAYER_WALK_SPEED   = $200
def PLAYER_RUN_SPEED    = $300
def PLAYER_JUMP_HEIGHT  = $300
def PLAYER_GRAVITY      = $040

Player_RAMStart:
Player_XPos:    ds  3   ; x position (Q16.8)
Player_YPos:    ds  2   ; y position (Q8.8)
Player_XVel:    ds  2   ; added to xpos each frame
Plaery_YVel:    ds  2   ; added to ypos each frame
Player_Grav:    ds  2   ; added to yvel each frame
Player_Flags:   db      ; bit 0: direction player is facing (0 = right, 1 = left)
                        ; bit 1: whether player is airborne (set) or grounded (unset)
                        ; bit 2:
                        ; bit 3:
                        ; bit 4:
                        ; bit 5:
                        ; bit 6:
                        ; bit 7:
Player_RAMEnd:

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
    ;call    PlayerMode_Noclip
    ;ret
    
PlayerMode_Noclip:
    ld      hl,hHeldButtons
    bit     BIT_UP,[hl]
    call    nz,.up
    bit     BIT_DOWN,[hl]
    call    nz,.down
    bit     BIT_LEFT,[hl]
    call    nz,.left
    bit     BIT_RIGHT,[hl]
    call    nz,.right
    ret
.up
    ld      a,[Player_YPos]
    sub     2
    ld      [Player_YPos],a
    ret
.down
    ld      a,[Player_YPos]
    add     2
    ld      [Player_YPos],a
    ret
.left
    ld      a,[Player_XPos]
    sub     2
    ld      [Player_XPos],a
    ret     nc
    push    hl
    ld      hl,Player_XPos+2
    dec     [hl]
    pop     hl
    ret
.right
    ld      a,[Player_XPos]
    add     2
    ld      [Player_XPos],a
    ret     nc
    push    hl
    ld      hl,Player_XPos+2
    inc     [hl]
    pop     hl
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
    db  -16, 8 -16, 0, 8
    db  -16, 8 - 8, 2, 8
    db  -16, 8 + 0, 4, 8
    db  -16, 8 + 8, 6, 8
    db  - 0, 8 -16, 8, 8
    db  - 0, 8 - 8,10, 8
    db  - 0, 8 + 0,12, 8
    db  - 0, 8 + 8,14, 8
.sprite_end

section "Player GFX",romx

PlayerTiles:    incbin  "GFX/player_placeholder.2bpp.wle"
PlayerPalette:  incbin  "GFX/player_placeholder.pal"