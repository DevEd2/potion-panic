def SLIME_IDLE_TIME_MIN     = 30
def SLIME_IDLE_TIME_MAX     = 60
def SLIME_CROAK_TIME_MIN    = 30
def SLIME_CROAK_TIME_MAX    = 90
def SLIME_PREHOP_TIME       = 16

def SLIME_HIT_WIDTH         = 6
def SLIME_HIT_HEIGHT        = 10

def SLIME_HOP_SPEED         = $00c0
def SLIME_HOP_HEIGHT_SMALL  = $0180
def SLIME_HOP_HEIGHT_BIG    = $0300
def SLIME_GRAVITY           = $0018

rsreset
def SLIME_STATE_INIT    rb
def SLIME_STATE_IDLE    rb
def SLIME_STATE_HOP     rb
def SLIME_STATE_TONGUE  rb
def SLIME_STATE_PREHOP  rb
def SLIME_STATE_DEFEAT  rb

rsreset
def Slime_IdleTimer     rb
def Slime_StateTimer    rb
def Slime_Frame         rb
def Slime_AnimSpeed     rb
def Slime_AnimTimer     rb
assert _RS <= 16, "Object uses too much RAM! (Max size = $10, got {_RS})"

Obj_Slime:
; Routine pointers.
; OBJ_STATE is used as an index into this
Obj_Slime_RoutinePointers:
    dw  Obj_Slime_Init
    dw  Obj_Slime_Idle
    dw  Obj_Slime_Midair
    dw  Obj_Slime_Defeat

Obj_Slime_Init:
    ldobjp  OBJ_STATE
    ld      a,SLIME_STATE_HOP
    ld      [hl+],a ; object state
    ; ld      a,1<<OBJSB_VISIBLE ; SLIME_STATE_IDLE and 1<<OBJB_VISIBLE both resolve to 1
    ld      [hl+],a ; flags
    xor     a
    ld      [hl+],a ; x subpixel
    inc     l       ; x position
    ld      [hl+],a ; y subpixel
    inc     l       ; y position
    ld      [hl+],a ; x velocity low
    ld      [hl+],a ; x velocity high
    ld      [hl+],a ; y velocity low
    ld      [hl+],a ; y velocity high
    ld      a,SLIME_HIT_WIDTH
    ld      [hl+],a ; object hitbox width (from center)
    ld      a,SLIME_HIT_HEIGHT
    ld      [hl+],a ; object hitbox height (from bottom center)

    ldobjrp Slime_IdleTimer
    xor     a
    ld      [hl+],a             ; Slime_IdleTimer
    ld      [hl+],a             ; Slime_StateTimer
    ld      [hl],SLIME_F_IDLE1  ; Slime_Frame
    inc     l
    ld      [hl+],a             ; Slime_AnimSpeed
    ld      [hl+],a             ; Slime_AnimTimer
    ; fall through

Obj_Slime_Idle:
    ; TODO
    jp      Obj_Slime_Draw

Obj_Slime_Midair:
    ld      a,[FreezeObjects]
    and     a
    jp      nz,Obj_Slime_Draw
    ; do gravity
    ldobjp  OBJ_VY
    ld      d,h
    ld      e,l
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    ld      bc,SLIME_GRAVITY
    add     hl,bc
    ld      c,h
    ld      a,l
    ld      [de],a
    inc     e
    ld      a,h
    ld      [de],a
    bit     7,h             ; is vertical velocity negative?
    jr      nz,.skipfloor   ; if not, skip floor check
    ; floor check
    ldobjp  OBJ_X
    ld      a,[hl]
    and     $f0
    ld      b,a
    inc     l
    inc     l
    ld      a,[hl]
    add     c
    and     $f0
    ldh     [hTemp1],a
    swap    a
    or      b
    ld      l,a
    ld      h,high(Level_Map)
    ld      a,[hl]
    ld      c,a
    ld      b,0
    call    GetCollisionIndex
    ld      a,b
    and     a                   ; is tile nonsolid?
    jr      z,.skipfloor        ; if yes, skip
    cp      COLLISION_SOLID     ; is tile solid?
    jr      z,.floor            ; if yes, run floor reset routine
    cp      COLLISION_TOPSOLID  ; is tile topsolid?
    jr      nz,.skipfloor       ; if not, skip
.floor
    ldobjp  OBJ_STATE
    ld      [hl],SLIME_STATE_IDLE
    ldobjrp Slime_Frame
    ld      [hl],SLIME_F_IDLE1
    ldobjp  OBJ_YSUB
    xor     a
    ld      [hl+],a ; y pos low
    ldh     a,[hTemp1]
    ld      [hl+],a
    ld      [hl+],a ; x velocity low
    ld      [hl+],a ; x velocity high
    ld      [hl+],a ; y velocity low
    ld      [hl+],a ; y velocity high
.skipfloor
    ldobjp  OBJ_VX
    ld      a,[hl+]
    ld      d,[hl]
    ld      e,a
    ld      a,d
    or      e
    jp      z,Obj_Slime_Draw ; skip if horizontal speed is zero
    ldobjp  OBJ_X
    ld      a,[hl]
    bit     7,d
    jr      nz,:+
    add     4
    jr      :++
