def FROG_IDLE_TIME_MIN = 120
def FROG_IDLE_TIME_MAX = 240
def FROG_CROAK_TIME_MIN = 30
def FROG_CROAK_TIME_MAX = 90

def FROG_HIT_WIDTH      = 6
def FROG_HIT_HEIGHT     = 6

rsreset
def FROG_STATE_INIT     rb
def FROG_STATE_IDLE     rb
def FROG_STATE_HOP      rb
def FROG_STATE_TONGUE   rb
def FROG_STATE_DEFEAT   rb

rsreset
def Frog_IdleTimer      rb
def Frog_StateTimer     rb
def Frog_AnimSpeed      rb
def Frog_AnimTimer      rb
def Frog_Frame          rb
def Frog_TongueLength   rb
assert _RS <= 16, "Object uses too much RAM! (Max size = $10, got {_RS})"

Obj_Frog:
; Routine pointers.
; OBJ_STATE is used as an index into this
Obj_Frog_RoutinePointers:
    dw  Obj_Frog_Init
    dw  Obj_Frog_Idle
    dw  Obj_Frog_Hop
    dw  Obj_Frog_Tongue
    dw  Obj_Frog_Defeat

Obj_Frog_Init:
    ldobjp  OBJ_STATE
    ld      a,FROG_STATE_IDLE
    ld      [hl+],a ; object state
    ; ld      a,1<<OBJB_VISIBLE ; FROG_STATE_IDLE and 1<<OBJB_VISIBLE both resolve to 1
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
    ld      a,FROG_HIT_WIDTH
    ld      [hl+],a ; object hitbox width (from center)
    ld      a,FROG_HIT_HEIGHT
    ld      [hl+],a ; object hitbox height (from bottom center)

    ldobjrp Frog_IdleTimer
    ld      a,(FROG_IDLE_TIME_MAX - FROG_IDLE_TIME_MIN)
    call    Math_RandRange
    add     FROG_IDLE_TIME_MIN
    ld      [hl+],a ; Frog_IdleTimer
    xor     a
    ld      [hl+],a ; Frog_StateTimer
    ld      [hl+],a ; Frog_AnimSpeed
    ld      [hl+],a ; Frog_AnimTimer
    ld      [hl+],a ; Frog_Frame
    ld      [hl+],a ; Frog_TongueLength
    ; fall through

Obj_Frog_Idle:
    ;ldobjrp Frog_IdleTimer
    ;dec     [hl]
    ;jr      nz,:+
    ;ldobjp  OBJ_STATE
    ;call    Math_Random
    ;and     1
    ;add     FROG_STATE_TONGUE

    ret
    jr      Obj_Frog_Draw

Obj_Frog_Hop:
    ; TODO
    ret

Obj_Frog_Tongue:
    ; TODO
    ret

Obj_Frog_Defeat:
    ; TODO
    ret

Obj_Frog_Draw:
    ldobjp  OBJ_FLAGS
    bit     OBJB_VISIBLE,[hl]
    ret     z
    ld      c,[hl]

    ldobjrp Frog_Frame
    ld      l,[hl]
    ld      h,0
    add     hl,hl   ; x2
    ld      de,Obj_Frog_Frames
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
        ld      a,[GFXPos_Frog]
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
    ret

rsreset
def FROG_F_IDLE         rb
def FROG_F_IDLE_CROAK   rb
def FROG_F_IDLE_BLINK   rb
def FROG_F_IDLE_TONGUE  rb
def FROG_F_PREHOP       rb
def FROG_F_HOP          rb

Obj_Frog_Frames:
    dw      SprDef_Frog_Idle
    dw      SprDef_Frog_IdleCroak
    dw      SprDef_Frog_IdleBlink
    dw      SprDef_Frog_Tongue
    dw      SprDef_Frog_PreHop
    dw      SprDef_Frog_Hop

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

SprDef_Frog_Tongue:
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
    db  8                           ; righttile ID
    db  2 | OAMF_BANK1 | OBJF_XFLIP ; rightattributes

SprDef_Frog_PreHop:
    dw  .left,.right
.left
    ; sprite 1
    db  0                           ; left Y pos
    db  0                           ; left X pos
    db  10                          ; left tile ID
    db  2 | OAMF_BANK1              ; left attributes
    ; sprite 2
    db  0                           ; right Y pos
    db  8                           ; right X pos
    db  12                          ; right tile ID
    db  2 | OAMF_BANK1              ; right attributes
.right
    ; sprite 1
    db  0                           ; left Y pos
    db  0                           ; left X pos
    db  12                          ; left tile ID
    db  2 | OAMF_BANK1 | OBJF_XFLIP ; left attributes
    ; sprite 2
    db  0                           ; right Y pos
    db  8                           ; right X pos
    db  10                          ; right tile ID
    db  2 | OAMF_BANK1 | OBJF_XFLIP ; right attributes

SprDef_Frog_Hop:
    dw  .left,.right
.left
    ; sprite 1
    db  0                           ; left Y pos
    db  0                           ; left X pos
    db  14                          ; keft tile ID
    db  2 | OAMF_BANK1              ; keft attributes
    ; sprite 2
    db  0                           ; right Y pos
    db  8                           ; right X pos
    db  16                          ; right tile ID
    db  2 | OAMF_BANK1              ; right attributes
.right
    ; sprite 1
    db  0                           ; left Y pos
    db  0                           ; left X pos
    db  16                          ; left tile ID
    db  2 | OAMF_BANK1 | OBJF_XFLIP ; left attributes
    ; sprite 2
    db  0                           ; right Y pos
    db  8                           ; right X pos
    db  14                          ; right tile ID
    db  2 | OAMF_BANK1 | OBJF_XFLIP ; right attributes

; =============================================================================

section "Enemy GFX - Frog",romx
ObjGFX_Frog:    incbin  "GFX/Enemies/frog.2bpp.wle"
ObjPal_Frog:    incbin  "GFX/Enemies/frog.pal"
