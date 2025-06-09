

; Collision constants

                                rsreset
def COLLISION_NONE              rb ; no collision
def COLLISION_SOLID             rb ; solid to player and enemies
def COLLISION_TOPSOLID          rb ; solid to player and enemies only on top
def COLLISION_SLOPE_L           rb ; left slope
def COLLISION_SLOPE_R           rb ; right slope
def COLLISION_SLOPE_S           rb ; shallow slope
def COLLISION_SLOPE_STEEP_L     rb ; left steep slope
def COLLISION_SLOPE_STEEP_R     rb ; right steep slope
def COLLISION_BREAKABLE         rb ; breakable
def COLLISION_COLLECT           rb ; disappears when touched; optionally can set a flag/increment a variable based on ID
def COLLISION_COLLECT_BIG_TL    rb ; same as COLLISION_COLLECT but also clears specific adjacent tiles
def COLLISION_COLLECT_BIG_TR    rb ; same as COLLISION_COLLECT but also clears specific adjacent tiles
def COLLISION_COLLECT_BIG_BL    rb ; same as COLLISION_COLLECT but also clears specific adjacent tiles
def COLLISION_COLLECT_BIG_BR    rb ; same as COLLISION_COLLECT but also clears specific adjacent tiles
; add more as needed

section "Metatile routines",rom0

; Input:    H = Y pos
;           L = X pos
; Output:   A = Tile coordinates
; Destroys: B
GetTileCoordinates:
    ld      a,l
    and     $f0
    swap    a
    ld      b,a
    ld      a,h
    and     $f0
    add     b
    ret

; INPUT: a = coordinates (low nybble = X, high nybble = Y)
; OUTPUT:   hl = pointer to height map
;            a = collision type
;            b = collision angle
GetTileProperties:
    ld      h,high(Level_Map)
    ld      b,a
    ld      a,[Level_CameraX+1]
    add     b
    ld      l,a
    jr      nc,:+
    inc     h
:   ld      a,bank(Level_Map)
    ldh     [rSVBK],a
    
    ld      de,Level_ColMapPtr
    ld      a,[de]
    inc     de
    ld      c,a
    ld      a,[de]
    ld      d,a
    ld      a,c
    ld      a,e
    add     [hl]
    ld      e,a
    jr      nc,:+
    inc     d
:   ld      a,[de]
    push    af
    
    ld      de,Level_ColAnglePtr
    ld      a,[de]
    inc     de
    ld      c,a
    ld      a,[de]
    ld      d,a
    ld      a,c
    ld      a,e
    add     [hl]
    ld      e,a
    jr      nc,:+
    inc     d
:   ld      a,[de]
    ld      b,a
    
    ld      a,[hl]
    ld      l,a
    ld      h,0
    add     hl,hl   ; x2
    add     hl,hl   ; x4
    add     hl,hl   ; x8
    add     hl,hl   ; x16
    ld      de,Level_ColAnglePtr
    ld      a,[de]
    inc     de
    ld      c,a
    ld      a,[de]
    ld      d,a
    ld      a,c
    add     hl,de
    
    pop     af
    ret
    
; Input:    A = Tile coordinates (upper nybble = X, lower nybble = Y)
;           B = Tile ID
; Output:   Metatile to screen RAM
; Destroys: BC, DE, HL
DrawMetatile:
    push    af
    swap    a
    push    hl
    ld      e,a
    and     $0f
    rla
    ld      l,a
    ld      a,e
    and     $f0
    ld      e,a
    rla
    rla
    and     %11000000
    or      l
    ld      l,a
    ld      a,e
    rra
    rra
    swap    a
    and     $3
    ld      h,a
    
    ld      de,_SCRN0
    add     hl,de
    ld      d,h
    ld      e,l
    ; get tile data pointer
    ld      a,[Level_BlockMapBank]
    bankswitch_to_a
    ld      hl,Level_BlockMapPtr
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    
    ld      c,b
    ld      b,0
    add     hl,bc
    add     hl,bc
    add     hl,bc
    add     hl,bc
    add     hl,bc
    add     hl,bc
    add     hl,bc
    add     hl,bc
    ; write to screen memory
    xor     a
    ldh     [rVBK],a
    wait_for_vram
    ld      a,[hl+]
    xor     %10000000
    ld      [de],a
    ld      a,1
    ldh     [rVBK],a
    wait_for_vram
    ld      a,[hl+]
    ld      [de],a
    inc     de
    
    xor     a
    ldh     [rVBK],a
    wait_for_vram
    ld      a,[hl+]
    xor     %10000000
    ld      [de],a
    ld      a,1
    ldh     [rVBK],a
    wait_for_vram
    ld      a,[hl+]
    ld      [de],a
    ld      a,e
    add     $1f
    jr      nc,.nocarry3
    inc     d
.nocarry3
    ld  e,a
    
    xor     a
    ldh     [rVBK],a
    wait_for_vram
    ld      a,[hl+]
    xor     %10000000
    ld      [de],a
    ld      a,1
    ldh     [rVBK],a
    wait_for_vram
    ld      a,[hl+]
    ld      [de],a
    inc     de
    
    xor     a
    ldh     [rVBK],a
    wait_for_vram
    ld      a,[hl+]
    xor     %10000000
    ld      [de],a
    ld      a,1
    ldh     [rVBK],a
    wait_for_vram
    ld      a,[hl+]
    ld      [de],a
    pop     hl
    pop     af
    ret
