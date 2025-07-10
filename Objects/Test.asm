Obj_Test:
; Routine pointers.
; OBJ_STATE is used as an index into this
Obj_Test_RoutinePointers:
    dw  Obj_Test_Init
    dw  Obj_Test_Main

; NOTE: For each object routine, DE will always contain a pointer to its slot + 1 byte (OBJ_STATE).
Obj_Test_Init:
    ld      a,1
    ld      [de],a
    ; fall through
Obj_Test_Main:
    dec     e
    ; object RAM test
    ; preserve current WRAM bank
    ldh     a,[rSVBK]
    push    af
    ; load ObjRAM WRAM bank
    ld      a,bank(ObjRAM)
    ldh     [rSVBK],a
    ; get pointer to object's memory
    ld      l,e     ; object slot x16
    ld      h,0
    add     hl,hl   ; x32
    add     hl,hl   ; x64
    add     hl,hl   ; x128
    ld      a,low(ObjRAM)
    add     h
    ld      h,a    
    ; now that we have our pointer, we can do stuff
    inc     [hl]
    ; we're done here now, so restore the WRAM bank
    pop     af
    ldh     [rSVBK],a
    ret
