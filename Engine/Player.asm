section "Player RAM",wram0

def PLAYER_ACCEL                = $040
def PLAYER_DECEL                = $020
def PLAYER_WALK_SPEED           = $120
def PLAYER_JUMP_HEIGHT          = $400
; def PLAYER_JUMP_HEIGHT_HIGH     = $490
def PLAYER_GRAVITY              = $028
def PLAYER_TERMINAL_VELOCITY    = $800
def PLAYER_COYOTE_TIME          = 15 ; coyote time in frames
def PLAYER_WAND_TIME            = 15 ; wand time in frames

def PLAYER_WIDTH                = 5 ; player hitbox width relative to center
def PLAYER_HEIGHT               = 24 ; player hitbox height relative from bottom

def SIZEOF_PROJECTILE = 10
def MAX_PROJECTILES = 2

rsreset
def PROJECTILE_SPR rb
def PROJECTILE_TTL rb
def PROJECTILE_PX  rw
def PROJECTILE_VX  rw
def PROJECTILE_PY  rw
def PROJECTILE_VY  rw

rsreset
def BIT_PLAYER_DIRECTION    rb
def BIT_PLAYER_AIRBORNE     rb
def BIT_PLAYER_CROUCHING    rb
def BIT_PLAYER_WAND         rb
if BUILD_DEBUG
def BIT_PLAYER_NOCLIP       rb
endc

Player_RAMStart:
Player_XPos:    ds  2   ; x position (Q16.8)
Player_YPos:    ds  2   ; y position (Q8.8)
Player_XVel:    ds  2   ; added to xpos each frame
Player_YVel:    ds  2   ; added to ypos each frame
Player_Grav:    ds  2   ; added to yvel each frame
Player_Flags:   db

Player_HorizontalCollisionSensorTop:    db
Player_HorizontalCollisionSensorBottom: db
Player_VerticalCollisionSensorLeft:     db
Player_VerticalCollisionSensorRight:    db
Player_VerticalCollisionSensorCenter:   db
Player_CoyoteTimer:                     db
Player_AnimFrame:                       db
Player_AnimTimer:                       db
Player_AnimPointer:                     dw
Player_AnimCurrent:                     dw
Player_AnimFlag:                        db
Player_WandTimer:                       db
Player_Projectiles: ds  MAX_PROJECTILES * SIZEOF_PROJECTILE
Player_RAMEnd:

macro player_set_animation
    ;push    af
    ld      a,[Player_AnimCurrent]
    ld      c,a
    ld      a,[Player_AnimCurrent+1]
    ld      b,a
    ld      de,Player_Anim_\1
    call    Math_Compare16
    jr      z,:+
    ld      a,low(Player_Anim_\1)
    ld      [Player_AnimPointer],a
    ld      [Player_AnimCurrent],a
    ld      a,high(Player_Anim_\1)
    ld      [Player_AnimPointer+1],a
    ld      [Player_AnimCurrent+1],a
    ld      a,1
    ld      [Player_AnimTimer],a
:   
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
    ; ld      hl,PlayerStarTiles
    ; ld      de,$8100
    call    DecodeWLE
    ld      a,e
    ldh     [hObjGFXPos],a
    ld      a,d
    ldh     [hObjGFXPos+1],a
    ld      hl,PlayerPalette
    ld      a,8
    call    LoadPal
    ; ld      hl,PlayerStarPalette
    ld      a,9
    call    LoadPal
    ; ld      hl,BorisPalette
    ; ld      a,10
    ; call    LoadPal
    ld      a,low(PLAYER_GRAVITY)
    ld      [Player_Grav],a
    xor     a   ; ld a,high(PLAYER_GRAVITY)
    ld      [Player_Grav+1],a
    
    player_set_animation Idle
    ret

