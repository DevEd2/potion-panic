def BIGTEXT_OFFSET_Y            = 60
def BIGTEXT_TIME_BETWEEN_STATES = 60

rsreset
def BIGTEXT_STATE_INIT      rb
def BIGTEXT_STATE_IDLE      rb
rsreset
def BigText_ID              rb
assert _RS <= 16, "Object uses too much RAM! (Max size = $10, got {_RS})"

Obj_BigText:
; Routine pointers.
; OBJ_STATE is used as an index into this
Obj_BigText_RoutinePointers:
    dw  Obj_BigText_Init
    dw  Obj_BigText_Idle

Obj_BigText_Init:
    ldobjp  OBJ_STATE
    ld      a,l
    dec     a
    ld      [BigText_ObjectID],a
    ld      a,BIGTEXT_STATE_IDLE
    ld      [hl+],a ; object state
    ; ld      a,1<<OBJB_VISIBLE ; BIGTEXT_STATE_IDLE and 1<<OBJB_VISIBLE both resolve to 1
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
    ;ld      a,BIGTEXT_HIT_WIDTH
    ld      [hl+],a ; object hitbox width (from center)
    ;ld      a,BIGTEXT_HIT_HEIGHT
    ld      [hl+],a ; object hitbox height (from bottom center)
    
    ld      hl,BigText_RAM
    xor     a
    ld      [BigText_Done],a
    ld      b,10
:   ld      [hl],0
    inc     hl
    ld      [hl+],a
    sub     4
    dec     b
    jr      nz,:-

    
    ; fall through

Obj_BigText_Idle:
Obj_BigText_Draw:
    ldobjp  OBJ_FLAGS
    bit     OBJB_VISIBLE,[hl]
    ret     z
    ld      a,[hOAMPos]
    ld      e,a
    ld      d,high(OAMBuffer)
    ; TODO
    
    ldobjrp BigText_ID
    ld      a,[hl]
    ld      l,a
    ld      h,0
    add     hl,hl
    ld      bc,BigText_Pointers
    add     hl,bc
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    ld      bc,0
    ld      a,[hl+]
    ldh     [hTemp3],a
:   ld      a,[hl+]
    ldh     [hTemp1],a
    cp      -1
    jp      z,.done
    push    hl
    ld      hl,BigText_RAM
    add     hl,bc
    add     hl,bc
    ld      a,[hl+]
    and     a
    jr      z,.initwait
    dec     a
    jr      z,.easein
    dec     a
    jr      z,.wait
    dec     a
    jr      z,.easeout
    ; fall through
.next
    pop     hl
    inc     c
    jr      :-
.initwait
    ld      a,[hl]
    and     a
    jp      z,.nextstate
    inc     a
    ld      [hl+],a
    jr      .next
.easein
    push    hl
    push    bc
    ld      a,[hl]
    ld      c,a
    ld      b,0
    
    ld      hl,BigText_SineEaseInTable
    add     hl,bc
    ld      a,[hl]
    add     BIGTEXT_OFFSET_Y
    ld      [de],a
    inc     e
    
    ld      hl,BigText_EaseInTable
    add     hl,bc
    ld      a,c
    ldh     [hTemp2],a
    pop     bc
    push    bc
    ld      a,c
    add     a
    add     a
    add     a
    add     [hl]
    push    bc
    ld      b,a
    ldh     a,[hTemp3]
    add     b
    pop     bc
    ld      [de],a
    inc     e
    ldh     a,[hTemp2]
    ld      c,a
    
    ldh     a,[hTemp1]
    add     a
    ld      [de],a
    inc     e
    
    ld      a,7
    ld      [de],a
    inc     e
    pop     bc
    pop     hl
    ld      a,[hl]
    inc     a
    cp      BIGTEXT_TIME_BETWEEN_STATES
    jr      z,.nextstate
    ld      [hl+],a
    jr      .next
.wait
    ld      a,BIGTEXT_OFFSET_Y
    ld      [de],a
    inc     e
    
    ld      a,c
    add     a
    add     a
    add     a
    push    bc
    ld      b,a
    ldh     a,[hTemp3]
    add     b
    pop     bc
    ld      [de],a
    inc     e
    
    ldh     a,[hTemp1]
    add     a
    ld      [de],a
    inc     e
    
    ld      a,7
    ld      [de],a
    inc     e
    
    ld      a,[hl]
    inc     a
    cp      BIGTEXT_TIME_BETWEEN_STATES
    jr      z,.nextstate
    ld      [hl+],a
    jr      .next
.easeout
    push    hl
    push    bc
    ld      a,[hl]
    ld      c,a
    ld      b,0
    
    ld      hl,BigText_SineEaseOutTable
    add     hl,bc
    ld      a,[hl]
    add     BIGTEXT_OFFSET_Y
    ld      [de],a
    inc     e
    
    ld      hl,BigText_EaseOutTable
    add     hl,bc
    ld      a,c
    ldh     [hTemp2],a
    pop     bc
    push    bc
    ld      a,c
    add     a
    add     a
    add     a
    add     [hl]
    push    bc
    ld      b,a
    ldh     a,[hTemp3]
    add     b
    pop     bc
    ld      [de],a
    inc     e
    ldh     a,[hTemp2]
    ld      c,a
    
    ldh     a,[hTemp1]
    add     a
    ld      [de],a
    inc     e
    
    ld      a,7
    ld      [de],a
    inc     e
    pop     bc
    pop     hl
    ld      a,[hl]
    inc     a
    cp      BIGTEXT_TIME_BETWEEN_STATES
    jr      z,.nextstate
    ld      [hl+],a
    jp      .next

.nextstate
    xor     a
    ld      [hl-],a
    inc     [hl]
    inc     l
    inc     l
    jp      .next
