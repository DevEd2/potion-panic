; Random facts about the player character!
; - Name: Natalie
; - Age: 24
; - Height: 5'11" (180cm)
; - She started as a stage magician, but later realized she actually has magical powers
; - Her in-game outfit is actually her stage outfit
; - She is a lesbian
; - Her broom is named Boris, he was accidentally brought to life due to a failed magic spell

; !!! KNOWN ISSUES:
; - When tiny, level top boundary is 16 pixels lower than it should be

section "Player RAM",wram0

def PLAYER_ACCEL                = $040
def PLAYER_DECEL                = $020
def PLAYER_WALK_SPEED           = $120
def PLAYER_JUMP_HEIGHT          = $400
def PLAYER_GRAVITY              = $028

def PLAYER_ACCEL_FAT            = $010
def PLAYER_DECEL_FAT            = $008
def PLAYER_WALK_SPEED_FAT       = $0c0
def PLAYER_JUMP_HEIGHT_FAT      = $480
def PLAYER_GRAVITY_FAT          = $030

def PLAYER_ACCEL_TINY           = $020
def PLAYER_DECEL_TINY           = $010
def PLAYER_WALK_SPEED_TINY      = $100
def PLAYER_JUMP_HEIGHT_TINY     = $1e0
def PLAYER_GRAVITY_TINY         = $008

def PLAYER_TERMINAL_VELOCITY    = $400
def PLAYER_COYOTE_TIME          = 15 ; coyote time in frames
def PLAYER_WAND_TIME            = 15 ; wand time in frames

def PLAYER_WIDTH                = 5 ; player hitbox width relative to center
def PLAYER_HEIGHT               = 24 ; player hitbox height relative from bottom
def PLAYER_WIDTH_FAT            = 8
def PLAYER_HEIGHT_FAT           = 24
def PLAYER_WIDTH_TINY           = 1
def PLAYER_HEIGHT_TINY          = 3

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
def BIT_PLAYER_FAT          rb
def BIT_PLAYER_TINY         rb
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
Player_ControlBitFlipMask:              db
Player_LockInPlace:                     db
Player_LockControls:                    db
Player_PauseTempFrame:                  db
Player_HitboxPointTL:                   dw ; x, y
Player_HitboxPointBR:                   dw ; x, y
Player_Health:                          db
Player_RAMEnd:

; Set the player's current animation.
; INPUT:    arg1 = animation name
; DESTROYS: af bc de
macro player_set_animation
    ld      a,[Player_Flags]
    bit     BIT_PLAYER_FAT,a
    jr      nz,.fat\@
    bit     BIT_PLAYER_TINY,a
    jr      nz,.tiny\@
.normal\@
    ld      de,Player_Anim_\1
    jr      .setanim\@
.fat\@
    ld      de,Player_Anim_Fat_\1
    jr      .setanim\@
.tiny\@
    ld      de,Player_Anim_Tiny_\1
.setanim\@
    call    Player_SetAnimation
endm

macro player_set_animation_direct
    ld      de,Player_Anim_\1
    call    Player_SetAnimation
endm

; Get appropriate movement constant for player's current state.
; INPUT:    arg1 = register, arg2 = constant
; DESTROYS: af
macro get_const
    ld      a,[Player_Flags]
    bit     BIT_PLAYER_FAT,a
    jr      nz,.fat\@
    bit     BIT_PLAYER_TINY,a
    jr      nz,.tiny\@
.normal\@
    ld      \1,\2
    jr      .gotconst\@
.fat\@
    ld      \1,\2_FAT
    jr      .gotconst\@
.tiny\@
    ld      \1,\2_TINY
.gotconst\@
endm