ProcessPlayer:
    if BUILD_DEBUG
        ld      hl,Player_Flags
        bit     BIT_PLAYER_NOCLIP,[hl]
        jp      nz,Player_Noclip
    endc
    
    ; wand fire check
    ;ld      hl,Player_Flags
    ;bit     BIT_PLAYER_WAND,[hl]
    ;jr      nz,.nowand
    ldh     a,[hPressedButtons]
    bit     BIT_B,a
    jr      z,.nowand
    call    Player_MakeStarProjectile
    jr      c,.nowand
    ld      hl,Player_Flags
    set     BIT_PLAYER_WAND,[hl]
    ld      a,PLAYER_WAND_TIME
    ld      [Player_WandTimer],a
    call    Player_Wand
    jp      .skipcontrols
.nowand
    
:   ; check if player has wand out
    ld      hl,Player_Flags
    bit     BIT_PLAYER_WAND,[hl]
    push    af
    call    nz,Player_Wand
    pop     af
    jr      z,:+
    ; cut horizontal and vertical velocity
    xor     a
    ld      [Player_XVel],a
    ld      [Player_YVel],a
    ld      [Player_XVel+1],a
    ld      [Player_YVel+1],a
    jp      .animateplayer
:   ;res     BIT_PLAYER_WAND,[hl]
    
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
;.skipcrouch
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
    ;ldh     a,[hHeldButtons]
    ;bit     BIT_UP,a
    ;jr      z,:+
    ;ld      a,low(-PLAYER_JUMP_HEIGHT_HIGH)
    ;ld      [Player_YVel],a
    ;ld      a,high(-PLAYER_JUMP_HEIGHT_HIGH)
    ;ld      [Player_YVel+1],a
    ;set     BIT_PLAYER_AIRBORNE,[hl]
    ;jr      .donejump
:   ld      a,low(-PLAYER_JUMP_HEIGHT)
    ld      [Player_YVel],a
    ld      a,high(-PLAYER_JUMP_HEIGHT)
    ld      [Player_YVel+1],a
    set     BIT_PLAYER_AIRBORNE,[hl]
    player_set_animation Jump
.donejump
.nojump
    ; run coyote timer
    ld      a,[Player_CoyoteTimer]
    and     a
    jr      z,:+
    dec     a
    ld      [Player_CoyoteTimer],a
:   ; check if player should release jump
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
.decel2
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
    ; do walk/idle animation
    ld      hl,Player_Flags
    bit     BIT_PLAYER_AIRBORNE,[hl]
    jr      nz,:+
    ld      a,[Player_XVel]
    ld      b,a
    ld      a,[Player_XVel+1]
    or      b
    jr      z,.idle
    player_set_animation Walk
    jr      :+
.idle
    player_set_animation Idle
:
.skipcontrols
    
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
    bit     7,h
    jr      nz,:+
    ld      a,[Player_Flags]
    bit     BIT_PLAYER_WAND,a
    jr      nz,:+
    player_set_animation Fall
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
    ld      a,[Player_YVel]
    and     a
    jr      z,:+
    bit     7,h
    jr      z,.animateplayer    ; skip if player isn't falling
:   ld      a,[Player_YVel+1]
    or      b
    jr      nz,.animateplayer
    ld      a,[Player_YPos]
    add     16
    and     $f0
    swap    a
    ld      c,a
    ; ld      a,[Player_XPos+2]
    ; ld      b,a
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
    ; snap to floor
    ld      a,[Player_VerticalCollisionSensorCenter]
    ld      c,a
    ld      b,0
    ld      hl,Level_ColMapPtr
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    add     hl,bc
    ld      a,[hl]
    and     a
    jr      z,:+
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
    jr      nz,.animateplayer ; skip ahead if player is already airborne
    ; init time
    ld      a,PLAYER_COYOTE_TIME
    ld      [Player_CoyoteTimer],a
:   set     BIT_PLAYER_AIRBORNE,[hl]    ; set airborne flag
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
.getbyte
    ld      a,[hl+]
    cp      $ff
    jr      z,.animjump
    cp      $fe
    jr      z,.animflag
.getframe
    ld      [Player_AnimTimer],a
    ld      a,[hl+]
    ld      [Player_AnimFrame],a
    jr      :+
.animjump
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    jr      .getbyte
:   ld      a,l
    ld      [Player_AnimPointer],a
    ld      a,h
    ld      [Player_AnimPointer+1],a
    ret