:   sub     4
:   and     $f0
    ld      b,a
    inc     l
    inc     l
    ld      a,[hl]
    sub     8
    and     $f0
    swap    a
    or      b
    ld      l,a
    ld      h,high(Level_Map)
    ld      a,[hl]
    ld      c,a
    ld      b,0
    call    GetCollisionIndex
    ld      a,b
    cp      COLLISION_SOLID
    jp      nz,Obj_Slime_Draw
    ldobjp  OBJ_VX
    push    hl
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    call    Math_Neg16
    pop     de
    ld      a,l
    ld      [de],a
    inc     e
    ld      a,h
    ld      [de],a
    ldobjp  OBJ_FLAGS
    ld      a,[hl]
    xor     1<<OBJB_XFLIP
    ld      [hl],a
    jp      Obj_Slime_Draw

Obj_Slime_Defeat:
    ld      a,[FreezeObjects]
    and     a
    jr      nz,Obj_Slime_Draw
    ldobjp  OBJ_VY
    push    hl
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    ld      bc,PLAYER_GRAVITY
    add     hl,bc
    pop     de
    ld      a,l
    ld      [de],a
    inc     e
    ld      a,h
    ld      [de],a
    bit     7,h
    jr      nz,Obj_Slime_Draw
    ldobjp  OBJ_Y
    ld      a,[hl]
    sub     16
    cp      $f0
    jr      c,Obj_Slime_Draw
    ldobjp  OBJ_ID
    ld      [hl],0
    ret
    
    ; fall through

Obj_Slime_Draw:
    ldobjp  OBJ_FLAGS
    ;bit     OBJB_VISIBLE,[hl]
    ;ret     z
    ld      c,[hl]

    ldobjrp Slime_Frame
    ld      l,[hl]
    ld      h,0
    add     hl,hl   ; x2
    ld      de,Obj_Slime_Frames
    add     hl,de
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    bit     OBJB_XFLIP,c
    jr      z,:+
    inc     hl
    inc     hl
:   ld      a,[hl+]
    ld      h,[hl]
    ld      l,a

    ld      a,[hOAMPos]
    ld      e,a
    ld      d,high(OAMBuffer)

    rept    2
        ; y pos
        ld      a,[hl+]
        ld      b,a
        push    hl
        ldobjp  OBJ_Y
        ld      a,[hl]
        pop     hl
        add     b
        ld      b,a
        ld      a,[Level_CameraY]
        cpl
        inc     a
        add     b
        ld      [de],a
        inc     e
        ; x pos
        ld      a,[hl+]
        ld      b,a
        push    hl
        ldobjp  OBJ_X
        ld      a,[hl]
        pop     hl
        add     b
        ld      b,a
        ld      a,[Level_CameraX]
        cpl
        inc     a
        add     b
        ld      [de],a
        inc     e
        ; tile ID
        ld      a,[hl+]
        ld      b,a
        ld      a,[GFXPos_Slime]
        add     b
        ld      [de],a
        inc     e
        ; attribute
        ld      a,[hl+]
        bit     OBJB_YFLIP,c
        jr      z,:+
        or      OAMF_YFLIP
:       ld      [de],a
        inc     e
    endr
    ld      a,e
    ldh     [hOAMPos],a
    ; fall through
    
Slime_CheckDefeat:
    ldobjp  OBJ_STATE
    ld      a,[hl]
    cp      SLIME_STATE_DEFEAT
    ret     z
    call    Obj_CheckProjectileIntersecting
    ret     nc
    ld      a,l
    add     PROJECTILE_VX+1
    ld      l,a
    bit     7,[hl]
    ld      hl,$100
    call    nz,Math_Neg16
    ld      d,h
    ld      e,l
    ldobjp  OBJ_VX
    ld      [hl],e
    inc     l
    ld      [hl],d
    inc     l
    ld      [hl],low(-$200)
    inc     l
    ld      [hl],high(-$200)
    ldobjp  OBJ_STATE
    ld      [hl],SLIME_STATE_DEFEAT
    inc     l
    set     OBJB_YFLIP,[hl]
    ld      hl,Level_EnemyCount
    dec     [hl]
    ret

rsreset
def SLIME_F_IDLE1        rb

Obj_Slime_Frames:
    dw      SprDef_Slime_Idle1

SprDef_Slime_Idle1:
    dw  .left,.right
.left
    ; sprite 1
    db  0                           ; left Y pos
    db  0                           ; left X pos
    db  0                           ; left tile ID
    db  3 | OAMF_BANK1              ; left attributes
    ; sprite 2
    db  0                           ; right Y pos
    db  8                           ; right X pos
    db  2                           ; right tile ID
    db  3 | OAMF_BANK1              ; right attributes
.right
    ; sprite 1
    db  0                           ; left Y pos
    db  0                           ; left X pos
    db  2                           ; left tile ID
    db  3 | OAMF_BANK1 | OAMF_XFLIP ; left attributes
    ; sprite 2
    db  0                           ; right Y pos
    db  8                           ; right X pos
    db  0                           ; right tile ID
    db  3 | OAMF_BANK1 | OAMF_XFLIP ; right attributes
    

; =============================================================================

section "Enemy GFX - Slime",romx
ObjGFX_Slime:    incbin  "GFX/Enemies/slime.2bpp.wle"
