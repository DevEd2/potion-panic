def IMP_HIT_WIDTH          = 6
def IMP_HIT_HEIGHT         = 12

rsreset
def IMP_STATE_INIT      rb
def IMP_STATE_FLOAT     rb
def IMP_STATE_SHOOT     rb
def IMP_STATE_DEFEAT    rb

rsreset
def Imp_Frame           rb
def Imp_InitXPos        rb
def Imp_InitYPos        rb
def Imp_Lifetime        rw
def Imp_ProjectileX     rw
def Imp_ProjectileVX    rw
def Imp_ProjectileY     rw
def Imp_ProjectileVY    rw
def Imp_ProjectileTTL   rb
def Imp_StateTimer      rb
assert _RS <= 16, "Object uses too much RAM! (Max size = $10, got {_RS})"

Obj_Imp:
; Routine pointers.
; OBJ_STATE is used as an index into this
Obj_Imp_RoutinePointers:
    dw  Obj_Imp_Init
    dw  Obj_Imp_Float
    dw  Obj_Imp_Shoot
    dw  Obj_Imp_Defeat

Obj_Imp_Init:
    ldobjp  OBJ_STATE
    ld      a,IMP_STATE_FLOAT
    ld      [hl+],a         ; object state
    ; ld      a,1<<OBJSB_VISIBLE ; IMP_STATE_IDLE and 1<<OBJB_VISIBLE both resolve to 1
    ld      [hl+],a         ; flags
    xor     a
    ld      [hl+],a         ; x subpixel
    ld      d,[hl]
    inc     l               ; x position
    ld      [hl+],a         ; y subpixel
    ld      e,[hl]
    inc     l               ; y position
    ld      [hl+],a         ; x velocity low
    ld      [hl+],a         ; x velocity high
    ld      [hl+],a         ; y velocity low
    ld      [hl+],a         ; y velocity high
    ld      a,IMP_HIT_WIDTH
    ld      [hl+],a     ; object hitbox width (from center)
    ld      a,IMP_HIT_HEIGHT
    ld      [hl+],a     ; object hitbox height (from bottom center)

    ldobjrp Imp_Frame
    ld      [hl],IMP_F_FLOAT_1 ; Imp_Frame
    inc     l
    ld      [hl],d                      ; Imp_InitXPos
    inc     l
    ld      [hl],e                      ; Imp_InitYPos
    inc     l
    xor     a
    ld      [hl+],a                     ; Imp_Lifetime
    ld      [hl+],a                     ; Imp_Lifetime
    ld      [hl+],a                     ; Imp_ProjectileX
    ld      [hl+],a                     ; Imp_ProjectileX
    ld      [hl+],a                     ; Imp_ProjectileVX
    ld      [hl+],a                     ; Imp_ProjectileVX
    ld      [hl+],a                     ; Imp_ProjectileY
    ld      [hl+],a                     ; Imp_ProjectileY
    ld      [hl+],a                     ; Imp_ProjectileVY
    ld      [hl+],a                     ; Imp_ProjectileVY
    ld      [hl+],a                     ; Imp_ProjectileTTL
    
    ; fall through

Obj_Imp_Float:
    ld      a,[FreezeObjects]
    and     a
    jp      nz,Obj_Imp_Draw
    ldobjrp Imp_Frame
    ldh     a,[hGlobalTick]
    rra
    rra
    rra
    and     1
    ld      [hl],a
    
    ldobjp  OBJ_X
    ld      a,[hl]
    push    af
    
    ldobjrp Imp_Lifetime
    ld      d,h
    ld      e,l
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    inc     hl
    ld      a,l
    ld      [de],a
    inc     e
    ld      a,h
    ld      [de],a
    ld      a,l
    inc     a
    jr      nz,:+
    push    hl
    ldobjp  OBJ_STATE
    ld      [hl],IMP_STATE_SHOOT
    ldobjrp Imp_StateTimer
    ld      [hl],60
    ; set projectile position
    ldobjp  OBJ_X
    ld      a,[hl+]
    ld      e,[hl]
    ld      d,a
    ldobjrp Imp_ProjectileX
    ld      [hl],e
    inc     l
    ld      [hl],d
    ldobjp  OBJ_Y
    ld      a,[hl+]
    ld      e,[hl]
    ld      d,a
    ldobjrp Imp_ProjectileY
    ld      [hl],e
    inc     l
    ld      [hl],d
    ; get distance from player position to imp position
    ldobjp  OBJ_X
    ld      a,[Player_XPos]
    sub     [hl]
    ld      b,a
    ldobjp  OBJ_Y
    ld      a,[Player_YPos]
    sub     [hl]
    ld      c,a
    call    Math_ATan2  ; calculate angle between points
    call    Math_SinCos ; get X and Y velocities
    push    hl
    ldobjrp Imp_ProjectileVX
    ld      [hl],e
    inc     l
    ld      [hl],d
    ldobjrp Imp_ProjectileVY
    pop     de
    ld      [hl],e
    inc     l
    ld      [hl],d    
    pop     hl
