section "Player RAM",wram0

def PLAYER_ACCEL            = $040
def PLAYER_DECEL            = $020
def PLAYER_WALK_SPEED       = $120
def PLAYER_JUMP_HEIGHT      = $400
def PLAYER_JUMP_HEIGHT_HIGH = $400 ;$490
def PLAYER_GRAVITY          = $028
def PLAYER_COYOTE_TIME      = 15 ; coyote time in frames

def PLAYER_WIDTH            = 6
def PLAYER_HEIGHT           = 27

Player_RAMStart:
Player_XPos:    ds  3   ; x position (Q16.8)
Player_YPos:    ds  2   ; y position (Q8.8)
Player_XVel:    ds  2   ; added to xpos each frame
Player_YVel:    ds  2   ; added to ypos each frame
Player_Grav:    ds  2   ; added to yvel each frame
Player_Flags:   db      ; bit 0: direction player is facing (0 = right, 1 = left)
                        ; bit 1: whether player is airborne (set) or grounded (unset)
                        ; bit 2: whether player is standing (unset) or crouching/crawling (set)
                        ; bit 3:
                        ; bit 4:
                        ; bit 5:
                        ; bit 6:
                        ; bit 7: noclip
Player_HorizontalCollisionSensorTop:    db
Player_HorizontalCollisionSensorBottom: db
Player_VerticalCollisionSensorLeft:     db
Player_VerticalCollisionSensorRight:    db
Player_VerticalCollisionSensorCenter:   db
Player_CoyoteTimer:                     db
Player_AnimFrame:                       db
Player_AnimTimer:                       db
Player_AnimPointer:                     dw
Player_RAMEnd:

def BIT_PLAYER_DIRECTION    = 0
def BIT_PLAYER_AIRBORNE     = 1
def BIT_PLAYER_CROUCHING    = 2 
def BIT_PLAYER_UNUSED3      = 3
def BIT_PLAYER_UNUSED4      = 4
def BIT_PLAYER_UNUSED5      = 5
def BIT_PLAYER_UNUSED6      = 6
def BIT_PLAYER_NOCLIP       = 7

macro player_set_animation
    ld      a,low(Player_Anim_\1)
    ld      [Player_AnimPointer],a
    ld      a,high(Player_Anim_\1)
    ld      [Player_AnimPointer+1],a
    ld      a,1
    ld      [Player_AnimTimer],a
endm

section "Player routines",rom0

InitPlayer:
    ; clear player RAM
    ld      hl,Player_RAMStart
    ld      b,Player_RAMEnd-Player_RAMStart
    xor     a
    call    MemFillSmall
    ; load player GFX
    ld      a,1
    ldh     [rVBK],a
    farload hl,PlayerPlaceholderTiles
    ld      de,_VRAM
    ; B = 0 here, which means we copy 256 bytes (16 tiles)
    call    MemCopySmall
    ;ld      hl,PlayerPalette
    ld      a,8
    call    LoadPal
    ld      a,low(PLAYER_GRAVITY)
    ld      [Player_Grav],a
    xor     a   ; ld a,high(PLAYER_GRAVITY)
    ld      [Player_Grav+1],a
    
    player_set_animation Idle
    ret

ProcessPlayer:
    ld      a,[Player_Flags]
    bit     BIT_PLAYER_NOCLIP,a
    push    af
    call    nz,Player_Noclip
    pop     af
    ret     nz  ; return if we're in noclip mode
    
    ; player controls
    
    ; check if player should crouch