.animflag
    ld      a,[hl+]
    ld      [Player_AnimFlag],a
    jr      .getbyte

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
.none
    ret
.solid
    ld      a,[Player_XPos]
    ld      hl,Player_Flags
    bit     BIT_PLAYER_DIRECTION,[hl]
    jr      z,.right
.left
    ld      c,a
    ; ld      a,[Player_XPos+2]
    ; ld      b,a
    ld      a,c
    and     $f0
    add     PLAYER_WIDTH
    ; jr      nc,:+
    ; inc     b
:   ld      [Player_XPos],a
    ; ld      a,b
    ; ld      [Player_XPos+2],a
    jr      .donelr
.right
    ld      c,a
    ; ld      a,[Player_XPos+2]
    ; ld      b,a
    ld      a,c
    and     $f0
    add     15-PLAYER_WIDTH
    ; jr      nc,:+
    ; dec     b
:   ld      [Player_XPos],a
    ; ld      a,b
    ; ld      [Player_XPos+2],a
.donelr
    ret

Player_CheckCollisionVertical:
    ld      a,[Player_YVel+1]
    bit     7,a ; is player moving up?
    ld      a,[Player_YPos]
    jr      z,.goingdown
    ; fall through
.goingup
    ; ld      hl,Player_Flags
    ; bit     BIT_PLAYER_CROUCHING,[hl]
    jr      nz,:+
    add     16-PLAYER_HEIGHT
    jr      c,.oob
    jr      :+
.goingdown
    add     15
    jr      c,.oob
    ; fall through
:   and     $f0
    swap    a
    ld      c,a
    ; get left collision point
    ; ld      a,[Player_XPos+2]
    ; ld      e,a
    ld      a,[Player_XPos]
    sub     PLAYER_WIDTH-2
    ; jr      nc,:+
    ; dec     e
:   and     $f0
    or      c
    ; ld      b,e
    call    GetTile
    ld      [Player_VerticalCollisionSensorLeft],a
    ; get right collision point
    ; ld      a,[Player_XPos+2]
    ; ld      e,a
    ld      a,[Player_XPos]
    add     PLAYER_WIDTH-2
    ; jr      nc,:+
    ; inc     e
:   and     $f0
    or      c
    ; ld      b,e
    call    GetTile
    ld      [Player_VerticalCollisionSensorRight],a
    ; get center collision point
    ; ld      a,[Player_XPos+2]
    ; ld      e,a
    ld      a,[Player_XPos]
    and     $f0
    or      c
    ; ld      b,e
    call    GetTile
    ld      [Player_VerticalCollisionSensorCenter],a
    ret
.oob
    ld      a,1
    ld      [Player_VerticalCollisionSensorLeft],a
    ld      [Player_VerticalCollisionSensorCenter],a
    ld      [Player_VerticalCollisionSensorRight],a
    ret

; Check for collision using two sensors - one at player Y - 8 pixels, one at player Y + 8 pixels, both at (X + 6) * [direction]
; Returns carry if a collision is found
Player_CheckCollisionHorizontal:
    ld      d,0
    ; check top sensor
    ; ld      a,[Player_XPos+2]
    ; ld      e,a
    ld      hl,Player_Flags
    bit     BIT_PLAYER_DIRECTION,[hl]
    jr      z,.ur
.ul
    ld      a,[Player_XPos]
    sub     PLAYER_WIDTH
    ; jr      nc,:+
    ; dec     e
    jr      :+
.ur
    ld      a,[Player_XPos]
    add     PLAYER_WIDTH
    ; jr      nc,:+
    ; inc     e
:   and     $f0
    ld      b,a
    ; ld      a,[Player_Flags]
    ; bit     BIT_PLAYER_CROUCHING,a
    ld      a,[Player_YPos]
    ; jr      z,.nocrouch
; .crouch
    ; add     8
    ; jr      :+
; .nocrouch
    sub     8
:   and     $f0
    swap    a
    or      b
    ; ld      b,e
    call    GetTile
    ld      [Player_HorizontalCollisionSensorTop],a
.nocol1
    ; check bottom sensor
    ; ld      a,[Player_XPos+2]
    ; ld      e,a
    ld      hl,Player_Flags
    bit     BIT_PLAYER_DIRECTION,[hl]
    jr      z,.br
