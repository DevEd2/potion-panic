section "Object system RAM",wram0,align[8]
def MAX_OBJECTS = 16

ObjList:    ds  MAX_OBJECTS * 16
ObjRAM:     ds  MAX_OBJECTS * 16

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

rsreset
def OBJID_NONE rb

macro objdef
def OBJID_\1 rb
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
; OUTPUT:   carry if no slots are free
; DESTROYS: af -- -- hl
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
    ld      a,c
    ld      [hl+],a
    ; object X velocity
    xor     a
    ld      [hl+],a
    ld      [hl+],a
    ; object Y velocity
    ld      [hl+],a
    ld      [hl+],a
    ret

; Deletes every object by setting their ID to 0 (used to indicate a slot is free).
; Note that this *only* clears object IDs; each object is expected to properly initialize itself.
; INPUT:    none
; OUTPUT:   none
; DESTROYS: af b- de hl
DeleteAllObjects:
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
    jr      z,.next
    
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
    dec     a
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
    push    hl
    ld      a,l
    and     $f0
    ld      e,a
    or      OBJ_VX
    ld      l,a
    ld      a,[hl+]
    ld      b,[hl]
    ld      c,a
    pop     hl
    ld      a,e
    or      OBJ_X
    ld      l,a
    push    hl
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    add     hl,bc
    ld      b,h
    ld      c,l
    pop     hl
    ld      a,c
    ld      [hl+],a
    ld      a,b
    ld      [hl+],a
    
    push    hl
    ld      a,l
    and     $f0
    ld      e,a
    or      OBJ_VY
    ld      l,a
    ld      a,[hl+]
    ld      b,[hl]
    ld      c,a
    pop     hl
    ld      a,e
    or      OBJ_Y
    ld      l,a
    push    hl
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    add     hl,bc
    ld      b,h
    ld      c,l
    pop     hl
    ld      a,c
    ld      [hl+],a
    ld      a,b
    ld      [hl+],a
    ; fall through    
.next
    ld      a,l
    and     $f0
    add     $10
    ld      l,a
    jr      nc,.loop
    ret

; ================================================================

    include "Objects/Pointers.asm"
