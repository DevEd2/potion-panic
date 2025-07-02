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
    ret
