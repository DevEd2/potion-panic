SFX_MenuSelect_CH1:
    s_header 1,16
    s_wait 2
    s_jump SFX_MenuSelect
    purge CHANNEL ; HACK
SFX_MenuSelect_CH2:
    s_header 2,16
SFX_MenuSelect:
    s_env 15, ENV_DIR_DOWN, 0
    s_pulse 2
    
    s_pitch nC#6
    s_wait 2
    s_pitch nG#5
    s_wait 2
    s_pitch nF_5
    s_wait 2
    s_pitch nC#7
    s_wait 2
    s_pitch nG#6
    s_wait 2
    s_pitch nF_6
    s_wait 2
    s_pitch nC#6
    s_wait 2
    s_env 8, ENV_DIR_DOWN, 0
    s_pitch nF_5
    s_wait 2
    s_pitch nC#7
    s_wait 2
    s_pitch nG#6
    s_wait 2
    s_pitch nF_6
    s_wait 2
    s_pitch nC#6
    s_wait 2
    s_env 4, ENV_DIR_DOWN, 0
    s_pitch nF_5
    s_wait 2
    s_pitch nC#7
    s_wait 2
    s_pitch nG#6
    s_wait 2
    s_pitch nF_6
    s_wait 2
    s_pitch nC#6
    s_wait 2
    s_env 2, ENV_DIR_DOWN, 0
    s_pitch nF_5
    s_wait 2
    s_pitch nC#7
    s_wait 2
    s_pitch nG#6
    s_wait 2
    s_pitch nF_6
    s_wait 2
    s_pitch nC#6
    s_wait 2
    s_env 1, ENV_DIR_DOWN, 0
    s_pitch nF_5
    s_wait 2
    s_pitch nC#7
    s_wait 2
    s_pitch nG#6
    s_wait 2
    s_pitch nF_6
    s_wait 2
    s_pitch nC#6
    s_wait 2
    s_env 0, ENV_DIR_DOWN, 0    
    s_end