SFX_PauseCH1: 
    s_header 1, 0
	; --------
    s_wait 8
    s_env 6,ENV_DIR_DOWN,2
    s_pulse 2
    s_pitch nF_5
    s_wait 5
    s_restart
    s_pitch nA_5
    s_wait 5
    s_restart
    s_pitch nC_6
    s_wait 5
    s_restart
    s_pitch nF_6
    s_wait 16
    s_end