:   ld      a,l
    add     a
    call    Math_SinCos
    add     hl,hl
    add     hl,hl
    add     hl,hl
    add     hl,hl
    add     hl,hl
    ld      b,h
    ldobjrp Imp_InitYPos
    ld      a,[hl]
    add     b
    ld      b,a
    ldobjp  OBJ_Y
    ld      [hl],b
    
    ldobjrp Imp_Lifetime
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    srl     h
    rr      l
    ld      a,l
    call    Math_SinCos
    ld      d,h
    ld      e,l
    add     hl,hl
    add     hl,hl
    add     hl,hl
    add     hl,hl
    add     hl,hl
    add     hl,hl
    ld      b,h
    ldobjrp Imp_InitXPos
    ld      a,[hl]
    add     b
    ld      b,a
    ldobjp  OBJ_X
    ld      [hl],b
    
    ldobjp  OBJ_FLAGS
    pop     af
    ld      b,a
    ld      a,[Player_XPos]
    cp      b
    jr      nc,.flip
.noflip
    res     OBJB_XFLIP,[hl]
    jr      .skip
.flip
    set     OBJB_XFLIP,[hl]
.skip
    ;call    Obj_Imp_UpdateProjectile
    jp      Obj_Imp_Draw

Obj_Imp_Shoot:
    ldobjrp Imp_Frame
    ld      [hl],IMP_F_SHOOT
    ldobjrp Imp_StateTimer
    dec     [hl]
    jr      nz,Obj_Imp_Draw
    ldobjp  OBJ_STATE
    ld      [hl],IMP_STATE_FLOAT
    ;call    Obj_Imp_UpdateProjectile
    jr      Obj_Imp_Draw

Obj_Imp_Defeat:
    ld      a,[FreezeObjects]
    and     a
    jr      nz,Obj_Imp_Draw
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
    jr      nz,Obj_Imp_Draw
    ldobjp  OBJ_Y
    ld      a,[hl]
    sub     16
    cp      $f0
    jr      c,Obj_Imp_Draw
    ldobjp  OBJ_ID
    ld      [hl],0
    ret

Obj_Imp_UpdateProjectile:
    ; TODO: This is broken
    ldobjrp Imp_ProjectileX
    push    hl
    ld      a,[hl+]
    ld      e,a
    ld      a,[hl+]
    and     a
    jr      z,.abort    ; bail out if X pos = 0 (denotes inactive projectile)
    ld      d,a
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    add     hl,de
    pop     de
    ld      a,l
    ld      [de],a
    inc     e
    ld      a,h
    ld      [de],a
    
    ldobjrp Imp_ProjectileY
    push    hl
    ld      a,[hl+]
    ld      e,a
    and     a
    jr      z,.abort    ; bail out if Y pos = 0 (denotes inactive projectile)
    ld      a,[hl+]
    ld      d,a
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    add     hl,de
    pop     de
    ld      a,l
    ld      [de],a
    inc     e
    ld      a,h
    ld      [de],a
    ret
.abort
    pop     hl
    ret

Obj_Imp_Draw:
    ldobjp  OBJ_FLAGS
    ;bit     OBJB_VISIBLE,[hl]
    ;ret     z
    ld      c,[hl]

    ldobjrp Imp_Frame
    ld      l,[hl]
    ld      h,0
    add     hl,hl   ; x2
    ld      de,Obj_Imp_Frames
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
        ld      a,[GFXPos_Imp]
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
    ; draw projectile
    ldobjrp Imp_ProjectileY+1
    ld      a,[hl]
    and     a
    jr      z,.skip
    sub     8
    ld      [de],a
    inc     e
    ldobjrp Imp_ProjectileX+1
    ld      a,[hl]
    and     a
    jr      z,.skip
    sub     4
    ld      [de],a
    inc     e
    ld      a,$7c
    ld      [de],a
    inc     e
    ld      a,6
    ld      [de],a
    inc     e
.skip
    ld      a,e
    ldh     [hOAMPos],a
    ; fall through
    