;    ld      hl,Player_Flags
;    bit     BIT_PLAYER_AIRBORNE,[hl]
;    jr      nz,.skipcrouch
;    ldh     a,[hHeldButtons]
;    bit     BIT_DOWN,a
;    jr      z,.nocrouch
;    set     BIT_PLAYER_CROUCHING,[hl]
;    jr      .skipcrouch
;.nocrouch
;    ; check if we should be able to uncrouch
;    ld      a,[Player_YPos]
;    sub     8
;    and     $f0
;    swap    a
;    ld      c,a
;    ld      a,[Player_XPos+2]
;    ld      e,a
;    ld      a,[Player_XPos]
;    and     $f0
;    or      c
;    ld      b,e
;    call    GetTile
;    ld      e,a
;    ld      d,0
;    ld      hl,Level_ColMapPtr
;    ld      a,[hl+]
;    ld      h,[hl]
;    ld      l,a
;    add     hl,de
;    ld      a,[hl]
;    and     a
;    jr      nz,.skipcrouch
;    ld      hl,Player_Flags
;    res     BIT_PLAYER_CROUCHING,[hl]
.skipcrouch
    ; check if player should jump
    ldh     a,[hPressedButtons]
    bit     BIT_A,a
    jr      z,.nojump
    ld      a,[Player_CoyoteTimer]
    and     a
    jr      nz,:+   ; skip airborne check if "coyote time" is active
    ld      hl,Player_Flags
    bit     BIT_PLAYER_AIRBORNE,[hl]
    jr      nz,.nojump
    ldh     a,[hHeldButtons]
    bit     BIT_UP,a
    jr      z,:+
    ld      a,low(-PLAYER_JUMP_HEIGHT_HIGH)
    ld      [Player_YVel],a
    ld      a,high(-PLAYER_JUMP_HEIGHT_HIGH)
    ld      [Player_YVel+1],a
    set     BIT_PLAYER_AIRBORNE,[hl]
    jr      .donejump
:   ld      a,low(-PLAYER_JUMP_HEIGHT)
    ld      [Player_YVel],a
    ld      a,high(-PLAYER_JUMP_HEIGHT)
    ld      [Player_YVel+1],a
    set     BIT_PLAYER_AIRBORNE,[hl]
.donejump
.nojump
    ; check if player should release jump
    ldh     a,[hReleasedButtons]
    bit     BIT_A,a
    jr      z,.norelease
    ld      a,[Player_YVel+1]
    bit     7,a
    jr      z,.norelease
    ld      hl,Player_YVel
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    srl     h
    rr      l
    set     7,h
    ld      a,l
    ld      [Player_YVel],a
    ld      a,h
    ld      [Player_YVel+1],a
.norelease
    ; left/right animation
    ld      hl,Player_Flags
    bit     BIT_PLAYER_AIRBORNE,[hl]
    jr      nz,.skipwalkanim
    ; check if left/right were just pressed
    ldh     a,[hPressedButtons]
    and     BTN_LEFT | BTN_RIGHT
    jr      z,:+
    player_set_animation Walk
    jr      .skipwalkanim
    ; check if left or right were just released
:   ldh     a,[hReleasedButtons]
    and     BTN_LEFT | BTN_RIGHT
    jr      z,.skipwalkanim
    player_set_animation Idle
    ; fall through
.skipwalkanim
    ; left/right movement
.checkright
    ldh     a,[hHeldButtons]
    bit     BIT_RIGHT,a
    jr      z,.checkleft
    ld      hl,Player_Flags
    res     BIT_PLAYER_DIRECTION,[hl]
    ld      hl,Player_XVel
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    ld      bc,PLAYER_ACCEL
    add     hl,bc
    ld      d,h
    ld      e,l
    ld      bc,PLAYER_WALK_SPEED
    call    Math_Compare16
    jr      nc,.nocapright
    ld      hl,PLAYER_WALK_SPEED
.nocapright
    ld      a,l
    ld      [Player_XVel],a
    ld      a,h
    ld      [Player_XVel+1],a
    jr      .nodecel
    
.checkleft
    ldh     a,[hHeldButtons]
    bit     BIT_LEFT,a
    jr      z,.decel
    ld      hl,Player_Flags
    set     BIT_PLAYER_DIRECTION,[hl]
    ld      hl,Player_XVel
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    ld      bc,-PLAYER_ACCEL
    add     hl,bc
    ld      d,h
    ld      e,l
    ld      bc,-PLAYER_WALK_SPEED
    call    Math_Compare16
    jr      c,.nocapleft
    ld      hl,-PLAYER_WALK_SPEED
.nocapleft
    ld      a,l
    ld      [Player_XVel],a
    ld      a,h
    ld      [Player_XVel+1],a
    jr      .nodecel
    
.decel
    ld      hl,Player_Flags
    bit     BIT_PLAYER_DIRECTION,[hl]
    jr      nz,.decelleft
.decelright
    ld      hl,Player_XVel
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    ld      bc,-PLAYER_DECEL
    add     hl,bc
    bit     7,h
    jr      z,.donedecel
    ld      hl,0
    jr      .donedecel