section fragment "Player ROM0",rom0

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
    ; farload hl,PlayerHurtLayer2Tiles
    ld      de,$8f80
    call    DecodeWLE
    ; farload hl,PlayerBroomLayer2Tiles
    ld      de,$8fc0
    call    DecodeWLE
    ; farload hl,PlayerStarTiles
    ld      de,$8100
    call    DecodeWLE
    ld      a,e
    ldh     [hObjGFXPos],a
    ld      a,d
    ldh     [hObjGFXPos+1],a
    ld      hl,PlayerPalette
    ld      a,8
    call    LoadPal
    ld      a,9
    call    LoadPal
    ; ld      hl,PlayerStarPalette
    ld      a,$a
    call    LoadPal
    ; ld      hl,BorisPalette
    ; ld      a,10
    ; call    LoadPal

    player_set_animation_direct Idle
    jp      Player_InitHUD

section fragment "Player ROMX",romx

ProcessPlayer:
    xor     a
    ld      [Player_AnimFlag],a
    get_const hl,PLAYER_GRAVITY
    ld      a,l
    ld      [Player_Grav],a
    ld      a,h
    ld      [Player_Grav+1],a

    if BUILD_DEBUG
        ld      hl,Player_Flags
        bit     BIT_PLAYER_NOCLIP,[hl]
        jp      nz,Player_Noclip
    endc
    
    ; wand fire check
    ;ld      hl,Player_Flags
    ;bit     BIT_PLAYER_WAND,[hl]
    ;jr      nz,.nowand
    ld      a,[Player_LockControls]
    and     a
    jr      nz,.nowand
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
    ; check if player should jump
    ld      a,[Player_LockControls]
    and     a
    jr      nz,.nojump
    ldh     a,[hPressedButtons]
    bit     BIT_A,a
    jr      z,.nojump
    ld      a,[Player_CoyoteTimer]
    and     a
    jr      nz,:+   ; skip airborne check if "coyote time" is active
    ld      hl,Player_Flags
    bit     BIT_PLAYER_AIRBORNE,[hl]
    jr      nz,.nojump
:   bit     BIT_PLAYER_FAT,[hl]
    jr      nz,.fat
    bit     BIT_PLAYER_TINY,[hl]
    jr      nz,.tiny
.normal
    ld      e,SFX_JUMP_NORMAL
    jr      :+
.fat
    ld      e,SFX_JUMP_FAT
    jr      :+
.tiny
    ld      e,SFX_JUMP_TINY
:   push    hl
    call    DSFX_PlaySound
    pop     hl
    get_const bc,-PLAYER_JUMP_HEIGHT
    ld      a,c
    ld      [Player_YVel],a
    ld      a,b
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
    ld      a,[Player_LockControls]
    and     a
    jp      nz,.decel
    ldh     a,[hHeldButtons]
    ld      b,a
    and     BTN_LEFT | BTN_RIGHT
    jp      z,.decel
    ld      a,[Player_ControlBitFlipMask]
    xor     b
    bit     BIT_RIGHT,a
    jr      z,.checkleft
    ld      hl,Player_Flags
    res     BIT_PLAYER_DIRECTION,[hl]
    ld      hl,Player_XVel
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    get_const bc,PLAYER_ACCEL
    add     hl,bc
    ld      d,h
    ld      e,l
    get_const bc,PLAYER_WALK_SPEED
    call    Math_Compare16
    jr      nc,.nocapright
    ld      h,b
    ld      l,c
.nocapright
    ld      a,l
    ld      [Player_XVel],a
    ld      a,h
    ld      [Player_XVel+1],a
    jp      .nodecel
    
