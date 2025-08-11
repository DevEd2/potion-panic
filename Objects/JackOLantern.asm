def JACKOLANTERN_HIT_WIDTH          = 6
def JACKOLANTERN_HIT_HEIGHT         = 12

rsreset
def JACKOLANTERN_STATE_INIT     rb
def JACKOLANTERN_STATE_FLOAT    rb
def JACKOLANTERN_STATE_DEFEAT   rb

rsreset
def JackOLantern_Frame          rb
def JackOLantern_InitYPos       rb
def JackOLantern_Lifetime       rb
assert _RS <= 16, "Object uses too much RAM! (Max size = $10, got {_RS})"

Obj_JackOLantern:
; Routine pointers.
; OBJ_STATE is used as an index into this
Obj_JackOLantern_RoutinePointers:
    dw  Obj_JackOLantern_Init
    dw  Obj_JackOLantern_Float
    dw  Obj_JackOLantern_Defeat

Obj_JackOLantern_Init:
    ldobjp  OBJ_STATE
    ld      a,JACKOLANTERN_STATE_FLOAT
    ld      [hl+],a         ; object state
    ; ld      a,1<<OBJSB_VISIBLE ; JACKOLANTERN_STATE_IDLE and 1<<OBJB_VISIBLE both resolve to 1
    ld      [hl+],a         ; flags
    xor     a
    ld      [hl+],a         ; x subpixel
    inc     l               ; x position
    ld      [hl+],a         ; y subpixel
    ld      e,[hl]  
    inc     l               ; y position
    ld      [hl],low(-$100)  ; x velocity low
    inc     l
    ld      [hl],high(-$100) ; x velocity high
    inc     l
    ld      [hl+],a         ; y velocity low
    ld      [hl+],a         ; y velocity high
    ld      a,JACKOLANTERN_HIT_WIDTH
    ld      [hl+],a     ; object hitbox width (from center)
    ld      a,JACKOLANTERN_HIT_HEIGHT
    ld      [hl+],a     ; object hitbox height (from bottom center)

    ldobjrp JackOLantern_Frame
    ld      [hl],JACKOLANTERN_F_FLOAT_1 ; JackOLantern_Frame
    inc     l
    ld      [hl],e                      ; JackOLantern_InitYPos
    inc     l
    ld      [hl],0                      ; JackOLantern_Lifetime
    
    ; fall through

Obj_JackOLantern_Float:
    ld      a,[FreezeObjects]
    and     a
    jp      nz,Obj_JackOLantern_Draw
    ldobjrp JackOLantern_Frame
    ldh     a,[hGlobalTick]
    rra
    rra
    rra
    and     1
    ld      [hl],a
    
    ldobjrp JackOLantern_Lifetime
    inc     [hl]
    ld      a,[hl]
    add     a
    call    Math_SinCos
    add     hl,hl
    add     hl,hl
    add     hl,hl
    ld      b,h
    ldobjrp JackOLantern_InitYPos
    ld      a,[hl]
    add     b
    ld      b,a
    ldobjp  OBJ_Y
    ld      [hl],b
    
    ; TODO
    jp      Obj_JackOLantern_Draw

Obj_JackOLantern_Defeat:
    ld      a,[FreezeObjects]
    and     a
    jr      nz,Obj_JackOLantern_Draw
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
    jr      nz,Obj_JackOLantern_Draw
    ldobjp  OBJ_Y
    ld      a,[hl]
    sub     16
    cp      $f0
    jr      c,Obj_JackOLantern_Draw
    ldobjp  OBJ_ID
    ld      [hl],0
    ret
    ; fall through

Obj_JackOLantern_Draw:
    ldobjp  OBJ_FLAGS
    ;bit     OBJB_VISIBLE,[hl]
    ;ret     z
    ld      c,[hl]

    ldobjrp JackOLantern_Frame
    ld      l,[hl]
    ld      h,0
    add     hl,hl   ; x2
    ld      de,Obj_JackOLantern_Frames
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
        ld      a,[GFXPos_JackOLantern]
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
    
JackOLantern_CheckDefeat:
    ldobjp  OBJ_STATE
    ld      a,[hl]
    cp      JACKOLANTERN_STATE_DEFEAT
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
    ld      [hl],JACKOLANTERN_STATE_DEFEAT
    inc     l
    set     OBJB_YFLIP,[hl]
    ld      hl,Level_EnemyCount
    dec     [hl]
    ldobjrp JackOLantern_Frame
    ld      [hl],JACKOLANTERN_F_DEFEAT
    ret

rsreset
def JACKOLANTERN_F_FLOAT_1      rb
def JACKOLANTERN_F_FLOAT_2      rb
def JACKOLANTERN_F_TURN         rb
def JACKOLANTERN_F_DEFEAT       rb

Obj_JackOLantern_Frames:
    dw      SprDef_JackOLantern_Float1
    dw      SprDef_JackOLantern_Float2
    dw      SprDef_JackOLantern_Turn
    dw      SprDef_JackOLantern_Defeat

SprDef_JackOLantern_Float1:
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

SprDef_JackOLantern_Float2:
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


SprDef_JackOLantern_Turn:
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
    
    
SprDef_JackOLantern_Defeat:
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

section "Enemy GFX - Jack O' Lantern",romx
ObjGFX_JackOLantern:    incbin  "GFX/Enemies/jackolantern.2bpp.wle"
ObjPal_JackOLantern:    incbin  "GFX/Enemies/jackolantern.pal"