.decelleft
    ld      hl,Player_XVel
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    ld      bc,PLAYER_DECEL
    add     hl,bc
    bit     7,h
    jr      nz,.donedecel
    ld      hl,0
.donedecel
    ld      a,l
    ld      [Player_XVel],a
    ld      a,h
    ld      [Player_XVel+1],a
    ; fall through
.nodecel    
    ; gravity
    ld      hl,Player_Flags
    bit     BIT_PLAYER_AIRBORNE,[hl]
    jr      z,:+ ; prevent erroneous speed build up
    ld      hl,Player_YVel
    ld      a,[hl+]
    ld      b,[hl]
    ld      c,a
    ld      hl,Player_Grav
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    add     hl,bc
    ld      a,l
    ld      [Player_YVel],a
    ld      a,h
    ld      [Player_YVel+1],a
:
    ; velocity to position
    ld      hl,Player_XVel
    ld      a,[hl+]
    ld      b,[hl]
    ld      c,a
    ld      hl,Player_XPos
    ld      a,[hl+]
    ld      l,[hl]
    ld      h,a
    add     hl,bc
    ld      a,h
    ld      [Player_XPos],a
    ld      a,l
    ld      [Player_XPos+1],a
;    jr      nc,.donex
;    ld      a,[Player_XPos+2]
;    bit     7,h
;    jr      nz,:+
;    inc     a
;    jr      :++
;:   dec     a
;    jr      :+
;:   ld      [Player_XPos+2],a
.donex
    ld      hl,Player_Flags
    bit     BIT_PLAYER_AIRBORNE,[hl]
    jr      z,:+
    ld      hl,Player_YVel
    ld      a,[hl+]
    ld      b,[hl]
    ld      c,a
    ld      hl,Player_YPos
    ld      a,[hl+]
    ld      l,[hl]
    ld      h,a
    add     hl,bc
    ld      a,h
    ld      [Player_YPos],a
    ld      a,l
    ld      [Player_YPos+1],a
:   call    Player_CheckCollisionHorizontal
    call    Player_CheckCollisionVertical
    call    Player_CollisionResponseHorizontal
    call    Player_CollisionResponseVertical
    ; coyote time
    ld      a,[Player_YPos]
    add     24
    and     $f0
    swap    a
    ld      c,a
    ld      a,[Player_XPos+2]
    ld      b,a
    ld      a,[Player_XPos]
    and     $f0
    or      c
    call    GetTile
    ld      c,a
    ld      b,0
    ld      hl,Level_ColMapPtr
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    add     hl,bc
    ld      a,[hl]
    and     a
    jr      z,.coyote
    ; TODO: Check for any other collision types that count as non-solid
    ; snap to floor
    
    ld      a,[Player_VerticalCollisionSensorCenter]
    and     a
    jr      z,.animateplayer
    ;ld      l,a
    ;ld      h,0
    ;add     hl,hl   ; x2
    ;add     hl,hl   ; x4
    ;add     hl,hl   ; x8
    ;add     hl,hl   ; x16
    ;ld      a,[Player_XPos]
    ;and     $f
    ;ld      c,a
    ;ld      b,0
    ;add     hl,bc
    ;ld      b,h
    ;ld      c,l
    ;ld      hl,Level_ColHeightPtr
    ;ld      a,[hl+]
    ;ld      h,[hl]
    ;ld      l,a
    ;add     hl,bc
    ;ld      b,[hl]
    ld      a,[Player_YPos]
    ;add     17
    and     $f0
    ;sub     b
    ld      [Player_YPos],a
    jr      .animateplayer
.coyote
    ld      hl,Player_Flags
    bit     BIT_PLAYER_AIRBORNE,[hl]
    jr      nz,:+ ; skip ahead if player is already airborne
    ; init time
    ld      a,PLAYER_COYOTE_TIME
    ld      [Player_CoyoteTimer],a
:   set     BIT_PLAYER_AIRBORNE,[hl]    ; set airborne flag
    ld      a,[Player_CoyoteTimer]
    and     a
    jr      z,.animateplayer ; if coyote timer = 0, bail out
    dec     a
    ld      [Player_CoyoteTimer],a ; set new coyote timer
    ; animate player
.animateplayer
    ld      a,[Player_AnimTimer]
    dec     a
    ld      [Player_AnimTimer],a
    ret     nz
    ld      hl,Player_AnimPointer
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    ld      a,[hl+]
    cp      $ff
    jr      z,.animjump