.checkleft
    ldh     a,[hHeldButtons]
    ld      a,[Player_ControlBitFlipMask]
    xor     b
    bit     BIT_LEFT,a
    jr      z,.decel
    ld      hl,Player_Flags
    set     BIT_PLAYER_DIRECTION,[hl]
    ld      hl,Player_XVel
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    get_const bc,-PLAYER_ACCEL
    add     hl,bc
    ld      d,h
    ld      e,l
    get_const bc,-PLAYER_WALK_SPEED
    call    Math_Compare16
    jr      c,.nocapleft
    ld      h,b
    ld      l,c
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
    get_const bc,-PLAYER_DECEL
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
    get_const  bc,PLAYER_DECEL
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
    ;ld      a,[Player_Flags]
    ;bit     BIT_PLAYER_WAND,a
    ;jr      nz,:+
    player_set_animation Fall
    ; terminal velocity
    push    de
    ld      d,h
    ld      e,l
    ld      bc,PLAYER_TERMINAL_VELOCITY
    call    Math_Compare16
    pop     de
    jr      nc,:+
    ld      a,c
    ld      [Player_YVel],a
    ld      a,b
    ld      [Player_YVel+1],a
    ;player_set_animation FallFast
:   ; velocity to position
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
    call    Player_GetColMapIndex
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
    jr      nz,.animateplayer ; skip ahead if player is already airborne
    ; init time
    ld      a,PLAYER_COYOTE_TIME
    ld      [Player_CoyoteTimer],a
:   ;ld      hl,Player_Flags
    set     BIT_PLAYER_AIRBORNE,[hl]    ; set airborne flag
    ; animate player
.animateplayer
    ; actually, set collision points first
    get_const   b,PLAYER_WIDTH
    ld      a,[Player_XPos]
    sub     b
    ld      [Player_HitboxPointTL],a
    ;ld      [Player_HitboxPointBL],a
    add     b
    add     b
    ;ld      [Player_HitboxPointTR],a
    ld      [Player_HitboxPointBR],a
    ld      a,[Player_YPos]
    ;ld      [Player_HitboxPointBL+1],a
    ld      [Player_HitboxPointBR+1],a
    get_const b,PLAYER_HEIGHT
    ld      a,[Player_YPos]
    sub     b
    ld      [Player_HitboxPointTL+1],a
    ;ld      [Player_HitboxPointTR+1],a
    ; *NOW* animate the player
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
    xor     a
    ld      [Player_LockInPlace],a
    ld      [FreezeObjects],a
    jr      .getbyte

section fragment "Player ROM0",rom0

Player_GetColMapIndex:
    push    de
    pushbank
    ld      a,[Level_ColMapBank]
    bankswitch_to_a
    ld      e,[hl]
    popbank
    ld      a,e
    pop     de
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
    push    af
    get_const b,-16+PLAYER_HEIGHT
    pop     af
    add     b
    ld      [Player_YPos],a
:   xor     a
    ld      [Player_YVel],a
    ld      [Player_YVel+1],a
    ret
  
Player_CollisionResponseHorizontal:
    pushbank
    ld      a,[Level_ColMapBank]
    bankswitch_to_a
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
    popbank
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
    push    af
    get_const b,PLAYER_WIDTH
    pop     af
    add     b
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
    push    af
    get_const b,15-PLAYER_WIDTH
    pop     af
    add     b
    ; jr      nc,:+
    ; dec     b
:   ld      [Player_XPos],a
    ; ld      a,b
    ; ld      [Player_XPos+2],a
.donelr
    ret

section fragment "Player ROMX",romx

Player_CheckCollisionVertical:
    ld      a,[Player_YVel+1]
    bit     7,a ; is player moving up?
    ld      a,[Player_YPos]
    jr      z,.goingdown
    ; fall through
.goingup
    ld      hl,Player_Flags
    bit     BIT_PLAYER_TINY,[hl]
    jr      z,:+    
    push    af
    get_const b,16-PLAYER_HEIGHT
    pop     af
    add     b
    jr      c,.oob
    jr      :+
.goingdown
    add     16
    ; fall through
