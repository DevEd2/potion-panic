rsreset
def SPARKLE_STATE_INIT      rb
def SPARKLE_STATE_IDLE      rb
rsreset
def Sparkle_Frame     rb
def Sparkle_Timer     rb
assert _RS <= 16, "Object uses too much RAM! (Max size = $10, got {_RS})"

Obj_Sparkle:
; Routine pointers.
; OBJ_STATE is used as an index into this
Obj_Sparkle_RoutinePointers:
    dw  Obj_Sparkle_Init
    dw  Obj_Sparkle_Idle

Obj_Sparkle_Init:
    ldobjp  OBJ_STATE
    ld      a,SPARKLE_STATE_IDLE
    ld      [hl+],a ; object state
    ; ld      a,1<<OBJB_VISIBLE ; SPARKLE_STATE_IDLE and 1<<OBJB_VISIBLE both resolve to 1
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
    xor     a
    ;ld      a,SPARKLE_HIT_WIDTH
    ld      [hl+],a ; object hitbox width (from center)
    ;ld      a,SPARKLE_HIT_HEIGHT
    ld      [hl+],a ; object hitbox height (from bottom center)
    
    ldobjrp 0
    ld      a,-1
    ld      [hl+],a ; Sparkle_Frame
    xor     a
    ld      [hl+],a ; Sparkle_Timer

    ; fall through

Obj_Sparkle_Idle:
    ldobjrp Sparkle_Timer
    ld      a,[hl]
    and     a
    jr      z,:+
    dec     [hl]
    jr      Obj_Sparkle_Draw
:   ld      [hl],1
    dec     l
    ld      a,[hl]
    cp      4
    jr      nz,:+
    ldobjp  OBJ_ID
    ld      [hl],0
    ret
:   inc     [hl]
    ; fall through
Obj_Sparkle_Draw:
    ; skip drawing sparkle on alternating frames based on object slot
    ld      a,l
    swap    a
    and     $f
    ld      b,a
    ldh     a,[hGlobalTick]
    add     b
    and     1
    ret     z

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
    add     4
    ld      b,a
    ld      a,[Level_CameraX]
    cpl
    inc     a
    add     b
    ld      [de],a
    inc     e
    ; tile ID
    ldobjrp Sparkle_Frame
    ld      a,[hl]
    add     $20
    ld      [de],a
    inc     e
    ; attribute
    ld      a,2 | %00001000
    ld      [de],a
    inc     e
    ld      a,e
    ldh     [hOAMPos],a
    ret

rsreset
; =============================================================================