.getframe
    ld      [Player_AnimTimer],a
    ld      a,[hl+]
    ld      [Player_AnimFrame],a
    jr      :+
.animjump
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    ld      a,[hl+]
    jr      .getframe
:   ld      a,l
    ld      [Player_AnimPointer],a
    ld      a,h
    ld      [Player_AnimPointer+1],a
    ret

Player_CollisionResponseVertical:
    pushbank
    ld      a,[Level_ColMapBank]
    bankswitch_to_a
    
    ld      a,[Player_VerticalCollisionSensorLeft]
    ld      e,a
    ld      c,a
    ld      b,0
    ld      hl,Level_ColMapPtr
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    add     hl,bc
    ld      a,[hl]
    ld      c,a
    ld      b,0
    ld      hl,.colresponsetable
    add     hl,bc
    add     hl,bc
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    rst     CallHL
    
    ld      a,[Player_VerticalCollisionSensorCenter]
    ld      e,a
    ld      c,a
    ld      b,0
    ld      hl,Level_ColMapPtr
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    add     hl,bc
    ld      a,[hl]
    ld      c,a
    ld      b,0
    ld      hl,.colresponsetable
    add     hl,bc
    add     hl,bc
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    rst     CallHL
    
    ld      a,[Player_VerticalCollisionSensorRight]
    ld      e,a
    ld      c,a
    ld      b,0
    ld      hl,Level_ColMapPtr
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    add     hl,bc
    ld      a,[hl]
    ld      c,a
    ld      b,0
    ld      hl,.colresponsetable
    add     hl,bc
    add     hl,bc
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    rst     CallHL
    
    popbank
    ret

.colresponsetable
    dw      .none
    dw      .solid
    dw      .topsolid
    dw      .slope_shallow
    dw      .slope_l
    dw      .slope_r
    dw      .slope_steep_l
    dw      .slope_steep_r
    dw      .solid
    dw      .none
    dw      .none
    dw      .none
    dw      .none
    dw      .none
.none
    ;ld      hl,Player_Flags
    ;set     BIT_PLAYER_AIRBORNE,[hl]
    ret
.topsolid
    ld      a,[Player_YVel+1]
    bit     7,a
    jr      nz,.none
    ; fall through
.solid
    ld      hl,Player_YVel+1
    bit     7,[hl]
    jr      nz,.solidceiling
.solidfloor
    ld      a,[Player_YPos]
    and     $f0
    ld      [Player_YPos],a
    ld      hl,Player_Flags
    bit     BIT_PLAYER_AIRBORNE,[hl]
    jr      nz,:+
    ; play walk or run animation based on whether player is moving
    ld      a,[Player_XVel]
    ld      b,a
    ld      a,[Player_XVel+1]
    or      b
    jr      z,.fidle
.fwalk
    player_set_animation Walk
    jr      :+
.fidle
    player_set_animation Idle
:   res     BIT_PLAYER_AIRBORNE,[hl]
    xor     a
    ld      [Player_CoyoteTimer],a
    ld      [Player_YVel],a
    ld      [Player_YVel+1],a
    jr      :+
.solidceiling
    ld      a,[Player_YPos]
    and     $f0
    add     16 + (32 - PLAYER_HEIGHT)
    ld      [Player_YPos],a
:   xor     a
    ld      [Player_YVel],a
    ld      [Player_YVel+1],a
    ret
.slope_shallow
    ; TODO
    ; 1. get tile penetration depth (player "foot" Y position mod 15)
    ; 2. get height of tile at player position (player X mod 15)
    ; 3. if penetration depth > tile height, snap to tile height and unset airborne flag
    ; ld      a,[Player_YPos]
    ; add     15
    ; ld      d,a
    ; and     15
    ; ld      e,a
    ; ld      a,[Player_XPos]
    ; and     15
    ; ld      c,a
    ; ld      b,0
    ; ld      a,[Player_VerticalCollisionSensorCenter]
    ; and     a
    ; ret     z
    ; ld      l,a
    ; ld      h,0
    ; add     hl,hl ; x2
    ; add     hl,hl ; x4
    ; add     hl,hl ; x8
    ; add     hl,hl ; x16
    ; add     hl,bc
    ; ld      b,h
    ; ld      c,l
    ; ld      hl,Level_ColHeightPtr
    ; ld      a,[hl+]
    ; ld      h,[hl]
    ; ld      l,a
    ; add     hl,bc
    ; ld      a,[hl]
    ; xor     $f
    ; inc     a
    ; cp      e
    ; jr      nc,.slope_floorcheck
    ; ld      a,[Player_YPos]
    ; and     $f0
    ; add     16
    ; sub     [hl]
    ; ld      [Player_YPos],a
    ; xor     a
    ; ld      [Player_YVel],a
    ; ld      [Player_YVel+1],a
    ; ld      [Player_CoyoteTimer],a
    ; ld      hl,Player_Flags
    ; res     BIT_PLAYER_AIRBORNE,[hl]
    ; ret
