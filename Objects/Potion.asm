rsreset
def POTION_STATE_INIT    rb
def POTION_STATE_IDLE    rb
rsreset
assert _RS <= 16, "Object uses too much RAM! (Max size = $10, got {_RS})"

def POTION_HIT_WIDTH = 8
def POTION_HIT_HEIGHT = 12

def POTION_DROP_CHANCE = 20 percent

Obj_Potion:
; Routine pointers.
; OBJ_STATE is used as an index into this
Obj_Potion_RoutinePointers:
    dw  Obj_Potion_Init
    dw  Obj_Potion_Idle

Obj_Potion_Init:
    ldobjp  OBJ_STATE
    ld      a,POTION_STATE_IDLE
    ld      [hl+],a ; object state
    ; ld      a,1<<OBJB_VISIBLE ; POTION_STATE_IDLE and 1<<OBJB_VISIBLE both resolve to 1
    ld      [hl+],a ; flags
    xor     a
    ld      [hl+],a ; x subpixel
    inc     l       ; x position
    ld      [hl+],a ; y subpixel
    inc     l       ; y position
    ld      [hl+],a ; x velocity low
    ld      [hl+],a ; x velocity high
    ld      [hl+],a ; y velocity low
    ld      a,high(-$200)
    ld      [hl+],a ; y velocity high
    ld      a,POTION_HIT_WIDTH
    ld      [hl+],a ; object hitbox width (from center)
    ld      a,POTION_HIT_HEIGHT
    ld      [hl+],a ; object hitbox height (from bottom center)
    
    ; floor check
:   ldobjp  OBJ_X
    ld      a,[hl]
    and     $f0
    ld      b,a
    inc     l
    inc     l
    ld      a,[hl]
    add     8
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
    ldobjp  OBJ_Y
    ld      a,[hl]
    dec     a
    ld      [hl],a
    jr      :-
.skipfloor
    
    ; fall through

Obj_Potion_Idle:
    ; apply gravity
    ldobjp  OBJ_VY
    ld      a,[hl+]
    ld      d,h
    ld      e,l
    ld      h,[hl]
    ld      l,a
    ld      bc,PLAYER_GRAVITY
    add     hl,bc
    ld      a,h
    ld      [de],a
    dec     e
    ld      a,l
    ld      [de],a
    ; floor check
    ldobjp  OBJ_X
    ld      a,[hl]
    and     $f0
    ld      b,a
    inc     l
    inc     l
    ld      a,[hl]
    add     high(PLAYER_GRAVITY) + 8
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
    ;ldobjp  OBJ_Y
    ;ld      a,[hl]
    ;and     $f0
    ;sub     8
    ;ld      [hl],a
    ldobjp  OBJ_VY
    ld      d,h
    ld      e,l
    ;ld      a,[hl+]
    ;ld      h,[hl]
    ;ld      l,a
    ld      hl,0
    ld      a,l
    ld      [de],a
    inc     e
    ld      a,h
    ld      [de],a
    ; TODO
.skipfloor
    call    Object_CheckPlayerIntersecting
    jr      nc,Obj_Potion_Draw
    ; delete object
    ldobjp  OBJ_ID
    ld      [hl],0
    ; TODO: Give potion effect

    ; fall through
Obj_Potion_Draw:
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
    ld      a,$4a
    ld      [de],a
    inc     e
    ; attribute
    ld      a,1 | %00000000
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
    ld      a,$4c
    ld      [de],a
    inc     e
    ; attribute
    ld      a,1 | %00000000
    ld      [de],a
    inc     e

    ld      a,e
    ldh     [hOAMPos],a
    ; TODO
    ret