:   and     $f0
    swap    a
    ld      c,a
    ; get left collision point
    ; ld      a,[Player_XPos+2]
    ; ld      e,a
    ld      a,[Player_XPos]
    push    af
    get_const b,-2+PLAYER_WIDTH
    pop     af
    sub     b
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
    push    af
    get_const b,-2+PLAYER_WIDTH
    pop     af
    add     b
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
    xor     a
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
    push    af
    get_const b,PLAYER_WIDTH
    pop     af
    sub     b
    ; jr      nc,:+
    ; dec     e
    jr      :+
.ur
    ld      a,[Player_XPos]
    push    af
    get_const b,PLAYER_WIDTH
    pop     af
    add     b
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
    jr      c,.oob
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
    push    af
    get_const b,PLAYER_WIDTH
    pop     af
    sub     b
    ; jr      nc,:+
    ; dec     e
    jr      :+
.br
    ld      a,[Player_XPos]
    push    af
    get_const b,PLAYER_WIDTH
    pop     af
    add     b
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
.oob
    xor     a
    ld      [Player_HorizontalCollisionSensorTop],a
    ld      [Player_HorizontalCollisionSensorBottom],a
    ld      hl,Player_YVel
    ld      [hl],$80
    inc     l
    ld      [hl+],a
    ld      hl,Player_YPos
    ld      [hl],8
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

section fragment "Player ROM0",rom0
 
DrawPlayer:
    ; copy GFX
    ld      a,1
    ldh     [rVBK],a
    farload bc,PlayerTiles
    ld      a,[Player_AnimFrame]
    ld      e,a
    ld      l,a
    ld      a,[sys_FadeState]
    and     a
    jr      nz,:+
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
:   pushbank
    farload hl,Player_SpriteMasks
    ld      d,0
    add     hl,de
    ld      c,[hl]
    popbank
    ld      hl,Player_Flags
    bit     BIT_PLAYER_DIRECTION,[hl]
    ld      hl,Player_OAM
    jr      z,:+
    ld      hl,Player_OAMFlip
:   ld      de,OAMBuffer
    ld      b,(Player_OAM.end-Player_OAM)/4
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

DrawPlayerLayers:
    ld      hl,.frames
.loop
    ld      a,[hl+]
    cp      -1
    ret     z
    ld      b,a
    ld      a,[Player_AnimFrame]
    cp      b
    jr      z,:+
    ld      a,l
    add     3
    ld      l,a
    jr      nc,.loop
    inc     h
    jr      .loop
:   ld      a,[hl+]
    ld      e,a
    add     a   ; x2
    add     a   ; x4
    ld      c,a
    ld      b,0
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    ld      a,[Player_Flags]
    bit     BIT_PLAYER_DIRECTION,a
    jr      z,:+
    add     hl,bc
:   ld      b,e
    ldh     a,[hOAMPos]
    ld      e,a
    ld      d,high(OAMBuffer)
    
:   ; y position
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
    
    ld      a,e
    ldh     [hOAMPos],a
    dec     b
    jr      nz,:-
    ret
    
.frames
    dbbw frame_hurt_layer1,     2,  Player_OAM_Hurt_Layer2
    dbbw frame_broom_layer1,    2,  Player_OAM_Broom_Layer2
    db  -1

Player_OAM_Hurt_Layer2:
    ; normal
    db -16+16, 8 - 8,$f8, $9
    db -16+16, 8 + 0,$fa, $9
    ; flipped
    db -16+16, 8 + 0,$f8, $9 | OAMF_XFLIP
    db -16+16, 8 - 8,$fa, $9 | OAMF_XFLIP

Player_OAM_Broom_Layer2:
    ; normal
    db   0+16, 8 -16,$fc, $a
    db   0+16, 8 - 8,$fe, $a
    ; flipped
    db   0+16, 8 + 8,$fc, $a | OAMF_XFLIP
    db   0+16, 8 + 0,$fe, $a | OAMF_XFLIP
    
    
