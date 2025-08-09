SFX_JumpFat: 
    s_header 2, 32
	; --------
    s_pulse 2
    s_env 15,ENV_DIR_DOWN,0
    s_slide -$20
    s_pitch nD#3
    s_wait 4
    
    s_slide $10
    s_pitch nC_2
    s_wait 8
    
    s_slide $40
    s_env 15,ENV_DIR_DOWN,2
    
    s_wait 16
    s_env 0,ENV_DIR_DOWN,0
    s_end