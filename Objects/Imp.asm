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
    ld      [hl],d             ; Imp_InitXPos
    inc     l
    ld      [hl],e             ; Imp_InitYPos
    inc     l
    xor     a
    ld      [hl+],a            ; Imp_Lifetime
    ld      [hl+],a            ; Imp_Lifetime
    push    hl
    call    Math_Random
    pop     hl
    and     $7f
    add     $80
    ld      [hl],a            ; Imp_StateTimer

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
    
    ldobjrp Imp_StateTimer
    dec     [hl]
    jr      nz,:+
    ldobjp  OBJ_STATE
    ld      [hl],IMP_STATE_SHOOT
    ldobjrp Imp_StateTimer
    ld      [hl],60
    ; create projectile
    ldobjp  OBJ_X
    ld      a,[hl+]
    ld      d,a
    inc     l
    ld      a,[hl+]
    ld      e,a
    ld      b,OBJID_ImpFireball
    call    CreateObject
:   

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
    jr      Obj_Imp_Draw
.flip
    set     OBJB_XFLIP,[hl]
    jr      Obj_Imp_Draw

Obj_Imp_Shoot:
    ldobjrp Imp_Frame
    ld      [hl],IMP_F_SHOOT
    ldobjrp Imp_StateTimer
    dec     [hl]
    jr      nz,Obj_Imp_Draw
    ldobjp  OBJ_STATE
    ld      [hl],IMP_STATE_FLOAT
    ldobjrp Imp_StateTimer
    push    hl
    call    Math_Random
    pop     hl
    and     $7f
    add     $80
    ld      [hl+],a            ; Imp_StateTimer
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
    ld      a,e
    ldh     [hOAMPos],a
    
    ld      a,[FreezeObjects]
    and     a
    ret     nz
    ; fall through

Imp_CheckHurtPlayer:
    ldobjp  OBJ_STATE
    ld      a,[hl]
    cp      IMP_STATE_DEFEAT
    ret     z
    call    Object_CheckPlayerIntersecting
    jr      nc,Imp_CheckDefeat
    ld      a,[Player_Flags]
    bit     BIT_PLAYER_FAT,a
    jr      z,:+
    
    ld      hl,Player_XVel
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    add     hl,hl
    add     hl,hl
    ld      d,h
    ld      e,l
    ldobjp  OBJ_VX
    ld      [hl],e
    inc     l
    ld      [hl],d
    
    ld      de,-$400
    ldobjp  OBJ_VY
    ld      [hl],e
    inc     l
    ld      [hl],d
    
    ld      e,SFX_BELLY_BUMP_CH2
    call    DSFX_PlaySound
    ld      e,SFX_BELLY_BUMP_CH4
    call    DSFX_PlaySound
    
    ldobjp  OBJ_STATE
    ld      [hl],IMP_STATE_DEFEAT
    inc     l
    set     OBJB_YFLIP,[hl]
    ld      hl,Level_EnemyCount
    dec     [hl]
    ld      hl,Player_XVel
    xor     a
    ld      [hl+],a
    ld      [hl],a
    ld      a,4
    ld      [Level_HitstopTimer],a
    ld      a,low(ScreenShake_Fat_HitEnemy)
    ld      [Level_ScreenShakePtr],a
    ld      a,high(ScreenShake_Fat_HitEnemy)
    ld      [Level_ScreenShakePtr+1],a
    ret
:   call    HurtPlayer

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
    jp      Object_ProcessDrops

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