.bl
    ld      a,[Player_XPos]
    sub     PLAYER_WIDTH
    ; jr      nc,:+
    ; dec     e
    jr      :+
.br
    ld      a,[Player_XPos]
    add     PLAYER_WIDTH
    ; jr      nc,:+
    ; inc     e
:   and     $f0
    ld      b,a
    ld      a,[Player_YPos]
    add     8
    and     $f0
    swap    a
    or      b
    ; ld      b,e
    call    GetTile
    ld      [Player_HorizontalCollisionSensorBottom],a
    ret

if BUILD_DEBUG
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
    ld      e,4
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
    ld      a,[Player_YPos]
    sub     e
    ld      [Player_YPos],a
    ret
.down
    ld      a,[Player_YPos]
    add     e
    ld      [Player_YPos],a
    ret
.left
    ; push    hl
    ld      a,[Player_XPos]
    sub     e
    ld      [Player_XPos],a
    ; jr      nc,:+
    ; ld      hl,Player_XPos+2
    ; dec     [hl]
:   ; pop     hl
    ret
.right
    ; push    hl
    ld      a,[Player_XPos]
    add     e
    ld      [Player_XPos],a
    ; jr      nc,:+
    ; ld      hl,Player_XPos+2
    ; inc     [hl]
:   ; pop     hl
    ret
endc

Player_Wand:
    bit     BIT_PLAYER_DIRECTION,[hl]
    jr      z,.right
.left
    player_set_animation WandLeft
    jr      .next
.right
    player_set_animation WandRight
.next
    ld      a,[Player_WandTimer]
    dec     a
    ld      [Player_WandTimer],a
    ret     nz
    res     BIT_PLAYER_WAND,[hl]
    ret

DrawPlayer:
    ; copy GFX
    ld      a,1
    ldh     [rVBK],a
    farload bc,PlayerTiles
    ld      a,[Player_AnimFrame]
    ld      e,a
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
    ld      hl,Player_SpriteMasks
    ld      d,0
    add     hl,de
    ld      c,[hl]
    ld      hl,Player_Flags
    bit     BIT_PLAYER_DIRECTION,[hl]
    ld      hl,.sprite
    jr      z,:+
    ld      hl,.spriteflip
:   ld      de,OAMBuffer
    ld      b,(.sprite_end-.sprite)/4
.loop
    rr      c
    jr      nc,.next
    push    bc
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
    pop     bc
:   dec     b
    jr      nz,.loop
    ld      a,e
    ldh     [hOAMPos],a
    ret
.next
    push    bc
    ld      bc,4
    add     hl,bc
    pop     bc
    jr      :-
    
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
.spriteflip
    db -16+16, 8 + 8, 0, 8 | OAMF_XFLIP
    db -16+16, 8 + 0, 2, 8 | OAMF_XFLIP
    db -16+16, 8 - 8, 4, 8 | OAMF_XFLIP
    db -16+16, 8 -16, 6, 8 | OAMF_XFLIP
    db   0+16, 8 + 8, 8, 8 | OAMF_XFLIP
    db   0+16, 8 + 0,10, 8 | OAMF_XFLIP
    db   0+16, 8 - 8,12, 8 | OAMF_XFLIP
    db   0+16, 8 -16,14, 8 | OAMF_XFLIP

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
    db  5,frame_walk2
    db  5,frame_walk3
    db  5,frame_walk4
    db  5,frame_walk5
    db  5,frame_walk6
    db  5,frame_walk7
    db  5,frame_walk8
    db  $ff
    dw  Player_Anim_Walk

Player_Anim_Jump:
    db  1,frame_jump
    db  $ff
    dw  Player_Anim_Jump

Player_Anim_Fall:
    db  4,frame_fall0
:   db  4,frame_fall1
    db  4,frame_fall2
    db  $ff
    dw  :-
    
Player_Anim_FallFast:
    db  3,frame_fall3
    db  3,frame_fall4
    db  $ff
    dw  Player_Anim_FallFast