Player_OAM:
    db -16+16, 8 -16, 0, 8
    db -16+16, 8 - 8, 2, 8
    db -16+16, 8 + 0, 4, 8
    db -16+16, 8 + 8, 6, 8
    db   0+16, 8 -16, 8, 8
    db   0+16, 8 - 8,10, 8
    db   0+16, 8 + 0,12, 8
    db   0+16, 8 + 8,14, 8
.end
Player_OAMFlip:
    db -16+16, 8 + 8, 0, 8 | OAMF_XFLIP
    db -16+16, 8 + 0, 2, 8 | OAMF_XFLIP
    db -16+16, 8 - 8, 4, 8 | OAMF_XFLIP
    db -16+16, 8 -16, 6, 8 | OAMF_XFLIP
    db   0+16, 8 + 8, 8, 8 | OAMF_XFLIP
    db   0+16, 8 + 0,10, 8 | OAMF_XFLIP
    db   0+16, 8 - 8,12, 8 | OAMF_XFLIP
    db   0+16, 8 -16,14, 8 | OAMF_XFLIP
.end

Player_OAM_Layer2:
    db -16+16, 8 -16, 0, 1
    db -16+16, 8 - 8, 2, 1
    db -16+16, 8 + 0, 4, 1
    db -16+16, 8 + 8, 6, 1
    db   0+16, 8 -16, 8, 1
    db   0+16, 8 - 8,10, 1
    db   0+16, 8 + 0,12, 1
    db   0+16, 8 + 8,14, 1
.end
Player_OAMFlip_Layer2:
    db -16+16, 8 + 8, 0, 1 | OAMF_XFLIP
    db -16+16, 8 + 0, 2, 1 | OAMF_XFLIP
    db -16+16, 8 - 8, 4, 1 | OAMF_XFLIP
    db -16+16, 8 -16, 6, 1 | OAMF_XFLIP
    db   0+16, 8 + 8, 8, 1 | OAMF_XFLIP
    db   0+16, 8 + 0,10, 1 | OAMF_XFLIP
    db   0+16, 8 - 8,12, 1 | OAMF_XFLIP
    db   0+16, 8 -16,14, 1 | OAMF_XFLIP
.end

Player_OAM_Layer3:
    db -16+16, 8 -16, 0, 2
    db -16+16, 8 - 8, 2, 2
    db -16+16, 8 + 0, 4, 2
    db -16+16, 8 + 8, 6, 2
    db   0+16, 8 -16, 8, 2
    db   0+16, 8 - 8,10, 2
    db   0+16, 8 + 0,12, 2
    db   0+16, 8 + 8,14, 2
.end
Player_OAMFlip_Layer3:
    db -16+16, 8 + 8, 0, 2 | OAMF_XFLIP
    db -16+16, 8 + 0, 2, 2 | OAMF_XFLIP
    db -16+16, 8 - 8, 4, 2 | OAMF_XFLIP
    db -16+16, 8 -16, 6, 2 | OAMF_XFLIP
    db   0+16, 8 + 8, 8, 2 | OAMF_XFLIP
    db   0+16, 8 + 0,10, 2 | OAMF_XFLIP
    db   0+16, 8 - 8,12, 2 | OAMF_XFLIP
    db   0+16, 8 -16,14, 2 | OAMF_XFLIP
.end

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

Player_Anim_Fatten:
    db  3,frame_shrink_fatten_0
    db  1,frame_fatten_1
    db  1,frame_shrink_fatten_0
    db  3,frame_fatten_1
    db  1,frame_fatten_2
    db  1,frame_fatten_1
    db  3,frame_fatten_2
    db  1,frame_fatten_3
    db  1,frame_fatten_2
    db  3,frame_fatten_3
    db  1,frame_fatten_4
    db  1,frame_fatten_3
    db  3,frame_fatten_4
    db  1,frame_fatten_5
    db  1,frame_fatten_4
    db  6,frame_fatten_5
    db  8,frame_fatten_6
    db  8,frame_fatten_7
    db  $fe,1
    ; fall through
