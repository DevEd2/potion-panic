macro effect_def
    def ID_\1 rb
    dw  PotionEffect_\1_Start
    dw  PotionEffect_\1_End
endm

section "Potion effect RAM",wram0
Potion_ActiveEffectList:    ds  8*3 ; effect ID, timer
.end

section "Potion effect routines",rom0

Potion_InitEffects:
    ld      hl,Potion_ActiveEffectList
    ld      b,Potion_ActiveEffectList.end-Potion_ActiveEffectList
    xor     a
    jp      MemFillSmall

Potion_ClearAllEffects:
    ld      de,Potion_ActiveEffectList
    ld      b,Potion_ActiveEffectList.end-Potion_ActiveEffectList
:   ld      a,[de]
    push    de
    ld      hl,Potion_EffectPointers
    ld      e,a
    ld      d,0
    add     hl,de
    add     hl,de
    add     hl,de
    add     hl,de
    inc     hl
    inc     hl
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    rst     CallHL
    pop     de
    xor     a
    ld      [de],a
    inc     de
    ld      [de],a
    inc     de
    dec     b
    jr      nz,:-
    ret
    

Potion_GiveEffect:
:   call    Math_Random
    and     bitwidth(NUM_POTION_EFFECTS)
    cp      NUM_POTION_EFFECTS
    jr      nc,:-
    
    push    af
    push    af
    ld      a,[BigText_ObjectID]
    ld      l,a
    ld      h,high(ObjList)
    ld      [hl],0
    ld      b,OBJID_BigText
    lb      de,0,0
    call    CreateObject
    pop     af
    add     BIGTEXT_POTIONS
    inc     h
    ld      [hl],a
    pop     af
    
    ld      c,a
;    ld      l,a
;    ld      h,0
;    add     hl,hl   ; x2
;    add     hl,hl   ; x4
;    ld      de,Potion_EffectPointers
;    add     hl,de
;    ld      a,[hl+]
;    ld      h,[hl]
;    ld      l,a
    
;    ld      hl,Potion_ActiveEffectList
;    ld      b,(Potion_ActiveEffectList.end-Potion_ActiveEffectList)/2
;:   ld      a,[hl+]
;    inc     hl
;    inc     hl
;    and     a
;    jr      z,:+
;    dec     b
;    jr      nz,:-
;    ret
;:   dec     hl
;    dec     hl
;    dec     hl
;    ld      [hl],c
;    inc     hl
;    ld      [hl],low(30 * 60)
;    inc     hl
;    ld      [hl],high(30 * 60)
    
    pushbank
    ld      a,bank(Potion_EffectHandlers)
    bankswitch_to_a
    ld      l,c
    ld      h,0
    add     hl,hl
    add     hl,hl
    ld      de,Potion_EffectPointers
    add     hl,de
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    rst     CallHL
    popbank
    ret

Potion_EffectPointers:
    rsreset
    effect_def  Nothing
    effect_def  Fat
    effect_def  Tiny
    effect_def  ReverseControls
    effect_def  1Up
    effect_def  Heal
.end

def NUM_POTION_EFFECTS equ (Potion_EffectPointers.end-Potion_EffectPointers)/4

section "Potion effect handlers",romx

Potion_EffectHandlers:

PotionEffect_Nothing_Start:
PotionEffect_Nothing_End:
PotionEffect_1Up_End:
PotionEffect_Heal_End:
    ret

PotionEffect_Fat_Start:
    ld      hl,Player_Flags
    res     BIT_PLAYER_TINY,[hl]
    set     BIT_PLAYER_FAT,[hl]
    ret

PotionEffect_Fat_End:
    ld      hl,Player_Flags
    res     BIT_PLAYER_FAT,[hl]
    ret

PotionEffect_Tiny_Start:
    ld      hl,Player_Flags
    res     BIT_PLAYER_FAT,[hl]
    set     BIT_PLAYER_TINY,[hl]
    ret

PotionEffect_Tiny_End:
    ld      hl,Player_Flags
    res     BIT_PLAYER_TINY,[hl]
    ret

PotionEffect_ReverseControls_Start:
PotionEffect_ReverseControls_End:
    ld      a,[Player_ControlBitFlipMask]
    xor     BTN_LEFT | BTN_RIGHT
    ld      [Player_ControlBitFlipMask],a
    ret

PotionEffect_1Up_Start:
    ld      hl,Player_Lives
    inc     [hl]
    ; TODO: Update HUD
    ret

PotionEffect_Heal_Start:
    ld      hl,Player_Health
    ld      [hl],3
    ; TODO: Update HUD
    ret