Player_Anim_WandLeft:
    db  24,frame_wand_left
    db  $ff
    dw  Player_Anim_WandLeft
    
Player_Anim_WandRight:
    db  24,frame_wand_right
    db  $ff
    dw  Player_Anim_WandRight

; ========

Player_MakeStarProjectile:
    call    Player_FindFreeProjectileSlot
    ret     c
    ; sprite
    ld      a,$10
    ld      [hl+],a
    ; TTL
    ld      a,-1
    ld      [hl+],a
    ; X pos
    ld      a,[Player_Flags]
    bit     BIT_PLAYER_DIRECTION,a
    ld      a,[Player_XPos]
    jr      z,.right
.left
    sub     14
    jr      :+
.right
    add     14
:   ld      [hl],0
    inc     hl
    ld      [hl+],a
    ; X velocity
    xor     a
    ld      [hl+],a
    ld      a,[Player_Flags]
    bit     BIT_PLAYER_DIRECTION,a
    ld      a,3
    jr      z,:+
    cpl
    inc     a
:   ld      [hl+],a
    ; Y pos
    xor     a
    ld      [hl+],a
    ld      a,[Player_YPos]
    inc     a
    ld      [hl+],a
    ; Y velocity
    xor     a
    ld      [hl+],a
    ld      [hl+],a 
    ret

Player_FindFreeProjectileSlot:
    ld      hl,Player_Projectiles
    ld      b,MAX_PROJECTILES
    ld      de,SIZEOF_PROJECTILE
:   ld      a,[hl]
    and     a
    jr      z,:+
    add     hl,de
    dec     b
    jr      nz,:-
    scf ; if we're here, we're out of free projectile slots
    ret
:   and     a
    ret
    
Player_ProcessProjectiles:
    ld      hl,Player_Projectiles
    ld      b,MAX_PROJECTILES
.loop
    ; sprite
    ld      a,[hl]
    and     a
    jp      z,.delete2
    ldh     a,[hGlobalTick]
    rra
    and     $7
    add     a
    add     $10
    ld      [hl+],a
;    inc     hl
    ; TTL
    ld      a,[hl]
    cp      -1
    jr      z,:+
    dec     a
    jp      z,.delete
    ld      [hl+],a
    jr      :++
:   inc     hl
:   ; can't have an anonymous label and rept on the same line smh my head
    push    bc
    ; X velocity to position
    push    hl
    ld      a,[hl+]
    ld      c,a
    ld      a,[hl+]
    ld      b,a
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    add     hl,bc
    ld      d,h
    ld      e,l
    pop     hl
    ld      a,e
    ld      [hl+],a
    ld      a,l
    ldh     [hTempPtr1],a
    ld      a,h
    ldh     [hTempPtr1+1],a
    ld      a,d
    ld      [hl+],a
    inc     hl
    inc     hl
    
    ; Y velocity to position
    push    hl
    ld      a,[hl+]
    ld      c,a
    ld      a,[hl+]
    ld      b,a
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    add     hl,bc
    ld      d,h
    ld      e,l
    pop     hl
    ld      a,e
    ld      [hl+],a
    ld      a,l
    ldh     [hTempPtr2],a
    ld      a,h
    ldh     [hTempPtr2+1],a
    ld      a,d
    ld      [hl+],a
    push    hl
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    ld      bc,PLAYER_GRAVITY
    add     hl,bc
    ld      b,h
    ld      c,l
    pop     hl
    ld      a,c
    ld      [hl+],a
    ld      a,b
    ld      [hl+],a
    
    
    ; make sparkles
    ldh     a,[hGlobalTick]
    and     3
    jr      nz,:+
    push    bc
    push    hl
    push    de
    ld      hl,hTempPtr1
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    ld      d,[hl]
    inc     hl
    inc     hl
    inc     hl
    inc     hl
    ld      e,[hl]
    ld      b,OBJID_Sparkle
    call    CreateObject
    pop     de
    pop     hl
    pop     bc
