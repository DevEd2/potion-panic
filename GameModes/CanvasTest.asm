section "Canvas test RAM",wram0
CanvasTestRAMStart:
Pen1PosX:   db
Pen1PosY:   db
Pen2PosX:   db
Pen2PosY:   db
Pen3PosX:   db
Pen3PosY:   db

Frame1:     db
Frame2:     db
Frame3:     db
Frame4:     db
CanvasTestRAMEnd:


section "Canvas test routines",romx
Pal_GrayscaleInverted:
    rgb      0, 0, 0
    rgb     31, 0, 0
    rgb      0,31, 0
    rgb      0, 0,31
GM_CanvasTest:
    call    LCDOff
    di
    
    lb      de,1,2
    call    InitCanvas
    
    xor     a
    ld      b,CanvasTestRAMEnd-CanvasTestRAMStart
    ld      hl,CanvasTestRAMStart
    call    MemFillSmall
    
    ; GBC palette
    ld      hl,Pal_GrayscaleInverted
    ld      a,$80
    ldh     [rBCPS],a
    rept    8
    ld      a,[hl+]
    ldh     [rBCPD],a
    endr
    
    ld      a,LCDCF_ON | LCDCF_BGON | LCDCF_BLK01 | LCDCF_BG9800
    ldh     [rLCDC],a
    ld      a,IEF_VBLANK
    ldh     [rIE],a
    ei
    
    ld      a,1
    ldh     [rVBK],a
    
    ;lb      hl,0,0
    ;lb      de,128,128
    ;call    DrawLine
    
CanvasTestLoop:
    halt
    jr      CanvasTestLoop