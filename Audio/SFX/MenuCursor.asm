SFX_MenuCursor: 
    s_header 2, 32
	; --------
    s_pulse 0
	s_env 15,ENV_DIR_DOWN,1
	s_pitch nE_6
	s_wait 2

	s_restart
	s_pulse 1
	s_pitch nF#6
	s_wait 2

	s_restart
	s_pulse 2
	s_pitch nB_6
	s_wait 2

	s_pulse 1
	s_env 4,ENV_DIR_DOWN,1
	s_pitch nE_6
	s_wait 2

	s_restart
	s_pulse 0
	s_pitch nF#6
	s_wait 2

	s_restart
	s_pulse 1
	s_pitch nB_6
	s_wait 2
	
	s_pulse 2
	s_env 1,ENV_DIR_DOWN,1
	s_pitch nE_6
	s_wait 2

	s_restart
	s_pulse 1
	s_pitch nF#6
	s_wait 2

	s_restart
	s_pulse 0
	s_pitch nB_6
	s_wait 2
	
	s_end