:    
    ld      a,[Level_ColMapBank]
    bankswitch_to_a
    
    ; skip collision checks if projectile is inside a topsolid tile
    push    hl
    ld      hl,hTempPtr1
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    ld      a,[hl]
    and     $f0
    ld      b,a
    ld      hl,hTempPtr2
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    ld      a,[hl]
    and     $f0
    swap    a
    or      b
    ld      l,a
    ld      h,high(Level_Map)
    ld      a,[hl]
    ld      c,a
    ld      b,0
    ld      hl,Level_ColMapPtr
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    add     hl,bc
    ld      a,[hl]
    cp      COLLISION_TOPSOLID
    pop     hl
    jp      z,.skipcollisionchecks
    
    ; bounce off floor
    push    hl
    ld      hl,hTempPtr1
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    ld      a,[hl]
    and     $f0
    ld      b,a
    ld      hl,hTempPtr2
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    ld      a,[hl]
    add     2
    and     $f0
    swap    a
    or      b
    ld      l,a
    ld      h,high(Level_Map)
    ld      a,[hl]
    ld      c,a
    ld      b,0
    ld      hl,Level_ColMapPtr
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    add     hl,bc
    ld      a,[hl]
    cp      COLLISION_SOLID
    jr      z,:+
    cp      COLLISION_TOPSOLID
    jr      nz,.donebouncev
:   ld      hl,hTempPtr2
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    inc     l
    push    hl
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    bit     7,h
    jr      nz,:+
    srl     h
    rr      l
    ld      d,h
    ld      e,l
    srl     h
    rr      l
    srl     h
    rr      l
    add     hl,de
:   call    Math_Neg16
    pop     de
    ld      a,l
    ld      [de],a
    inc     e
    ld      a,h
    ld      [de],a
    ld      hl,hTempPtr2
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    dec     l
    xor     a
    ld      [hl+],a
    ld      a,[hl+]
    and     $f0
    sub     2
    ld      [hl],a
    
    ld      hl,hTempPtr1
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    inc     l
    push    hl
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    bit     7,h
    push    af
    call    Math_Abs16
    ld      de,-$40
    add     hl,de
    jr      c,:+
    pop     af
    pop     hl
    pop     hl
    push    hl
    ld      hl,hTempPtr1
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    ld      d,[hl]
    inc     hl
    inc     hl
    inc     hl
    inc     hl
    ld      e,[hl]
    ;ld      b,OBJID_Sparkle
    ;call    CreateObject
    pop     hl
    pop     bc
    ld      a,l
    sub     SIZEOF_PROJECTILE
    ld      l,a
    jp      .delete2
:   pop     af
    call    nz,Math_Neg16
    pop     de
    ld      a,l
    ld      [de],a
    inc     e
    ld      a,h
    ld      [de],a
    
    ; TODO: Bounce sound effect
.donebouncev
   pop     hl
   
    ; bounce off left wall
    push    hl
    ld      hl,hTempPtr1
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    ld      a,[hl]
    sub     4
    and     $f0
    ld      b,a
    ld      hl,hTempPtr2
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    ld      a,[hl]
    sub     2
    and     $f0
    swap    a
    or      b
    ld      l,a
    ld      h,high(Level_Map)
    ld      a,[hl]
    ld      c,a
    ld      b,0
    ld      hl,Level_ColMapPtr
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    add     hl,bc
    ld      a,[hl]
    cp      COLLISION_SOLID
    jr      nz,.donebouncehl
    ld      hl,hTempPtr1
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    dec     l
    xor     a
    ld      [hl+],a
    ld      a,[hl]
    and     $f0
    add     2
    ld      [hl+],a
    push    hl
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    ld      de,$80
    add     hl,de
    jr      nc,:+
    ld      hl,0
:   call    Math_Neg16
    pop     de
    ld      a,l
    ld      [de],a
    inc     e
    ld      a,h
    ld      [de],a
    jr      .donebouncehr
