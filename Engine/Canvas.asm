section union "Canvas",vram,bank[1]
vCanvas: ds (16 * 16) * 16
.end

section "Canvas routines",rom0

; INPUT: de = destination Y,X in background map coordinates for canvas
; WARNING: Assumes LCD is off!
InitCanvas:
    ld      a,1
    ldh     [rVBK],a
    ld      hl,vCanvas
    ld      bc,vCanvas.end-vCanvas
:   xor     a
    ld      [hl+],a
    dec     bc
    ld      a,b
    or      c
    jr      nz,:-
    ; clear tilemap
    push    de
    ld      hl,_SCRN0
    ld      bc,_SCRN1-_SCRN0
    ld      e,0
    push    hl
    push    bc
    call    MemFill
    xor     a
    ldh     [rVBK],a
    pop     bc
    pop     hl
    call    MemFill
    pop     de
    ; get tilemap address for input coordinates
    ld      l,d
    ld      h,0
    add     hl,hl   ; x2
    add     hl,hl   ; x4
    add     hl,hl   ; x8
    add     hl,hl   ; x16
    add     hl,hl   ; x32
    ld      d,0
    add     hl,de
    ld      de,_SCRN0
    add     hl,de
    
    ; fill map
    lb      bc,16,16
.mapfillloop
    ld      [hl],e
    ld      a,e
    add     $10
    ld      e,a
    ld      a,1
    ldh     [rVBK],a
    ld      a,%00001000
    ld      [hl+],a
    xor     a
    ldh     [rVBK],a
    dec     b
    jr      nz,.mapfillloop
    ld      b,16
    ld      a,l
    add     $10
    ld      l,a
    jr      nc,:+
    inc     h
:   inc     e
    dec     c
    jr      nz,.mapfillloop
    ret

; INPUT: bc = x,y
;         a = pen color
; WARNING: Assumes VRAM bank 1 is set!
PlotPixel:
    push    af
    push    bc
    push    de
    push    hl
    push    af
    ; set Y position
    ld      a,c
    and     $7f ; clamp to 0-127
    ld      l,a
    ld      h,0
    add     hl,hl   ; x2
    ld      e,l
    ; set X position
    ld      a,b
    and     $7f
    ld      l,a
    ld      h,0
    add     hl,hl
    ld      bc,CanvasXPositions
    add     hl,bc
    ld      a,[hl+]
    ld      d,a
    ld      a,[hl] ; get pixel mask
    ld      b,a
    cpl
    ld      c,a
    pop     af
    push    bc
    and     3
    add     a
    ld      c,a
    ld      b,0
    ld      hl,.colorpaths
    add     hl,bc
    pop     bc
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    rst     CallHL
.doneplot
    pop     hl
    pop     de
    pop     bc
    pop     af
    ret
    
.colorpaths
    dw      .color0
    dw      .color1
    dw      .color2
    dw      .color3
.color0
    wait_for_vram
    ld      a,[de]
    and     c
    ld      [de],a
    inc     e
    ld      a,[de]
    and     c
    ld      [de],a
    ret
.color1
    wait_for_vram
    ld      a,[de]
    or      b
    ld      [de],a
    inc     e
    ld      a,[de]
    and     c
    ld      [de],a
    ret
.color2
    wait_for_vram
    ld      a,[de]
    and     c
    ld      [de],a
    inc     e
    ld      a,[de]
    or      b
    ld      [de],a
    ret
.color3
    wait_for_vram
    ld      a,[de]
    or      b
    ld      [de],a
    inc     e
    ld      a,[de]
    or      b
    ld      [de],a
    ret