; .slope_floorcheck
    ; ld      a,[Player_Flags]
    ; bit     BIT_PLAYER_AIRBORNE,a
    ; ret     nz
    ; ld      a,[Player_YPos]
    ; and     $f0
    ; add     16
    ; sub     [hl]
    ; ld      [Player_YPos],a
    ; ret
    ret
.slope_l
    ; TODO
    ; 1. run "shallow slope" logic
    ; 2. push player back slightly (1px per frame?)
    ret
.slope_r
    ; TODO
    ; See slope_l
    ret
.slope_steep_l
    ; TODO
    ; 1. get tile penetration depth (player "foot" Y position mod 15)
    ; 2. get height of tile at player position (player X mod 15)
    ; 3. push player back until penetration depth > height
    ; 4. unset airborne flag (allow jumping off slope)
    ret
.slope_steep_r
    ; TODO
    ; see slope_steep_l
    ret
    
Player_CollisionResponseHorizontal:
    ld      a,[Player_HorizontalCollisionSensorTop]
    ld      e,a
    ld      c,a
    ld      b,0
    ld      hl,Level_ColMapPtr
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    add     hl,bc
    ld      a,[hl]
    ld      c,a
    ld      b,0
    ld      hl,.colresponsetable2
    add     hl,bc
    add     hl,bc
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    rst     CallHL
    
    
    ld      a,[Player_HorizontalCollisionSensorBottom]
    ld      e,a
    ld      c,a
    ld      b,0
    ld      hl,Level_ColMapPtr
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    add     hl,bc
    ld      a,[hl]
    ld      c,a
    ld      b,0
    ld      hl,.colresponsetable2
    add     hl,bc
    add     hl,bc
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    rst     CallHL
    ret
.colresponsetable2
    dw      .none           ; blank
    dw      .solid          ; solid
    dw      .none           ; top solid
    dw      .slope          ; normal slope
    dw      .slope          ; shallow slope
    dw      .slope          ; steep slope
    dw      .solid          ; breakable
    dw      .none           ; collectable
    dw      .none           ; big collectable TL
    dw      .none           ; big collectable TR
    dw      .none           ; big collectable BL
    dw      .none           ; big collectable BR
.none
    ret
.solid
    ld      a,[Player_XPos]
    ld      hl,Player_Flags
    bit     BIT_PLAYER_DIRECTION,[hl]
    jr      z,.right
.left
    ld      c,a
    ld      a,[Player_XPos+2]
    ld      b,a
    ld      a,c
    and     $f0
    add     PLAYER_WIDTH
    jr      nc,:+
    inc     b
:   ld      [Player_XPos],a
    ld      a,b
    ld      [Player_XPos+2],a
    jr      .donelr
.right
    ld      c,a
    ld      a,[Player_XPos+2]
    ld      b,a
    ld      a,c
    and     $f0
    add     15-PLAYER_WIDTH
    jr      nc,:+
    dec     b
:   ld      [Player_XPos],a
    ld      a,b
    ld      [Player_XPos+2],a
.donelr
    ret
.slope
    ; TODO
    ret

Player_CheckCollisionVertical:
    ld      a,[Player_YVel+1]
    bit     7,a ; is player moving up?
    ld      a,[Player_YPos]
    jr      z,.goingdown
    ; fall through
.goingup
    ld      hl,Player_Flags
    bit     BIT_PLAYER_CROUCHING,[hl]
    jr      nz,:+
    add     16-PLAYER_HEIGHT
    jr      :+
.goingdown
    add     15
    ; fall through
