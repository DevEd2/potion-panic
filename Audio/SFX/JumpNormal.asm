SFX_JumpNormal: 
    s_header 2, 32
	; --------
    s_pulse 2
    s_env 15,ENV_DIR_DOWN,1
    s_slide $17
    s_pitch nG_3
    s_wait 16
    s_env 0,ENV_DIR_DOWN,0	
	s_end
