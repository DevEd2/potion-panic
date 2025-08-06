rsreset
def EXPLOSION_STATE_INIT    rb
def EXPLOSION_STATE_IDLE    rb
rsreset
def Explosion_Timer         rb
def Explosion_Frame         rb
assert _RS <= 16, "Object uses too much RAM! (Max size = $10, got {_RS})"

def EXPLOSION_FRAME_TIME = 4

Obj_Explosion:
; Routine pointers.
; OBJ_STATE is used as an index into this
Obj_Explosion_RoutinePointers:
    dw  Obj_Explosion_Init
    dw  Obj_Explosion_Idle

Obj_Explosion_Init:
    ldobjp  OBJ_STATE
    ld      a,EXPLOSION_STATE_IDLE
    ld      [hl+],a ; object state
    ; ld      a,1<<OBJB_VISIBLE ; EXPLOSION_STATE_IDLE and 1<<OBJB_VISIBLE both resolve to 1
    ld      [hl+],a ; flags
    xor     a
    ld      [hl+],a ; x subpixel
    inc     l       ; x position
    ld      [hl+],a ; y subpixel
    inc     l       ; y position
    call    Math_Random
    ld      [hl+],a ; x velocity low
    ; sign extend
    rlca
    sbc     a
    ld      [hl+],a ; x velocity high
    call    Math_Random
    ld      [hl+],a ; y velocity low
    ; sign extend
    rlca
    sbc     a
    ld      [hl+],a ; y velocity high
    xor     a
    ;ld      a,EXPLOSION_HIT_WIDTH
    ld      [hl+],a ; object hitbox width (from center)
    ;ld      a,EXPLOSION_HIT_HEIGHT
    ld      [hl+],a ; object hitbox height (from bottom center)
    
    ldobjrp Explosion_Timer
    ld      a,EXPLOSION_FRAME_TIME
    ld      [hl+],a
    ld      [hl],0  ; Explosion_Frame

    ; fall through

Obj_Explosion_Idle:
    ldobjrp Explosion_Timer
    dec     [hl]
    jr      nz,Obj_Explosion_Draw
    ld      [hl],EXPLOSION_FRAME_TIME+1
    inc     l
    inc     [hl]
    ld      a,[hl]
    cp      4
    jr      nz,:+
    ldobjp  OBJ_ID
    ld      [hl],0
    ret
:   ; fall through
Obj_Explosion_Draw:
    ldobjp  OBJ_FLAGS
    bit     OBJB_VISIBLE,[hl]
    ret     z

    ld      a,[hOAMPos]
    ld      e,a
    ld      d,high(OAMBuffer)

    ; y pos
    ldobjp  OBJ_Y
    ld      a,[hl]
    add     8
    ld      b,a
    ld      a,[Level_CameraY]
    cpl
    inc     a
    add     b
    ld      [de],a
    inc     e
    ; x pos
    ldobjp  OBJ_X
    ld      a,[hl]
    ld      b,a
    ld      a,[Level_CameraX]
    cpl
    inc     a
    add     b
    ld      [de],a
    inc     e
    ; tile ID
    ldobjrp Explosion_Frame
    ld      a,[hl]
    ld      hl,Explosion_SpriteTiles
    add     l
    ld      l,a
    jr      nc,:+
    inc     h
:   ld      a,[hl]
    push    af
    ld      [de],a
    inc     e
    ; attribute
    ld      a,6 | %00000000
    ld      [de],a
    inc     e
    
    ; y pos
    ldobjp  OBJ_Y
    ld      a,[hl]
    add     8
    ld      b,a
    ld      a,[Level_CameraY]
    cpl
    inc     a
    add     b
    ld      [de],a
    inc     e
    ; x pos
    ldobjp  OBJ_X
    ld      a,[hl]
    add     8
    ld      b,a
    ld      a,[Level_CameraX]
    cpl
    inc     a
    add     b
    ld      [de],a
    inc     e
    ; tile ID
    pop     af
    add     2
    ld      [de],a
    inc     e
    ; attribute
    ld      a,6 | %00000000
    ld      [de],a
    inc     e

    ld      a,e
    ldh     [hOAMPos],a
    ret

Explosion_SpriteTiles:
    db  $60,$64,$68,$6C

rsreset
; =============================================================================