:   and     $f0
    swap    a
    ld      c,a
    ; get left collision point
    ld      a,[Player_XPos+2]
    ld      e,a
    ld      a,[Player_XPos]
    sub     PLAYER_WIDTH-2
    jr      nc,:+
    dec     e
:   and     $f0
    or      c
    ld      b,e
    call    GetTile
    ld      [Player_VerticalCollisionSensorLeft],a
    ; get right collision point
    ld      a,[Player_XPos+2]
    ld      e,a
    ld      a,[Player_XPos]
    add     PLAYER_WIDTH-2
    jr      nc,:+
    inc     e
:   and     $f0
    or      c
    ld      b,e
    call    GetTile
    ld      [Player_VerticalCollisionSensorRight],a
    ; get center collision point
    ld      a,[Player_XPos+2]
    ld      e,a
    ld      a,[Player_XPos]
    and     $f0
    or      c
    ld      b,e
    call    GetTile
    ld      [Player_VerticalCollisionSensorCenter],a
    ret

; Check for collision using two sensors - one at player Y - 8 pixels, one at player Y + 8 pixels, both at (X + 6) * [direction]
; Returns carry if a collision is found
Player_CheckCollisionHorizontal:
    ld      d,0
    ; check top sensor
    ld      a,[Player_XPos+2]
    ld      e,a
    ld      hl,Player_Flags
    bit     BIT_PLAYER_DIRECTION,[hl]
    jr      z,.ur
.ul
    ld      a,[Player_XPos]
    sub     PLAYER_WIDTH
    jr      nc,:+
    dec     e
    jr      :+
.ur
    ld      a,[Player_XPos]
    add     PLAYER_WIDTH
    jr      nc,:+
    inc     e
:   and     $f0
    ld      b,a
    ld      a,[Player_Flags]
    bit     BIT_PLAYER_CROUCHING,a
    ld      a,[Player_YPos]
    jr      z,.nocrouch
.crouch
    add     8
    jr      :+
.nocrouch
    sub     8
:   and     $f0
    swap    a
    or      b
    ld      b,e
    call    GetTile
    ld      [Player_HorizontalCollisionSensorTop],a
.nocol1
    ; check bottom sensor
    ld      a,[Player_XPos+2]
    ld      e,a
    ld      hl,Player_Flags
    bit     BIT_PLAYER_DIRECTION,[hl]
    jr      z,.br
.bl
    ld      a,[Player_XPos]
    sub     PLAYER_WIDTH
    jr      nc,:+
    dec     e
    jr      :+
.br
    ld      a,[Player_XPos]
    add     PLAYER_WIDTH
    jr      nc,:+
    inc     e
:   and     $f0
    ld      b,a
    ld      a,[Player_YPos]
    add     8
    and     $f0
    swap    a
    or      b
    ld      b,e
    call    GetTile
    ld      [Player_HorizontalCollisionSensorBottom],a
    ret

Player_Noclip:
    xor     a
    ld      [Player_XVel],a
    ld      [Player_XVel+1],a
    ld      [Player_YVel],a
    ld      [Player_YVel+1],a

    ld      e,2    
    ld      hl,hHeldButtons
    bit     BIT_B,[hl]
    jr      z,:+
    ld      e,8
:   bit     BIT_UP,[hl]
    call    nz,.up
    bit     BIT_DOWN,[hl]
    call    nz,.down
    bit     BIT_LEFT,[hl]
    call    nz,.left
    bit     BIT_RIGHT,[hl]
    call    nz,.right
    ret
.up
    ld      a,-1
    ld      [Player_YVel],a
    ld      [Player_YVel+1],a
    ld      a,[Player_YPos]
    sub     e
    ld      [Player_YPos],a
    ret
.down
    xor     a
    ld      [Player_YVel],a
    ld      [Player_YVel+1],a
    ld      a,[Player_YPos]
    add     e
    ld      [Player_YPos],a
    ret
.left
    push    hl
    ld      hl,Player_Flags
    set     BIT_PLAYER_DIRECTION,[hl]
    ld      a,[Player_XPos]
    sub     e
    ld      [Player_XPos],a
    jr      nc,:+
    ld      hl,Player_XPos+2
    dec     [hl]
:   pop     hl
    ret