Player_Anim_Fat_Idle:
    db  16,frame_fat_idle1
    db  16,frame_fat_idle2
    db  16,frame_fat_idle1
    db  8,frame_fat_idle2
    db  8,frame_fat_idle3
    db  $ff
    dw  Player_Anim_Fat_Idle

Player_Anim_Fat_Walk:
    db  6,frame_fat_walk1
    db  6,frame_fat_walk2
    db  6,frame_fat_walk3
    db  6,frame_fat_walk4
    db  6,frame_fat_walk5
    db  6,frame_fat_walk6
    db  6,frame_fat_walk7
    db  6,frame_fat_walk8
    db  $ff
    dw  Player_Anim_Fat_Walk

Player_Anim_Fat_Jump:
    db  1,frame_fat_jump
    db  $ff
    dw  Player_Anim_Fat_Jump

Player_Anim_Fat_Fall:
    db  4,frame_fat_fall0
:   db  4,frame_fat_fall1
    db  4,frame_fat_fall2
    db  $ff
    dw  :-
    
Player_Anim_Fat_FallFast:
    db  3,frame_fat_fall3
    db  3,frame_fat_fall4
    db  $ff
    dw  Player_Anim_Fat_FallFast

Player_Anim_Fat_WandLeft:
    db  24,frame_fat_wand_left
    db  $ff
    dw  Player_Anim_Fat_WandLeft
    
Player_Anim_Fat_WandRight:
    db  24,frame_fat_wand_right
    db  $ff
    dw  Player_Anim_Fat_WandRight

Player_Anim_Shrink:
    db  3,frame_shrink_fatten_0
    db  1,frame_shrink_1
    db  1,frame_shrink_fatten_0
    db  3,frame_shrink_1
    db  1,frame_shrink_2
    db  1,frame_shrink_1
    db  3,frame_shrink_2
    db  1,frame_shrink_3
    db  1,frame_shrink_2
    db  3,frame_shrink_3
    db  1,frame_shrink_4
    db  1,frame_shrink_3
    db  3,frame_shrink_4
    db  1,frame_tiny_1
    db  1,frame_shrink_4
    db  $fe,1
    ; fall through
Player_Anim_Tiny_Jump:
Player_Anim_Tiny_Fall:
Player_Anim_Tiny_FallFast:
Player_Anim_Tiny_Idle:
    db  1,frame_tiny_1
    db  $ff
    dw  Player_Anim_Tiny_Idle

Player_Anim_Tiny_Walk:
    db  10,frame_tiny_1
    db  10,frame_tiny_2
    db  $ff
    dw  Player_Anim_Tiny_Walk

Player_Anim_Tiny_WandLeft:
Player_Anim_Tiny_WandRight:
    db  1,frame_tiny_wand
    db  $ff
    dw  Player_Anim_Tiny_WandRight

Player_Anim_Broom:
    db  1,frame_broom_layer1
    db  $ff
    dw  Player_Anim_Broom

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
    bit     BIT_PLAYER_TINY,a
    jr      nz,.tinyX
    bit     BIT_PLAYER_DIRECTION,a
    ld      a,[Player_XPos]
    jr      z,.right
.left
    sub     14
    jr      :+
.right
    add     14
    jr      :+
.tinyX
    ld      a,[Player_XPos]
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
    ld      a,[Player_Flags]
    bit     BIT_PLAYER_TINY,a
    ld      a,[Player_YPos]
    jr      nz,.tinyY
.normal
    inc     a
    jr      :+
.tinyY
    add     12
:   ld      [hl+],a
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

section fragment "Player ROM0",rom0

