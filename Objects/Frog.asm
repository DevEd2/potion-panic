def FROG_IDLE_TIME_MIN = 120
def FROG_IDLE_TIME_MAX = 240
def FROG_CROAK_TIME_MIN = 30
def FROG_CROAK_TIME_MAX = 90

rsreset
def FROG_STATE_INIT     rb
def FROG_STATE_IDLE     rb
def FROG_STATE_HOP      rb
def FROG_STATE_TOUNGE   rb
def FROG_STATE_DEFEAT   rb

rsreset
def Frog_IdleTimer      rb
def Frog_StateTimer     rb
def Frog_AnimSpeed      rb
def Frog_AnimTimer      rb
def Frog_Frame          rb
def Frog_ToungeLength   rb
assert _RS <= 16, "Object uses too much RAM! (Max size = $10, got {_RS})"

Obj_Frog:
; Routine pointers.
; OBJ_STATE is used as an index into this
Obj_Frog_RoutinePointers:
    dw  Obj_Frog_Init
    dw  Obj_Frog_Idle
    dw  Obj_Frog_Hop
    dw  Obj_Frog_Tounge
    dw  Obj_Frog_Defeat

Obj_Frog_Init:
    ldobjp  OBJ_STATE
    ld      a,FROG_STATE_IDLE
    ld      [hl],a
    ; fall through

Obj_Frog_Idle:
    ; TODO
    jr      Obj_Frog_Draw

Obj_Frog_Hop:
    ; TODO
    ret

Obj_Frog_Tounge:
    ; TODO
    ret

Obj_Frog_Defeat:
    ; TODO
    ret

Obj_Frog_Draw:
    ld      a,[GFXPos_Frog]
    ld      c,a
    ld      a,[hOAMPos]
    ld      e,a
    ld      d,high(OAMBuffer)
    ld      hl,SprDef_Frog_Idle.left ; TODO: select sprite based on facing direction
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
        add     c
        ld      [de],a
        inc     e
        ; attribute
        ld      a,[hl+]
        ld      [de],a
        inc     e
    endr
    ld      a,e
    ldh     [hOAMPos],a
    ret

SprDef_Frog_Idle:
    dw  .left,.right
.left
    ; sprite 1
    db  0                           ; left Y pos
    db  0                           ; left X pos
    db  0                           ; left tile ID
    db  2 | OAMF_BANK1              ; left attributes
    ; sprite 2
    db  0                           ; right Y pos
    db  8                           ; right X pos
    db  2                           ; right tile ID
    db  2 | OAMF_BANK1              ; right attributes
.right
    ; sprite 1
    db  0                           ; left Y pos
    db  0                           ; left X pos
    db  2                           ; left tile ID
    db  2 | OAMF_BANK1 | OBJF_XFLIP ; left attributes
    ; sprite 2
    db  0                           ; right Y pos
    db  8                           ; right X pos
    db  0                           ; right tile ID
    db  2 | OAMF_BANK1 | OBJF_XFLIP ; right attributes

SprDef_Frog_IdleCroak:
    dw  .left,.right
.left
    ; sprite 1
    db  0                           ; left Y pos
    db  0                           ; left X pos
    db  4                           ; left tile ID
    db  2 | OAMF_BANK1              ; left attributes
    ; sprite 2
    db  0                           ; right Y pos
    db  8                           ; right X pos
    db  2                           ; right tile ID
    db  2 | OAMF_BANK1              ; right attributes
.right
    ; sprite 1
    db  0                           ; left Y pos
    db  0                           ; left X pos
    db  2                           ; tile ID
    db  2 | OAMF_BANK1 | OBJF_XFLIP ; attributes
    ; sprite 2
    db  0                           ; right Y pos
    db  8                           ; right X pos
    db  4                           ; right tile ID
    db  2 | OAMF_BANK1 | OBJF_XFLIP ; right attributes

SprDef_Frog_IdleBlink:
    dw  .left,.right
.left
    ; sprite 1
    db  0                           ; left Y pos
    db  0                           ; left X pos
    db  6                           ; left tile ID
    db  2 | OAMF_BANK1              ; left attributes
    ; sprite 2
    db  0                           ; right Y pos
    db  8                           ; right X pos
    db  2                           ; right tile ID
    db  2 | OAMF_BANK1              ; right attributes
.right
    ; sprite 1
    db  0                           ; left Y pos
    db  0                           ; left X pos
    db  2                           ; left tile ID
    db  2 | OAMF_BANK1 | OBJF_XFLIP ; left attributes
    ; sprite 2
    db  0                           ; right Y pos
    db  8                           ; right X pos
    db  6                           ; righttile ID
    db  2 | OAMF_BANK1 | OBJF_XFLIP ; rightattributes

SprDef_Frog_PreHop:
    dw  .left,.right
.left
    ; sprite 1
    db  0                           ; left Y pos
    db  0                           ; left X pos
    db  8                           ; left tile ID
    db  2 | OAMF_BANK1              ; left attributes
    ; sprite 2
    db  0                           ; right Y pos
    db  8                           ; right X pos
    db  10                          ; right tile ID
    db  2 | OAMF_BANK1              ; right attributes
.right
    ; sprite 1
    db  0                           ; left Y pos
    db  0                           ; left X pos
    db  10                          ; left tile ID
    db  2 | OAMF_BANK1 | OBJF_XFLIP ; left attributes
    ; sprite 2
    db  0                           ; right Y pos
    db  8                           ; right X pos
    db  8                           ; right tile ID
    db  2 | OAMF_BANK1 | OBJF_XFLIP ; right attributes
    
SprDef_Frog_Hop:
    dw  .left,.right
.left
    ; sprite 1
    db  0                           ; left Y pos
    db  0                           ; left X pos
    db  12                          ; keft tile ID
    db  2 | OAMF_BANK1              ; keft attributes
    ; sprite 2
    db  0                           ; right Y pos
    db  8                           ; right X pos
    db  14                          ; right tile ID
    db  2 | OAMF_BANK1              ; right attributes
.right
    ; sprite 1
    db  0                           ; left Y pos
    db  0                           ; left X pos
    db  14                          ; left tile ID
    db  2 | OAMF_BANK1 | OBJF_XFLIP ; left attributes
    ; sprite 2
    db  0                           ; right Y pos
    db  8                           ; right X pos
    db  12                          ; right tile ID
    db  2 | OAMF_BANK1 | OBJF_XFLIP ; right attributes

; =============================================================================

section "Enemy GFX - Frog",romx
ObjGFX_Frog:    incbin  "GFX/Enemies/frog.2bpp.wle"
ObjPal_Frog:    incbin  "GFX/Enemies/frog.pal"