.donebouncehl
   pop     hl

    ; bounce off right wall
    push    hl
    ld      hl,hTempPtr1
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    ld      a,[hl]
    add     4
    and     $f0
    ld      b,a
    ld      hl,hTempPtr2
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    ld      a,[hl]
    sub     2
    and     $f0
    swap    a
    or      b
    ld      l,a
    ld      h,high(Level_Map)
    ld      a,[hl]
    ld      c,a
    ld      b,0
    ld      hl,Level_ColMapPtr
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    add     hl,bc
    ld      a,[hl]
    cp      COLLISION_SOLID
    jr      nz,.donebouncehr
    ld      hl,hTempPtr1
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    dec     l
    xor     a
    ld      [hl+],a
    ld      a,[hl]
    and     $f0
    sub     2
    ld      [hl+],a
    push    hl
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    ld      de,-$80
    add     hl,de
    jr      c,:+
    ld      hl,0
:   call    Math_Neg16
    pop     de
    ld      a,l
    ld      [de],a
    inc     e
    ld      a,h
    ld      [de],a
.donebouncehr
   pop     hl

.skipcollisionchecks
    
:   ; TODO: Delete projectile if it touches an enemy
    pop     bc
    dec     b
    jp      nz,.loop
    ret
.delete
    dec     hl
.delete2
    xor     a
    rept    SIZEOF_PROJECTILE
        ld      [hl+],a
    endr
    dec     b
    jp      nz,.loop
    ret
.startable
    db  $10,$10,$12,$12,$14,$14,$12,$12

Player_DrawProjectiles:
    ld      a,[hOAMPos]
    ld      e,a
    ld      d,0
    ld      hl,OAMBuffer
    add     hl,de
    ld      d,h
    ld      e,l
    ld      hl,Player_Projectiles
    ld      b,MAX_PROJECTILES
:   ld      a,[hl+] ; sprite
    and     a
    jr      z,.next
    ld      c,a
    inc     hl      ; TTL
    inc     hl      ; x pos low
    ld      a,[hl+] ; x pos high
    push    af
    inc     hl      ; x velocity low
    inc     hl      ; x velocity high
    inc     hl      ; y pos low
    ld      a,[hl+] ; y pos high
    inc     hl      ; y velocity low
    inc     hl      ; y velocity high
    ; write Y pos
    push    bc
    ld      b,a
    ld      a,[Level_CameraY]
    cpl
    inc     a
    add     b
    add     8
    ld      [de],a
    inc     e
    pop     bc
    ; write X pos
    pop     af
    push    bc
    ld      b,a
    ld      a,[Level_CameraX]
    cpl
    inc     a
    add     b
    add     4
    ld      [de],a
    inc     e
    ld      a,c
    ld      [de],a
    inc     e
    ld      a,1 | %00001000
    ld      [de],a
    inc     e
    pop     bc
    dec     b
    jr      nz,:-
    ld      a,e
    ldh     [hOAMPos],a
    ret
.next
    push    bc
    ld      bc,9
    add     hl,bc
    pop     bc
    dec     b
    jr      nz,:-
    ld      a,e
    ldh     [hOAMPos],a
    ret
    

section "Player GFX",romx,align[8]

PlayerPlaceholderTiles: incbin  "GFX/Player/placeholder.png.2bpp"
PlayerStarTiles:        incbin  "GFX/star.2bpp.wle"
PlayerPalette:          incbin  "GFX/player.pal"
PlayerStarPalette:      incbin  "GFX/star.pal"

rsreset
macro animframe
def frame_\1 rb
section fragment "Player tiles",romx,align[8]
    incbin "GFX/Player/player_\1.png.2bpp"
section fragment "Player sprite masks",rom0
    db  \2
endm

section fragment "Player sprite masks",rom0
Player_SpriteMasks:

section fragment "Player tiles",romx
PlayerTiles:
    animframe   idle1,%01100110
    animframe   idle2,%01100110
    animframe   idle3,%01100110
    animframe   walk1,%01100110
    animframe   walk2,%01100110
    animframe   walk3,%01100110
    animframe   walk4,%01100110
    animframe   walk5,%01100110
    animframe   walk6,%01100110
    animframe   walk7,%01100110
    animframe   walk8,%01100110
    animframe   jump,%01100110
    animframe   fall0,%01100110
    animframe   fall1,%01100110
    animframe   fall2,%01100110
    animframe   fall3,%01100110
    animframe   fall4,%01100110
    animframe   wand_right,%11101110
    animframe   wand_left,%11101110