Player_InitHUD:
    xor     a
    ldh     [rVBK],a
    ld      de,_SCRN1
    ld      hl,HUD_TileMap
    ld      b,HUD_TileMap.row2-HUD_TileMap.row1
    call    MemCopySmall
    ld      de,$9c20
    ld      b,HUD_TileMap.row2-HUD_TileMap.row1
    call    MemCopySmall
    
    ld      a,1
    ldh     [rVBK],a
    ld      de,_SCRN1
    ld      hl,HUD_AttrMap
    ld      b,HUD_AttrMap.row2-HUD_AttrMap.row1
    call    MemCopySmall
    ld      de,$9c20
    ld      b,HUD_AttrMap.row2-HUD_AttrMap.row1
    call    MemCopySmall
    
    ld      a,low(IntS_HUD)
    ldh     [hSTATPointer],a
    ld      a,high(IntS_HUD)
    ldh     [hSTATPointer+1],a
    ld      a,144-16
    ldh     [rLYC],a
    ld      a,144-16
    ldh     [rWY],a
    ld      a,7
    ldh     [rWX],a
    ld      a,STATF_LYC
    ldh     [rSTAT],a
    ret

IntS_HUD:
    ld      a,LCDCF_ON | LCDCF_BGON | LCDCF_OBJOFF | LCDCF_BLK21 | LCDCF_OBJ16 | LCDCF_WINON | LCDCF_WIN9C00
    ldh     [rLCDC],a
    ret
    
HUD_NumberTiles:
    db  $5e,$70 ; 0
    db  $5f,$71 ; 1
    db  $60,$72 ; 2
    db  $61,$73 ; 3
    db  $62,$74 ; 4
    db  $63,$75 ; 5
    db  $64,$76 ; 6
    db  $65,$77 ; 7
    db  $66,$78 ; 8
    db  $67,$79 ; 9

HUD_TileMap:
.row1   db  $5a,$5b,$5c,$5c,$6a,$6c,$6c,$6c,$6a,$66,$67,$68,$69,$5c,$5c,$5c,$5c,$5c,$5c,$6b
.row2   db  $6d,$6e,$6f,$6f,$7d,$7f,$7f,$7f,$7d,$79,$7a,$7b,$7c,$6f,$6f,$6f,$6f,$6f,$6f,$7d

HUD_AttrMap:
.row1   db  $0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e
.row2   db  $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f

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
    ;and     $f0
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
    ;and     $f0
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

section fragment "Player ROM0",rom0

Player_CamShake_FatLand:
    db        0, 0, 0,-2, 0,-3, 0,-3, 0,-2, 0, 0, 0, 2, 0, 3, 0, 2, 0, 1
    db        0, 0, 0,-1, 0,-2, 0,-2, 0,-1, 0, 0, 0, 1, 0, 2, 0, 2, 0, 1
    db        0, 0, 0,-1, 0,-2, 0,-2, 0,-1, 0, 0, 0, 1, 0, 2, 0, 2, 0, 1
    db        0, 0, 0,-1, 0,-1, 0,-1, 0,-1, 0, 0, 0, 1, 0, 1, 0, 1, 0, 1
    db        0, 0, 0,-1, 0,-1, 0,-1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0
    db        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db      $80
    
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
    ld      a,2 | %00001000
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

section fragment "Player ROM0",rom0

Player_SetAnimation:
    ld      a,[Player_AnimCurrent]
    ld      c,a
    ld      a,[Player_AnimCurrent+1]
    ld      b,a
    call    Math_Compare16
    ret     z
    ld      a,e
    ld      [Player_AnimPointer],a
    ld      [Player_AnimCurrent],a
    ld      a,d
    ld      [Player_AnimPointer+1],a
    ld      [Player_AnimCurrent+1],a
    ld      a,1
    ld      [Player_AnimTimer],a
    ret

    
