section "Object system RAM",wram0,align[8]
def MAX_OBJECTS = 16

ObjList:        ds  MAX_OBJECTS * 16
ObjRAM:         ds  MAX_OBJECTS * 16
FreezeObjects:  db

section "Object system HRAM",hram
hObjGFXPos:         dw
hObjPtr:            dw
hObjRAMPtr:         dw

section fragment "Object GFX positions",wram0
ObjectGFXPositions::
GFXPos_Null:    db

rsreset
def OBJ_ID          rb  ; object ID (if zero, slot is free)
def OBJ_STATE       rb  ; object state - if 0, object is uninitialized
def OBJ_FLAGS       rb  ; object flags
def OBJ_XSUB        rb  ; object X subpixel
def OBJ_X           rb  ; object X position
def OBJ_YSUB        rb  ; object Y subpixel
def OBJ_Y           rb  ; object Y position
def OBJ_VX          rw  ; object X velocity (signed 8.8)
def OBJ_VY          rw  ; object Y velocity (signed 8.8)
def OBJ_HIT_WIDTH   rb  ; object hitbox width
def OBJ_HIT_HEIGHT  rb  ; object hitbox height
assert _RS <= 16, "Object struct too large! Max size = $10, got {_RS}"

rsreset
def OBJB_VISIBLE    rb
def OBJB_XFLIP      rb
def OBJB_YFLIP      rb
; TODO: Any additional flags needed?

def OBJF_VISIBLE    equ 1 << OBJB_VISIBLE
def OBJF_XFLIP      equ 1 << OBJB_XFLIP
def OBJF_YFLIP      equ 1 << OBJB_YFLIP


def NUM_OBJECTS = 0
def OBJID_NONE = NUM_OBJECTS

macro objdef
def OBJID_\1 = NUM_OBJECTS
def NUM_OBJECTS = NUM_OBJECTS+1
section fragment "Object GFX positions",wram0
GFXPos_\1: db
section fragment "Object pointer table",rom0
ObjPointer_\1:
    db bank(Object_\1)
    dw Object_\1
section "Object routine include - \1",romx
Object_\1:  include  "Objects/\1.asm"
endm

; LoaD OBJect Pointer + offset into HL
macro ldobjp
    ld      hl,hObjPtr
    ld      a,[hl+]
    ld      h,[hl]
    if \1 != 0
        add     \1
    endc
    ld      l,a
endm

; LoaD OBJect Ram Pointer + offset into HL
macro ldobjrp
    ld      hl,hObjRAMPtr
    ld      a,[hl+]
    ld      h,[hl]
    if \1 != 0
        add     \1
    endc
    ld      l,a
endm


; ================================================================

section "Object routines",rom0

; Create an object.
; INPUT:    b = ID
;           c = screen
;           d = X position
;           e = Y position
; OUTPUT:   hl = object slot pointer
;           carry if no slots are free
; DESTROYS: af, hl*
; * only if no free object slot was found
CreateObject:
    ld      hl,ObjList + OBJ_ID
:   ld      a,[hl]
    and     a
    jr      z,.gotslot
    ld      a,l
    add     $10
    ld      l,a
    jr      nc,:-
    scf
    ret
.gotslot
    push    hl
    ; object ID
    ld      a,b
    ld      [hl+],a
    ; object state
    xor     a
    ld      [hl+],a
    ; object flags
    ld      [hl+],a
    ; object X position
    ld      [hl+],a
    ld      a,d
    ld      [hl+],a
    ; object Y position
    xor     a
    ld      [hl+],a
    ld      a,e
    ld      [hl+],a
    ; object screen
    ; ld      a,c
    ; ld      [hl+],a
    ; inc     l
    ; object X velocity
    xor     a
    ld      [hl+],a
    ld      [hl+],a
    ; object Y velocity
    ld      [hl+],a
    ld      [hl+],a
    pop     hl
    ret

; Deletes every object by setting their ID to 0 (used to indicate a slot is free).
; Note that this *only* clears object IDs; each object is expected to properly initialize itself.
; INPUT:    none
; OUTPUT:   none
; DESTROYS: af b- de hl
DeleteAllObjects:
    xor     a
    ld      [FreezeObjects],a
    ld      hl,ObjList + OBJ_ID
    ld      de,$10
    ld      b,32
:   ld      [hl],0
    add     hl,de
    dec     b
    jr      nz,:-
    ret

; Call once per frame to tick objects.
ProcessObjects:
    ld      hl,ObjList