; page, bitmask
CanvasXPositions:
    db  high(vCanvas)+$0,$80
    db  high(vCanvas)+$0,$40
    db  high(vCanvas)+$0,$20
    db  high(vCanvas)+$0,$10
    db  high(vCanvas)+$0,$08
    db  high(vCanvas)+$0,$04
    db  high(vCanvas)+$0,$02
    db  high(vCanvas)+$0,$01
    db  high(vCanvas)+$1,$80
    db  high(vCanvas)+$1,$40
    db  high(vCanvas)+$1,$20
    db  high(vCanvas)+$1,$10
    db  high(vCanvas)+$1,$08
    db  high(vCanvas)+$1,$04
    db  high(vCanvas)+$1,$02
    db  high(vCanvas)+$1,$01
    db  high(vCanvas)+$2,$80
    db  high(vCanvas)+$2,$40
    db  high(vCanvas)+$2,$20
    db  high(vCanvas)+$2,$10
    db  high(vCanvas)+$2,$08
    db  high(vCanvas)+$2,$04
    db  high(vCanvas)+$2,$02
    db  high(vCanvas)+$2,$01
    db  high(vCanvas)+$3,$80
    db  high(vCanvas)+$3,$40
    db  high(vCanvas)+$3,$20
    db  high(vCanvas)+$3,$10
    db  high(vCanvas)+$3,$08
    db  high(vCanvas)+$3,$04
    db  high(vCanvas)+$3,$02
    db  high(vCanvas)+$3,$01
    db  high(vCanvas)+$4,$80
    db  high(vCanvas)+$4,$40
    db  high(vCanvas)+$4,$20
    db  high(vCanvas)+$4,$10
    db  high(vCanvas)+$4,$08
    db  high(vCanvas)+$4,$04
    db  high(vCanvas)+$4,$02
    db  high(vCanvas)+$4,$01
    db  high(vCanvas)+$5,$80
    db  high(vCanvas)+$5,$40
    db  high(vCanvas)+$5,$20
    db  high(vCanvas)+$5,$10
    db  high(vCanvas)+$5,$08
    db  high(vCanvas)+$5,$04
    db  high(vCanvas)+$5,$02
    db  high(vCanvas)+$5,$01
    db  high(vCanvas)+$6,$80
    db  high(vCanvas)+$6,$40
    db  high(vCanvas)+$6,$20
    db  high(vCanvas)+$6,$10
    db  high(vCanvas)+$6,$08
    db  high(vCanvas)+$6,$04
    db  high(vCanvas)+$6,$02
    db  high(vCanvas)+$6,$01
    db  high(vCanvas)+$7,$80
    db  high(vCanvas)+$7,$40
    db  high(vCanvas)+$7,$20
    db  high(vCanvas)+$7,$10
    db  high(vCanvas)+$7,$08
    db  high(vCanvas)+$7,$04
    db  high(vCanvas)+$7,$02
    db  high(vCanvas)+$7,$01
    db  high(vCanvas)+$8,$80
    db  high(vCanvas)+$8,$40
    db  high(vCanvas)+$8,$20
    db  high(vCanvas)+$8,$10
    db  high(vCanvas)+$8,$08
    db  high(vCanvas)+$8,$04
    db  high(vCanvas)+$8,$02
    db  high(vCanvas)+$8,$01
    db  high(vCanvas)+$9,$80
    db  high(vCanvas)+$9,$40
    db  high(vCanvas)+$9,$20
    db  high(vCanvas)+$9,$10
    db  high(vCanvas)+$9,$08
    db  high(vCanvas)+$9,$04
    db  high(vCanvas)+$9,$02
    db  high(vCanvas)+$9,$01
    db  high(vCanvas)+$a,$80
    db  high(vCanvas)+$a,$40
    db  high(vCanvas)+$a,$20
    db  high(vCanvas)+$a,$10
    db  high(vCanvas)+$a,$08
    db  high(vCanvas)+$a,$04
    db  high(vCanvas)+$a,$02
    db  high(vCanvas)+$a,$01
    db  high(vCanvas)+$b,$80
    db  high(vCanvas)+$b,$40
    db  high(vCanvas)+$b,$20
    db  high(vCanvas)+$b,$10
    db  high(vCanvas)+$b,$08
    db  high(vCanvas)+$b,$04
    db  high(vCanvas)+$b,$02
    db  high(vCanvas)+$b,$01
    db  high(vCanvas)+$c,$80
    db  high(vCanvas)+$c,$40
    db  high(vCanvas)+$c,$20
    db  high(vCanvas)+$c,$10
    db  high(vCanvas)+$c,$08
    db  high(vCanvas)+$c,$04
    db  high(vCanvas)+$c,$02
    db  high(vCanvas)+$c,$01
    db  high(vCanvas)+$d,$80
    db  high(vCanvas)+$d,$40
    db  high(vCanvas)+$d,$20
    db  high(vCanvas)+$d,$10
    db  high(vCanvas)+$d,$08
    db  high(vCanvas)+$d,$04
    db  high(vCanvas)+$d,$02
    db  high(vCanvas)+$d,$01
    db  high(vCanvas)+$e,$80
    db  high(vCanvas)+$e,$40
    db  high(vCanvas)+$e,$20
    db  high(vCanvas)+$e,$10
    db  high(vCanvas)+$e,$08
    db  high(vCanvas)+$e,$04
    db  high(vCanvas)+$e,$02
    db  high(vCanvas)+$e,$01
    db  high(vCanvas)+$f,$80
    db  high(vCanvas)+$f,$40
    db  high(vCanvas)+$f,$20
    db  high(vCanvas)+$f,$10
    db  high(vCanvas)+$f,$08
    db  high(vCanvas)+$f,$04
    db  high(vCanvas)+$f,$02
    db  high(vCanvas)+$f,$01
    
; INPUT: hl = point 1 x,y
;        de = point 2 x,y
DrawLine:
    ; TODO
    ret