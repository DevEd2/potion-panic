rsreset
def SPAWNPOINT_STATE_INIT   rb
def SPAWNPOINT_STATE_IDLE   rb
rsreset
assert _RS <= 16, "Object uses too much RAM! (Max size = $10, got {_RS})"

Obj_EnemySpawnpoint:
; Routine pointers.
; OBJ_STATE is used as an index into this
Obj_EnemySpawnpoint_RoutinePointers:
    dw  Obj_EnemySpawnpoint_Init
    dw  Obj_EnemySpawnpoint_Idle

Obj_EnemySpawnpoint_Init:
    ldobjp  OBJ_STATE
    ld      a,SPAWNPOINT_STATE_IDLE
    ld      [hl+],a ; object state
    ; ld      a,1<<OBJB_VISIBLE ; SPAWNPOINT_STATE_IDLE and 1<<OBJB_VISIBLE both resolve to 1
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
    ;ld      a,SPAWNPOINT_HIT_WIDTH
    ld      [hl+],a ; object hitbox width (from center)
    ;ld      a,SPAWNPOINT_HIT_HEIGHT
    ld      [hl+],a ; object hitbox height (from bottom center)

    ; fall through

Obj_EnemySpawnpoint_Idle:
    ; TODO
    ret
; object does not to be drawn

rsreset
; =============================================================================