.right
    push    hl
    ld      hl,Player_Flags
    res     BIT_PLAYER_DIRECTION,[hl]
    ld      a,[Player_XPos]
    add     e
    ld      [Player_XPos],a
    jr      nc,:+
    ld      hl,Player_XPos+2
    inc     [hl]
:   pop     hl
    ret

DrawPlayer:
    ; copy GFX
    ld      a,1
    ldh     [rVBK],a
    farload bc,PlayerTiles
    ld      a,[Player_AnimFrame]
    ld      l,a
    ld      h,0
    add     hl,hl   ; x2
    add     hl,hl   ; x4
    add     hl,hl   ; x8
    add     hl,hl   ; x16
    add     hl,hl   ; x32
    add     hl,hl   ; x64
    add     hl,hl   ; x128
    add     hl,hl   ; x256
    add     hl,bc
    ld      a,h
    ldh     [rHDMA1],a
    ld      a,l
    ldh     [rHDMA2],a
    ld      a,high(_VRAM)
    ldh     [rHDMA3],a
    ld      a,low(_VRAM)
    ldh     [rHDMA4],a
    ld      a,$0f
    ldh     [rHDMA5],a
    ; put player metasprite in OAM
    ld      hl,Player_Flags
    bit     BIT_PLAYER_DIRECTION,[hl]
    ld      hl,.sprite
    jr      z,:+
    ld      hl,.spritef
:   ld      de,OAMBuffer
    ld      b,(.sprite_end-.sprite)/4
.loop
    ; y position
    ld      a,[hl+]
    ld      c,a
    ld      a,[Player_YPos]
    add     c
    ld      c,a
    ld      a,[Level_CameraY]
    cpl
    inc     a
    add     c
    ld      [de],a
    inc     e
    ; x position
    ld      a,[hl+]
    ld      c,a
    ld      a,[Player_XPos]
    add     c
    ld      c,a
    ld      a,[Level_CameraX]
    cpl
    inc     a
    add     c
    ld      [de],a
    inc     e
    ; sprite
    ld      a,[hl+]
    ld      [de],a
    inc     e
    ; attribute
    ld      a,[hl+]
    ld      [de],a
    inc     e
    dec     b
    jr      nz,.loop
    
    ret
.sprite
    db -16+16, 8 -16, 0, 8
    db -16+16, 8 - 8, 2, 8
    db -16+16, 8 + 0, 4, 8
    db -16+16, 8 + 8, 6, 8
    db   0+16, 8 -16, 8, 8
    db   0+16, 8 - 8,10, 8
    db   0+16, 8 + 0,12, 8
    db   0+16, 8 + 8,14, 8
.sprite_end
.spritef
    db -16+16, 8 -16, 6, 8 | OAMF_XFLIP
    db -16+16, 8 - 8, 4, 8 | OAMF_XFLIP
    db -16+16, 8 + 0, 2, 8 | OAMF_XFLIP
    db -16+16, 8 + 8, 0, 8 | OAMF_XFLIP
    db   0+16, 8 -16,14, 8 | OAMF_XFLIP
    db   0+16, 8 - 8,12, 8 | OAMF_XFLIP
    db   0+16, 8 + 0,10, 8 | OAMF_XFLIP
    db   0+16, 8 + 8, 8, 8 | OAMF_XFLIP

Player_Anim_Idle:
    db  16,frame_idle1
    db  16,frame_idle2
    db  16,frame_idle1
    db  8,frame_idle2
    db  8,frame_idle3
    db  $ff
    dw  Player_Anim_Idle

Player_Anim_Walk:
    db  5,frame_walk1
    db  6,frame_walk2
    db  5,frame_walk3
    db  6,frame_walk4
    db  5,frame_walk5
    db  6,frame_walk6
    db  5,frame_walk7
    db  6,frame_walk8
    db  $ff
    dw  Player_Anim_Walk

section "Player GFX",romx,align[8]

rsreset
macro animframe
def frame_\1 rb
    incbin "GFX/Player/player_\1.png.2bpp"
endm

PlayerTiles:
    animframe  idle1
    animframe  idle2
    animframe  idle3
    animframe  walk1
    animframe  walk2
    animframe  walk3
    animframe  walk4
    animframe  walk5
    animframe  walk6
    animframe  walk7
    animframe  walk8
    
PlayerPlaceholderTiles:
    incbin  "GFX/Player/placeholder.png.2bpp"
PlayerPalette:  incbin  "GFX/player.pal"