Imp_CheckDefeat:
    ldobjp  OBJ_STATE
    ld      a,[hl]
    cp      IMP_STATE_DEFEAT
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
    ld      [hl],IMP_STATE_DEFEAT
    inc     l
    set     OBJB_YFLIP,[hl]
    ld      hl,Level_EnemyCount
    dec     [hl]
    ldobjrp Imp_Frame
    ld      [hl],IMP_F_DEFEAT
    ret

rsreset
def IMP_F_FLOAT_1      rb
def IMP_F_FLOAT_2      rb
def IMP_F_SHOOT        rb
def IMP_F_DEFEAT       rb

Obj_Imp_Frames:
    dw      SprDef_Imp_Float1
    dw      SprDef_Imp_Float2
    dw      SprDef_Imp_Shoot
    dw      SprDef_Imp_Defeat

SprDef_Imp_Float1:
    dw  .left,.right
.left
    ; sprite 1
    db  0                           ; left Y pos
    db  0                           ; left X pos
    db  0                           ; left tile ID
    db  4 | OAMF_BANK1              ; left attributes
    ; sprite 2
    db  0                           ; right Y pos
    db  8                           ; right X pos
    db  2                           ; right tile ID
    db  4 | OAMF_BANK1              ; right attributes
.right
    ; sprite 1
    db  0                           ; left Y pos
    db  0                           ; left X pos
    db  2                           ; left tile ID
    db  4 | OAMF_BANK1 | OAMF_XFLIP ; left attributes
    ; sprite 2
    db  0                           ; right Y pos
    db  8                           ; right X pos
    db  0                           ; right tile ID
    db  4 | OAMF_BANK1 | OAMF_XFLIP ; right attributes

SprDef_Imp_Float2:
    dw  .left,.right
.left
    ; sprite 1
    db  0                           ; left Y pos
    db  0                           ; left X pos
    db  4                           ; left tile ID
    db  4 | OAMF_BANK1              ; left attributes
    ; sprite 2
    db  0                           ; right Y pos
    db  8                           ; right X pos
    db  6                           ; right tile ID
    db  4 | OAMF_BANK1              ; right attributes
.right
    ; sprite 1
    db  0                           ; left Y pos
    db  0                           ; left X pos
    db  6                           ; left tile ID
    db  4 | OAMF_BANK1 | OAMF_XFLIP ; left attributes
    ; sprite 2
    db  0                           ; right Y pos
    db  8                           ; right X pos
    db  4                           ; right tile ID
    db  4 | OAMF_BANK1 | OAMF_XFLIP ; right attributes


SprDef_Imp_Shoot:
    dw  .left,.right
.left
    ; sprite 1
    db  0                           ; left Y pos
    db  0                           ; left X pos
    db  8                           ; left tile ID
    db  4 | OAMF_BANK1              ; left attributes
    ; sprite 2
    db  0                           ; right Y pos
    db  8                           ; right X pos
    db  10                           ; right tile ID
    db  4 | OAMF_BANK1              ; right attributes
.right
    ; sprite 1
    db  0                           ; left Y pos
    db  0                           ; left X pos
    db  10                          ; left tile ID
    db  4 | OAMF_BANK1 | OAMF_XFLIP ; left attributes
    ; sprite 2
    db  0                           ; right Y pos
    db  8                           ; right X pos
    db  8                           ; right tile ID
    db  4 | OAMF_BANK1 | OAMF_XFLIP ; right attributes
    
    
SprDef_Imp_Defeat:
    dw  .left,.right
.left
    ; sprite 1
    db  0                           ; left Y pos
    db  0                           ; left X pos
    db  12                          ; left tile ID
    db  4 | OAMF_BANK1              ; left attributes
    ; sprite 2
    db  0                           ; right Y pos
    db  8                           ; right X pos
    db  14                          ; right tile ID
    db  4 | OAMF_BANK1              ; right attributes
.right
    ; sprite 1
    db  0                           ; left Y pos
    db  0                           ; left X pos
    db  14                          ; left tile ID
    db  4 | OAMF_BANK1 | OAMF_XFLIP ; left attributes
    ; sprite 2
    db  0                           ; right Y pos
    db  8                           ; right X pos
    db  12                          ; right tile ID
    db  4 | OAMF_BANK1 | OAMF_XFLIP ; right attributes

; =============================================================================

section "Enemy GFX - Imp",romx
ObjGFX_Imp:    incbin  "GFX/Enemies/imp.2bpp.wle"