;Player_PotionEffectStrings:
;    ;    ####################
;    db  "    UH-OH, BIG!     "  ; fat
;    db  " GOT A MICROSCOPE?  "  ; shrink
;    db  "   DOUBLE DAMAGE!   "  ; double damage
;    db  "DOUBLE JUMP ENABLED!"  ; double jump
;    db  "  SCORE MULTIPLIER! "  ; multiplier
;    db  "  BLACK MAGIC SHOT  "  ; quad damage
;    db  "   WHAT ENEMIES?    "  ; screen nuke
;    db  "     JACKPOT!!      "  ; jackpot
;    db  "  MEGA JACKPOT!!!!  "  ; mega jackpot
;    db  "      SO RETRO      "  ; DMG mode
;    db  " I CAN DRAW I SWEAR "  ; programmer art
;    db  "    iUMOP 3PISdn    "  ; upside down
;    db  "OOPS THAT WAS POISON"  ; poison
;    db  "  LADY LUCK SMILES  "  ; good luck
;    db  "  LADY LUCK FROWNS  "  ; bad luck
;    db  "      SCORE TAX     "  ; score tax
;    db  "   INVERTED COLORS  "  ; inverted colors
;    db  "TOTALLY TRIPPING OUT"  ; trippy mode
;    db  " SLORTNOC SDRAWKCAB "  ; inverted controls (lol slortnoc)
;    db  "   SHE FLIES NOW    "  ; floating
;    db  " FAMILIAR SUMMONED  "  ; summon

include "Engine/PotionEffects.asm"

section "Player GFX",romx,align[8]

PlayerPlaceholderTiles: incbin  "GFX/Player/placeholder.png.2bpp"
PlayerHurtLayer2Tiles:  incbin  "GFX/Player/player_hurt_layer2.png.2bpp.wle"
PlayerBroomLayer2Tiles: incbin  "GFX/Player/player_broom_layer2.png.2bpp.wle"
PlayerStarTiles:        incbin  "GFX/star.2bpp.wle"
PlayerPalette:          incbin  "GFX/player.pal"
                        incbin  "GFX/player2.pal"
PlayerStarPalette:      incbin  "GFX/star.pal"

rsreset
macro animframe
def frame_\1 rb
section fragment "Player tiles",romx,align[8]
    incbin "GFX/Player/player_\1.png.2bpp"
section fragment "Player sprite masks",romx
    db  \2
endm

section fragment "Player sprite masks",romx
Player_SpriteMasks:

section fragment "Player sprite palette flags",rom0
Player_SpritePalFlags:

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
    
    animframe   fat_idle1,%11101110
    animframe   fat_idle2,%11101110
    animframe   fat_idle3,%11101110
    animframe   fat_walk1,%11101110
    animframe   fat_walk2,%11101110
    animframe   fat_walk3,%11101110
    animframe   fat_walk4,%11101110
    animframe   fat_walk5,%11101110
    animframe   fat_walk6,%11101110
    animframe   fat_walk7,%11101110
    animframe   fat_walk8,%11101110
    animframe   fat_jump,%11101110
    animframe   fat_fall0,%11101110
    animframe   fat_fall1,%11101110
    animframe   fat_fall2,%11101110
    animframe   fat_fall3,%11101110
    animframe   fat_fall4,%11101110
    animframe   fat_wand_right,%11101110
    animframe   fat_wand_left,%11101110
    
    animframe   tiny_1,%01100000
    animframe   tiny_2,%01100000
    animframe   tiny_jump,%01100000
    animframe   tiny_wand,%01100000
    
    animframe   shrink_fatten_0,%01100110
    animframe   fatten_1,%01100110
    animframe   fatten_2,%01100110
    animframe   fatten_3,%11100110
    animframe   fatten_4,%11100110
    animframe   fatten_5,%11100110
    animframe   fatten_6,%11100110
    animframe   fatten_7,%11100110
    
    animframe   shrink_1,%01100110
    animframe   shrink_2,%01100110
    animframe   shrink_3,%01100000
    animframe   shrink_4,%01100000
    
    animframe   broom_layer1,%11110110
    
    animframe   hurt_layer1,%11110110
    