.loop
    ld      a,[hl]
    and     a
    jp      z,.next
    
    ; set object RAM pointers
    ld      a,l
    ldh     [hObjPtr],a
    ldh     [hObjRAMPtr],a
    ld      a,h
    ldh     [hObjPtr+1],a
    inc     a
    ldh     [hObjRAMPtr+1],a
    ld      d,h
    ld      e,l
    ; jump to object-specific processing routines
    ld      a,[hl]
    ;dec     a
    ld      c,a
    ld      b,0
    push    hl
    ld      hl,ObjPointers
    add     hl,bc
    add     hl,bc
    add     hl,bc
    pushbank
    ld      a,[hl+]
    bankswitch_to_a
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    inc     e
    ld      a,[de]
    ld      c,a
    ld      b,0
    add     hl,bc
    add     hl,bc
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    rst     CallHL
    popbank
    pop     hl
    
    ; speed to position
    ld      a,[FreezeObjects]
    and     a
    jr      nz,.next
.speedtopos
    push    hl
    ldobjp  OBJ_XSUB
    push    hl
    ld      a,[hl+]
    ld      d,[hl]
    ld      e,a
    ldobjp  OBJ_VX
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
        
    ldobjp  OBJ_YSUB
    push    hl
    ld      a,[hl+]
    ld      d,[hl]
    ld      e,a
    ldobjp  OBJ_VY
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
    pop     hl
    
    ; fall through    
.next
    ld      a,l
    and     $f0
    add     $10
    ld      l,a
    jp      nc,.loop
    ret

; Returns zero flag if a projectile intersects with current object.
; INPUT:    none
; OUTPUT:   zero flag on collision + HL = projectile pointer
; DESTROYS: a bc e
Obj_CheckProjectileIntersecting:
    ld      b,MAX_PROJECTILES
    ld      hl,Player_Projectiles
.loop
    ld      a,[hl]
    and     a
    jr      z,.next
    inc     l
    inc     l
    inc     l
    push    bc
    push    hl
    ldobjp  OBJ_X
    ld      e,[hl]
    ldobjp  OBJ_HIT_WIDTH
    ld      a,e
    sub     [hl]
    ldh     [hTemp1],a
    ld      a,e
    add     [hl]
    ldh     [hTemp3],a
    
    ldobjp  OBJ_Y
    ld      e,[hl]
    ldobjp  OBJ_HIT_HEIGHT
    ld      a,e
    sub     [hl]
    sub     [hl]
    ldh     [hTemp2],a
    ld      a,e
    ldh     [hTemp4],a
    
    pop     hl
    push    hl
    ld      a,[hl+]
    ld      b,a
    inc     l
    inc     l
    inc     l
    ld      a,[hl+]
    ld      l,a
    ld      h,b
    ldh     a,[hTemp1]
    ld      b,a
    ldh     a,[hTemp2]
    ld      c,a
    ldh     a,[hTemp3]
    ld      d,a
    ldh     a,[hTemp4]
    ld      e,a
    call    Math_IsPointInRectangle
    pop     hl
    dec     l
    dec     l
    dec     l
    jr      c,.hit
    ld      a,l
    add     SIZEOF_PROJECTILE
    ld      l,a
    pop     bc
    dec     b
    jr      nz,.loop
    jr      .nohit
.next
    ld      a,l
    add     SIZEOF_PROJECTILE
    ld      l,a
    dec     b
    jr      nz,.loop
.nohit
    and     a
    ret
.hit
    ;ld      [hl],0
    pop     bc
    ret

; Returns carry flag if the player intersects with current object.
; INPUT:    none
; OUTPUT:   zero flag on collision
; DESTROYS: a b e hl
; !!! KNOWN ISSUE: Actual collision area is offset
Object_CheckPlayerIntersecting:
    ldobjp  OBJ_HIT_WIDTH
    ld      b,[hl]
    ldobjp  OBJ_X
    ld      a,[hl]
    sub     b
    ld      e,a
    ld      a,[Player_HitboxPointTL]
    cp      e
    jr      c,.nocollision
    ld      a,[hl]
    add     b
    ld      e,a
    ld      a,[Player_HitboxPointBR]
    cp      e
    jr      nc,.nocollision
    
    ldobjp  OBJ_HIT_HEIGHT
    ld      b,[hl]
    ldobjp  OBJ_Y
    ld      a,[hl]
    sub     b
    ld      e,a
    ld      a,[Player_HitboxPointTL+1]
    cp      e
    jr      nc,.nocollision
    ld      a,[Player_HitboxPointBR+1]
    cp      [hl]
    ret
.nocollision
    and     a
    ret

; Determine whether or not to drop an item.
; INPUT:    none
; OUTPUT:   none
; DESTROYS: af bc de hl
Object_ProcessDrops:
    call    Math_Random
    cp      POTION_DROP_CHANCE
    ret     nc
    ldobjp  OBJ_X
    ld      d,[hl]
    inc     l
    inc     l
    ld      e,[hl]
    ld      b,OBJID_Potion
    jp      CreateObject

; ================================================================

    include "Objects/Pointers.asm"
