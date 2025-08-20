SFX_BigBump_CH4:
    s_header 4, 32
    s_pan PAN_RIGHT
    s_env 15,ENV_DIR_DOWN,1
    s_noise $4e
    s_wait 3
    
    s_pan PAN_LEFT
    s_env 12,ENV_DIR_DOWN,1
    s_noise $4f
    s_wait 3
    
    s_pan PAN_CENTER
    s_env 15,ENV_DIR_DOWN,1
    s_noise $4e
    s_wait 6
    
    s_env 10,ENV_DIR_DOWN,1
    s_noise $5d
    s_wait 9
    
    s_env 5,ENV_DIR_DOWN,2
    s_pan PAN_RIGHT
    s_noise $5d
    s_wait 9
    
    s_env 2,ENV_DIR_DOWN,4
    s_pan PAN_LEFT
    s_noise $5d
    s_wait 9
    
    s_env 1,ENV_DIR_DOWN,7
    s_pan PAN_RIGHT
    s_noise $5d
    s_wait 9
    
    s_end
