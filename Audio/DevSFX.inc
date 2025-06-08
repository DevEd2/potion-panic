def SFX_PRIO_MAX = 0
def SFX_PRIO_MIN = 63

; SFX sequence commands

macro s_header
    IF def(CHANNEL)
        FAIL "Please only define one SFX per file. Do not use `s_header` manually, it is automatically generated from the filename!"
    ENDC

    def CHANNEL equ (\1)
    assert (CHANNEL > 0) && (CHANNEL < 5), "SFX channel must be between 1 and 4!"
    assert (\2) <= 63, "SFX priority must be between 0 and 63!"
    db (CHANNEL - 1) << 6 | (\2)
endm

; Marks the end of a sound sequence.
macro s_end
    db  0
endm

; usage: s_pitch freq
; @param freq: Frequency
macro s_pitch
    assert CHANNEL != 4, "s_pitch cannot be used on channel 4, please use s_noise instead"
    db  1
    dw  \1
endm

; usage: s_noise freq
; @param freq: Frequency
macro s_noise
    assert CHANNEL == 4, "s_noise can only be used on channel 4, please use s_pitch instead"
    db  1
    db  \1
endm

; Set the volume envelope.
; Only valid on CH1, CH2, and CH4.
; @usage: s_env vol,dir,length
; @param vol, Initial volume
; @param dir, Direction
; @param length, Length
macro s_env
    assert CHANNEL != 3, "s_env cannot be used on channel 3, please use s_wvol instead"
    assert ((\1 >= 0) & (\1 < 16)), "Volume must be between 0 and 15!"
    assert ((\2 == 0) | (\2 == 1)), "Invalid direction!"
    assert ((\3 >= 0) & (\3 < 8)), "Length must be between 0 and 7!"
    db  2
    db  (\1 << 4) | (\2 << 3) | \3
endm
def ENV_DIR_UP = 1
def ENV_DIR_DOWN = 0

; Same as s_env but the direction and length are omitted.
macro s_vol
    assert CHANNEL != 3, "s_vol cannot be used on channel 3, please use s_wvol instead"
    assert ((\1 >= 0) & (\1 < 16)), "Volume must be between 0 and 15!"
    db  2
    db  (\1 << 4)
endm

; Set the volume of the wave channel.
; Only valid on CH3.
; @usage: s_vol vol
; @param vol
macro s_wvol
    assert CHANNEL == 3, "s_wvol can only be used on channel 3, please use s_env or s_vol instead"
    db  2
    db  \1
endm

def WAVE_VOL_0      = $00
def WAVE_VOL_25     = $60
def WAVE_VOL_50     = $40
def WAVE_VOL_100    = $20

; Set the pulse width.
; Overrides any active pulse modulation effects.
; Only valid on CH1 and CH2.
; @usage: s_pulse p
; @param p, pulse width
macro s_pulse
    assert CHANNEL != 3 & CHANNEL != 4, "s_pulse can only be used on channel 1 and channel 2"
    assert ((\1 >= 0) & (\1 < 4)), "Invalid pulse width!"
    db  3
    db  \1 << 6
endm

def PULSE_125 = 0   ; -_______  ; 12.5%
def PULSE_25 = 1    ; --______  ; 25%
def PULSE_50 = 2    ; ----____  ; 50% - square wave
def PULSE_75 = 3    ; __------  ; 75% - same as 25% but inverted

; Sets the waveform for CH3.
; Only valid on CH3.
; usage: s_wave ptr
; @param ptr, Wave pointer
; WARNING: If pointer is in ROMX, it MUST be in the same bank as the sound effect!
; WARNING: This overrides CH3's volume level!
macro s_wave
    assert CHANNEL == 3, "s_wave can only be used on channel 3"
    assert BANK(\1) == BANK(@)
    db  3
    dw  \1
endm

macro s_wait
    db  4
    db  \1
endm

macro s_pan
    db  5
    db  \1
endm
def PAN_LEFT    = %00010000
def PAN_RIGHT   = %00000001
def PAN_CENTER  = %00010001
def PAN_NONE    = %00000000 ; not recommended - use s_vol or s_wvol to set volume to zero instead

macro s_set_prio
    db  6
    db  \1
endm

; usage: s_slide speed
; @param speed = speed of slide
macro s_slide
    assert CHANNEL != 4, "s_slide cannot be used on channel 4"
    db  7
    dw  \1
endm

; Force a retrigger without needing to reload the envelope. Does not apply to CH3.
; usage: s_restart
; No parameters.
macro s_restart
    assert CHANNEL != 3, "s_restart cannot be used on channel 3"
    db  8
endm

; Set range for random pitch.
; usage: s_pitchrange
macro s_pitchrange
    assert CHANNEL != 4, "s_pitchrange cannot be used on channel 4"
    db  9
    db  \1
endm

macro s_resetpitch
    assert CHANNEL != 4, "s_resetpitch cannot be used on channel 4"
    db  10
endm

; really wish i didn't have to do this...
def nC_2 equ $2c
def nC#2 equ $9d
def nD_2 equ $107
def nD#2 equ $16b
def nE_2 equ $1c9
def nF_2 equ $223
def nF#2 equ $277
def nG_2 equ $2c7
def nG#2 equ $312
def nA_2 equ $358
def nA#2 equ $39b
def nB_2 equ $3da
def nC_3 equ $416
def nC#3 equ $44e
def nD_3 equ $483
def nD#3 equ $4b5
def nE_3 equ $4e5
def nF_3 equ $511
def nF#3 equ $53b
def nG_3 equ $563
def nG#3 equ $589
def nA_3 equ $5ac
def nA#3 equ $5ce
def nB_3 equ $5ed
def nC_4 equ $60b
def nC#4 equ $627
def nD_4 equ $642
def nD#4 equ $65b
def nE_4 equ $672
def nF_4 equ $689
def nF#4 equ $69e
def nG_4 equ $6b2
def nG#4 equ $6c4
def nA_4 equ $6d6
def nA#4 equ $6e7
def nB_4 equ $6f7
def nC_5 equ $706
def nC#5 equ $714
def nD_5 equ $721
def nD#5 equ $72d
def nE_5 equ $739
def nF_5 equ $744
def nF#5 equ $74f
def nG_5 equ $759
def nG#5 equ $762
def nA_5 equ $76b
def nA#5 equ $773
def nB_5 equ $77b
def nC_6 equ $783
def nC#6 equ $78a
def nD_6 equ $790
def nD#6 equ $797
def nE_6 equ $79d
def nF_6 equ $7a2
def nF#6 equ $7a7
def nG_6 equ $7ac
def nG#6 equ $7b1
def nA_6 equ $7b6
def nA#6 equ $7ba
def nB_6 equ $7be
def nC_7 equ $7c1
def nC#7 equ $7c5
def nD_7 equ $7c8
def nD#7 equ $7cb
def nE_7 equ $7ce
def nF_7 equ $7d1
def nF#7 equ $7d4
def nG_7 equ $7d6
def nG#7 equ $7d9
def nA_7 equ $7db
def nA#7 equ $7dd
def nB_7 equ $7df
def nC_8 equ $7e1
def nC#8 equ $7e2
def nD_8 equ $7e4
def nD#8 equ $7e6
def nE_8 equ $7e7
def nF_8 equ $7e9
def nF#8 equ $7ea
def nG_8 equ $7eb
def nG#8 equ $7ec
def nA_8 equ $7ed
def nA#8 equ $7ee
def nB_8 equ $7ef
