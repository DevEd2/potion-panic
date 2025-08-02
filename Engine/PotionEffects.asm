section "Potion effect handlers",romx

PotionEffect_Fat_Start:
    ld      hl,Player_Flags
    set     BIT_PLAYER_FAT,[hl]
    ret

PotionEffect_Fat_End:
    ld      hl,Player_Flags
    res     BIT_PLAYER_FAT,[hl]
    ret

PotionEffect_Tiny_Start:
    ld      hl,Player_Flags
    set     BIT_PLAYER_TINY,[hl]
    ret

PotionEffect_Tiny_End:
    ld      hl,Player_Flags
    res     BIT_PLAYER_TINY,[hl]
    ret

PotionEffect_ReverseControls_Start:
    ld      hl,Player_ControlBitFlipMask
    ld      [hl],BTN_LEFT | BTN_RIGHT
    ret

PotionEffect_ReverseControls_End:
    ld      hl,Player_ControlBitFlipMask
    ld      [hl],0
    ret