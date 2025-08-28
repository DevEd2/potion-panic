def FIREBALL_HIT_WIDTH      = 6
def FIREBALL_HIT_HEIGHT     = 12

rsreset
def FIREBALL_STATE_INIT     rb
def FIREBALL_STATE_FLOAT    rb

rsreset
assert _RS <= 16, "Object uses too much RAM! (Max size = $10, got {_RS})"

Obj_Fireball:
; Routine pointers.
; OBJ_STATE is used as an index into this
Obj_Fireball_RoutinePointers:
    dw  Obj_Fireball_Init
    dw  Obj_Fireball_Float

Obj_Fireball_Init:
    ldobjp  OBJ_STATE
    ld      a,FIREBALL_STATE_FLOAT
    ld      [hl+],a         ; object state
    ; ld      a,1<<OBJSB_VISIBLE ; FIREBALL_STATE_FLOAT and 1<<OBJB_VISIBLE both resolve to 1
    ld      [hl+],a         ; flags
    xor     a
    ld      [hl+],a         ; x subpixel
    ld      d,[hl]
    inc     l               ; x position
    ld      [hl+],a         ; y subpixel
    ld      a,[hl]
    sub     8
    ld      e,a
    ld      [hl+],a         ; y position
    ; calculate velocity
    ld      a,[Player_XPos]
    sub     d
    ld      b,a
    ld      a,[Player_YPos]
    sub     e
    ld      c,a
    push    hl
    call    Math_ATan2
    call    Math_SinCos
    pop     bc
    ld      a,e
    ld      [bc],a
    inc     c
    ld      a,d
    ld      [bc],a
    inc     c
    ld      a,l
    ld      [bc],a
    inc     c
    ld      a,h
    ld      [bc],a
    inc     c
    ld      h,b
    ld      l,c
    xor     a
    ld      [hl+],a     ; object hitbox width (from center)
    ld      [hl+],a     ; object hitbox height (from center)

    ; fall through

Obj_Fireball_Float:
    ld      a,[FreezeObjects]
    and     a
    jp      nz,Obj_Fireball_Draw
    ; check for terrain collision
    ldobjp  OBJ_X
    ld      a,[hl]
    and     $f0
    ld      b,a
    inc     l
    inc     l
    ld      a,[hl]
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
    dec     a                       ; have we collided with a solid tile?
    jr      nz,Obj_Fireball_Draw    ; if not, skip ahead
    ldobjp  OBJ_ID
    ld      [hl],OBJID_Explosion    ; turn this object into an explosion
    inc     l
    ld      [hl],0                  ; force object to reinitialize itself on the next tick
    ret
Obj_Fireball_Draw:
    ldobjp  OBJ_FLAGS
    bit     OBJB_VISIBLE,[hl]
    ret     z
    ld      a,[hOAMPos]
    ld      e,a
    ld      d,high(OAMBuffer)
    ; y pos
    ldobjp  OBJ_Y
    ld      b,[hl]
    ld      a,[Level_CameraY]
    cpl
    inc     a
    add     b
    add     8
    ld      [de],a
    inc     e
    ; x pos
    ldobjp  OBJ_X
    ld      a,[hl]
    add     4
    ld      b,a
    ld      a,[Level_CameraX]
    cpl
    inc     a
    add     b
    ld      [de],a
    inc     e
    ; tile ID
    ld      a,$7c
    ld      [de],a
    inc     e
    ; attribute
    ld      a,6
    ld      [de],a
    inc     e
    ld      a,e
    ldh     [hOAMPos],a
    ret


; =============================================================================

section "Enemy GFX - Fireball",romx
ObjGFX_Fireball:    incbin  "GFX/Enemies/imp.2bpp.wle"