.done
    
    ld      hl,BigText_RAM.end-2
    ld      b,11
:   dec     b
    jr      z,:+
    ld      a,[hl-]
    dec     hl
    and     a   ; a=0
    jr      z,:-
    dec     a   ; a=1
    jr      z,:+
    dec     a   ; a=2
    jr      z,:+
    dec     a   ; a=3
    jr      z,:+
    dec     a   ; a=4
    jr      nz,:+
    ld      a,1
    ld      [BigText_Done],a
    ldobjp  OBJ_ID
    ld      [hl],0
:   

    ld      a,e
    ldh     [hOAMPos],a
    ret

; =============================================================================

    pushc
    newcharmap bigfont
redef chars equs "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ "
def char = 0
rept strlen("{chars}")
    charmap strsub("{chars}", char + 1, 1), char
def char = char + 1
endr

rsreset
def BIGTEXT_GET_READY   rb
def BIGTEXT_WELL_DONE   rb
def BIGTEXT_TIME_UP     rb
def BIGTEXT_TOO_BAD     rb
def BIGTEXT_GAME_OVER   rb

def BIGTEXT_POTIONS     rb

BigText_Pointers:
    dw      .getready
    dw      .welldone
    dw      .timeup
    dw      .toobad
    dw      .gameover
:   dw      .potion_nothing
    dw      .potion_fat
    dw      .potion_tiny
    dw      .potion_reverse
    dw      .potion_1up
    dw      .potion_heal
    dw      .potion_dmgmode
    dw      .potion_tripping
    dw      .potion_familiar
:

.getready               db  88 - ((:++ - :+) * 4)
:                       db  "GET READY"
:                       db  -1
.welldone               db  88 - ((:++ - :+) * 4)
:                       db  "WELL DONE"
:                       db  -1
.timeup                 db  88 - ((:++ - :+) * 4)
:                       db  "TIME UP"
:                       db  -1
.toobad                 db  88 - ((:++ - :+) * 4)
:                       db  "TOO BAD"
:                       db  -1
.gameover               db  88 - ((:++ - :+) * 4)
:                       db  "GAME OVER"
:                       db  -1
.potion_fat             db  88 - ((:++ - :+) * 4)
:                       db  "UH OH BIG"
:                       db  -1
.potion_tiny            db  88 - ((:++ - :+) * 4)
:                       db  "UH OH TINY"
:                       db  -1
.potion_nothing         db  88 - ((:++ - :+) * 4)
:                       db  "NOTHING"
:                       db  -1
.potion_1up             db  88 - ((:++ - :+) * 4)
:                       db  "EXTRA LIFE"
:                       db  -1
.potion_reverse         db  88 - ((:++ - :+) * 4)
:                       db  "SDRAWKCAB"
:                       db  -1
.potion_heal            db  88 - ((:++ - :+) * 4)
:                       db  "FULL HEAL"
:                       db  -1
.potion_dmgmode         db  88 - ((:++ - :+) * 4)
:                       db  "SO RETRO"
:                       db  -1
.potion_tripping        db  88 - ((:++ - :+) * 4)
:                       db  "TRIPPING"
:                       db  -1
.potion_familiar        db  88 - ((:++ - :+) * 4)
:                       db  "FAMILIAR"
:                       db  -1
    popc

BigText_EaseInTable:
    db  120, 116, 112, 108, 105, 101,  97,  94,  90,  87
    db   83,  80,  77,  74,  71,  68,  65,  62,  59,  56
    db   53,  51,  48,  46,  43,  41,  39,  36,  34,  32
    db   30,  28,  26,  24,  23,  21,  19,  18,  16,  15
    db   13,  12,  11,  10,   9,   8,   7,   6,   5,   4
    db    3,   3,   2,   2,   1,   1,   1,   0,   0,   0
BigText_EaseOutTable:
    db   -0,  -0,  -0,  -0,  -1,  -1,  -1,  -2,  -2,  -3
    db   -3,  -4,  -5,  -6,  -7,  -8,  -9, -10, -11, -12
    db  -13, -15, -16, -18, -19, -21, -23, -24, -26, -28
    db  -30, -32, -34, -36, -39, -41, -43, -46, -48, -51
    db  -53, -56, -59, -62, -65, -68, -71, -74, -77, -80
    db  -83, -87, -90, -94, -97,-101,-105,-108,-112,-116
BigText_SineEaseInTable:
    db    0,   2,   5,   7,   9,  10,  12,  13,  13,  13
    db   13,  13,  12,  11,  10,   8,   7,   5,   3,   2
    db    0,  -2,  -3,  -4,  -6,  -7,  -7,  -8,  -8,  -8
    db   -8,  -8,  -7,  -6,  -6,  -5,  -4,  -3,  -2,  -1
    db    0,   1,   1,   2,   3,   3,   3,   3,   3,   3
    db    3,   2,   2,   2,   1,   1,   1,   0,   0,   0
BigText_SineEaseOutTable:
    db    0,   0,   0,   0,   1,   1,   1,   2,   2,   2
    db    3,   3,   3,   3,   3,   3,   3,   2,   1,   1
    db    0,  -1,  -2,  -3,  -4,  -5,  -6,  -6,  -7,  -8
    db   -8,  -8,  -8,  -8,  -7,  -7,  -6,  -4,  -3,  -2
    db    0,   2,   3,   5,   7,   8,  10,  11,  12,  13
    db   13,  13,  13,  13,  12,  10,   9,   7,   5,   2

; ================================================================

section "Bigtext RAM",wram0

BigText_RAM:        ds  2*10
.end
BigText_Done:       db
BigText_ObjectID:   db
rsreset
def BIGTEXT_CHAR_MODE   rb
def BIGTEXT_CHAR_OFFSET rb

