rsreset
def OBJECT_NAME_HERE_STATE_INIT    rb
def OBJECT_NAME_HERE_STATE_IDLE    rb
rsreset
assert _RS <= 16, "Object uses too much RAM! (Max size = $10, got {_RS})"

def OBJECT_NAME_HERE_HIT_WIDTH = 8
def OBJECT_NAME_HERE_HIT_HEIGHT = 12

Obj_ObjectNameHere:
; Routine pointers.
; OBJ_STATE is used as an index into this
Obj_ObjectNameHere_RoutinePointers:
    dw  Obj_ObjectNameHere_Init
    dw  Obj_ObjectNameHere_Idle

Obj_ObjectNameHere_Init:
    ldobjp  OBJ_STATE
    ld      a,OBJECT_NAME_HERE_STATE_IDLE
    ld      [hl+],a ; object state
    ; ld      a,1<<OBJB_VISIBLE ; OBJECT_NAME_HERE_STATE_IDLE and 1<<OBJB_VISIBLE both resolve to 1
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
    ld      a,OBJECT_NAME_HERE_HIT_WIDTH
    ld      [hl+],a ; object hitbox width (from center)
    ld      a,OBJECT_NAME_HERE_HIT_HEIGHT
    ld      [hl+],a ; object hitbox height (from bottom center)
    
    ; Any object-specific initialization code goes here

    ; fall through

Obj_ObjectNameHere_Idle:
    ; TODO
    ; fall through
Obj_ObjectNameHere_Draw:
    ; TODO
    ret
