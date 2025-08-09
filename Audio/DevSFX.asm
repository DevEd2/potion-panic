; =============================================================================
; DevSFX sound effect engine
; Copyright (C) 2024 DevEd
;
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
; 
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
; 
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.
; =============================================================================

def SFX_PRIO_MAX = 0
def SFX_PRIO_MIN = 63

; SFX sequence commands

macro s_header
	;IF def(CHANNEL)
	;	FAIL "Please only define one SFX per file. Do not use `s_header` manually, it is automatically generated from the filename!"
	;ENDC

	def CHANNEL equ (\1)
	assert (CHANNEL > 0) && (CHANNEL < 5), "SFX channel must be between 1 and 4!"
	assert (\2) <= 63, "SFX priority must be between 0 and 63!"
	db (CHANNEL - 1) << 6 | (\2)
endm

; Marks the end of a sound sequence.
macro s_end
	db	0
    purge CHANNEL
endm

; usage: s_pitch freq
; @param freq: Frequency
macro s_pitch
	assert CHANNEL != 4, "s_pitch cannot be used on channel 4, please use s_noise instead"
	db	1
	dw	\1
endm

; usage: s_noise freq
; @param freq: Frequency
macro s_noise
	assert CHANNEL == 4, "s_noise can only be used on channel 4, please use s_pitch instead"
	db	1
	db	\1
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
	db	2
	db	(\1 << 4) | (\2 << 3) | \3
endm
def ENV_DIR_UP = 1
def ENV_DIR_DOWN = 0

; Same as s_env but the direction and length are omitted.
macro s_vol
	assert CHANNEL != 3, "s_vol cannot be used on channel 3, please use s_wvol instead"
	assert ((\1 >= 0) & (\1 < 16)), "Volume must be between 0 and 15!"
	db	2
	db	(\1 << 4)
endm

; Set the volume of the wave channel.
; Only valid on CH3.
; @usage: s_vol vol
; @param vol
macro s_wvol
	assert CHANNEL == 3, "s_wvol can only be used on channel 3, please use s_env or s_vol instead"
	db	2
	db	\1
endm

def WAVE_VOL_0		= $00
def WAVE_VOL_25		= $60
def WAVE_VOL_50		= $40
def WAVE_VOL_100	= $20

; Set the pulse width.
; Overrides any active pulse modulation effects.
; Only valid on CH1 and CH2.
; @usage: s_pulse p
; @param p, pulse width
macro s_pulse
	assert CHANNEL != 3 & CHANNEL != 4, "s_pulse can only be used on channel 1 and channel 2"
	assert ((\1 >= 0) & (\1 < 4)), "Invalid pulse width!"
	db	3
	db	\1 << 6
endm

def PULSE_125 = 0	; -_______	; 12.5%
def PULSE_25 = 1	; --______	; 25%
def PULSE_50 = 2	; ----____	; 50% - square wave
def PULSE_75 = 3	; __------	; 75% - same as 25% but inverted

; Sets the waveform for CH3.
; Only valid on CH3.
; usage: s_wave ptr
; @param ptr, Wave pointer
; WARNING: If pointer is in ROMX, it MUST be in the same bank as the sound effect!
; WARNING: This overrides CH3's volume level!
macro s_wave
	assert CHANNEL == 3, "s_wave can only be used on channel 3"
	assert BANK(\1) == BANK(@)
	db	3
	dw	\1
endm

macro s_wait
	db	4
	db	\1
endm

macro s_pan
	db	5
	db	\1
endm
def PAN_LEFT	= %00010000
def PAN_RIGHT	= %00000001
def PAN_CENTER	= %00010001
def PAN_NONE	= %00000000 ; not recommended - use s_vol or s_wvol to set volume to zero instead

macro s_set_prio
	db	6
	db	\1
endm

; usage: s_slide speed
; @param speed = speed of slide
macro s_slide
	assert CHANNEL != 4, "s_slide cannot be used on channel 4"
	db	7
	dw	\1
endm

; Force a retrigger without needing to reload the envelope. Does not apply to CH3.
; usage: s_restart
; No parameters.
macro s_restart
	assert CHANNEL != 3, "s_restart cannot be used on channel 3"
	db	8
endm

; Set range for random pitch.
; usage: s_pitchrange
macro s_pitchrange
	assert CHANNEL != 4, "s_pitchrange cannot be used on channel 4"
	db	9
	db	\1
endm

macro s_resetpitch
	assert CHANNEL != 4, "s_resetpitch cannot be used on channel 4"
	db	10
endm

; Set repeat count.
; usage: s_repeat times
; @param times: number of times to repeat, 255 = forever
macro s_repeat
	db	11
	dw	\1
	db	\2
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

section "DevSFX RAM",wram0
DSFX_RAM:
DSFX_Enabled::			db	; set to 0 to disable sound effects

; pointer to SFX sequence for each channel
DSFX_CH1Pointer:		dw
DSFX_CH2Pointer:		dw
DSFX_CH3Pointer:		dw
DSFX_CH4Pointer:		dw
; time until SFX sequence fetch is needed
DSFX_CH1Timer:			db
DSFX_CH2Timer:			db
DSFX_CH3Timer:			db
DSFX_CH4Timer:			db
; pitch offset (used for randomized pitch mode)
DSFX_CH1PitchOffset:	dw
DSFX_CH2PitchOffset:	dw
DSFX_CH3PitchOffset:	dw
; priority of currently playing sound effects
; If bit 7 is set, no SFX is playing on that channel.
DSFX_CH1Priority:		db
DSFX_CH2Priority:		db
DSFX_CH3Priority:		db
DSFX_CH4Priority:		db
; panning of currently playing sound effects
DSFX_CH1Panning:		db
DSFX_CH2Panning:		db
DSFX_CH3Panning:		db
DSFX_CH4Panning:		db
; slide speed of currently playing sound effects
DSFX_CH1SlideSpeed:		dw
DSFX_CH2SlideSpeed:		dw
DSFX_CH3SlideSpeed:		dw
; current pitch of playing sound effects
DSFX_CH1Pitch:			dw
DSFX_CH2Pitch:			dw
DSFX_CH3Pitch:			dw
; stereo flags
DSFX_StereoMask:		db
; repeat count
; 00: no repeat
; FF: repeat forever (use DSFX_KillChannel to stop)
; all others: repeat N times
DSFX_CH1RepeatCount:	db
DSFX_CH2RepeatCount:	db
DSFX_CH3RepeatCount:	db
DSFX_CH4RepeatCount:	db
; repeat pointer
DSFX_CH1RepeatPtr:		dw
DSFX_CH2RepeatPtr:		dw
DSFX_CH3RepeatPtr:		dw
DSFX_CH4RepeatPtr:		dw
; volume fade amount - volume is decremented by this when fading
DSFX_CH1VolFadeAmount:	db
DSFX_CH2VolFadeAmount:	db
DSFX_CH3VolFadeAmount:	db
DSFX_CH4VolFadeAmount:	db
; volume fade speed - volume decrements after this many frames when fading
; bit 7 set: fade after N repeats
DSFX_CH1VolFadeSpeed:	db
DSFX_CH2VolFadeSpeed:	db
DSFX_CH3VolFadeSpeed:	db
DSFX_CH4VolFadeSpeed:	db
; volume fade counter
DSFX_CH1VolFadeCount:	db
DSFX_CH2VolFadeCount:	db
DSFX_CH3VolFadeCount:	db
DSFX_CH4VolFadeCount:	db
DSFX_MusicPanning::		db
DSFX_RAM_End:

; =============================================================================

section "DevSFX trampolines",rom0
DSFX_Init:
    push    af
    pushbank
    farcall _DSFX_Init
    popbank
    pop     af
    ret
    
DSFX_PlaySound:
    push    af
    pushbank
    farcall _DSFX_PlaySound
    popbank
    pop     af
    ret

DSFX_KillChannel:
    push    af
    pushbank
    farcall _DSFX_KillChannel
    popbank
    pop     af
    ret
    
DSFX_Update:
    push    af
    pushbank
    farcall _DSFX_Update
    popbank
    pop     af
    ret

section "DevSFX routines",romx

DSFX_Thumbprint:
    pushc
    setcharmap main
    db  "DevSFX sound effect engine by DevEd | deved8@gmail.com",0
    popc

    include "Audio/SFX/Pointers.inc"
    assert bank(DSFX_SFXPointers) == bank(DSFX_Thumbprint)

; Init DSFX.
; @destroy: a
_DSFX_Init::
    ld      hl,DSFX_RAM
    ld      b,DSFX_RAM_End-DSFX_RAM
    xor     a
    call    MemFillSmall
	ld		a,$FF
	ld		[DSFX_CH1Priority],a
	ld		[DSFX_CH2Priority],a
	ld		[DSFX_CH3Priority],a
	ld		[DSFX_CH4Priority],a
	ld		[DSFX_Enabled],a
	ld		[DSFX_MusicPanning],a
	ret

; Play a sound effect.
; @param e: sound id
; @destroy: af, b, de, hl
_DSFX_PlaySound::
	ld		a,[DSFX_Enabled]
	and		a
	ret		z
	; get pointer to sound effect
	ld		l,e
	ld		h,0
	add		hl,hl
	ld		de,DSFX_SFXPointers
	add		hl,de
	ld		a,[hl+]
	ld		h,[hl]
	ld		l,a
	; get channel
	ld		a,[hl]
	swap	a
	rra
	rra
	and		3
	jp		z,.ch1
	dec		a
	jr		z,.ch2
	dec		a
	jr		z,.ch3
	; default case: fall through to channel 4 init
.ch4
	ld		a,[hl]
	and		SFX_PRIO_MIN
	ld		b,a
	ld		a,[DSFX_CH4Priority]
	cp		b
	ret		c	; if priority of current sfx > priority of new sfx, exit
	ld		a,[hl+]
	and		SFX_PRIO_MIN
	ld		[DSFX_CH4Priority],a
	ld		a,1
	ld		[DSFX_CH4Timer],a
	ld		a,l
	ld		[DSFX_CH4Pointer],a
	ld		a,h
	ld		[DSFX_CH4Pointer+1],a
	ld		hl,GBM_PanFlags
	set		3,[hl]
	ld		a,$11 << 3
	ld		[DSFX_CH4Panning],a
	ld		b,a
	ld		a,[DSFX_StereoMask]
	or		b
	ld		[DSFX_StereoMask],a
	ret
.ch3
	ld		a,[hl]
	and		SFX_PRIO_MIN
	ld		b,a
	ld		a,[DSFX_CH3Priority]
	cp		b
	ret		c	; if priority of current sfx > priority of new sfx, exit
	ld		a,[hl+]
	and		SFX_PRIO_MIN
	ld		[DSFX_CH3Priority],a
	xor		a
	ld		[DSFX_CH3SlideSpeed],a
	ld		[DSFX_CH3SlideSpeed+1],a
	ld		[DSFX_CH3PitchOffset],a
	ld		[DSFX_CH3PitchOffset+1],a
	inc		a
	ld		[DSFX_CH3Timer],a
	ld		a,l
	ld		[DSFX_CH3Pointer],a
	ld		a,h
	ld		[DSFX_CH3Pointer+1],a
	ld		hl,GBM_PanFlags
	set		2,[hl]
	ld		a,$11 << 2
	ld		[DSFX_CH3Panning],a
	ld		b,a
	ld		a,[DSFX_StereoMask]
	or		b
	ld		[DSFX_StereoMask],a
	ret
.ch2
	ld		a,[hl]
	and		SFX_PRIO_MIN
	ld		b,a
	ld		a,[DSFX_CH2Priority]
	cp		b
	ret		c	; if priority of current sfx > priority of new sfx, exit
	ld		a,[hl+]
	and		SFX_PRIO_MIN
	ld		[DSFX_CH2Priority],a
	xor		a
	ld		[DSFX_CH2SlideSpeed],a
	ld		[DSFX_CH2SlideSpeed+1],a
	ld		[DSFX_CH2PitchOffset],a
	ld		[DSFX_CH2PitchOffset+1],a
	inc		a
	ld		[DSFX_CH2Timer],a
	ld		a,l
	ld		[DSFX_CH2Pointer],a
	ld		a,h
	ld		[DSFX_CH2Pointer+1],a
	ld		hl,GBM_PanFlags
	set		1,[hl]
	ld		a,$11 << 1
	ld		[DSFX_CH2Panning],a
	ld		b,a
	ld		a,[DSFX_StereoMask]
	or		b
	ld		[DSFX_StereoMask],a
	ret
.ch1
	ld		a,[DSFX_CH1Priority]
	cp		[hl]
	ret		c	; if priority of current sfx > priority of new sfx, exit
	ld		a,[hl+]
	ld		[DSFX_CH1Priority],a
	xor		a
	ld		[DSFX_CH1SlideSpeed],a
	ld		[DSFX_CH1SlideSpeed+1],a
	ld		[DSFX_CH1PitchOffset],a
	ld		[DSFX_CH1PitchOffset+1],a
	inc		a
	ld		[DSFX_CH1Timer],a
	ld		a,l
	ld		[DSFX_CH1Pointer],a
	ld		a,h
	ld		[DSFX_CH1Pointer+1],a
	ld		hl,GBM_PanFlags
	set		0,[hl]
	ld		a,$11
	ld		[DSFX_CH1Panning],a
	ld		b,a
	ld		a,[DSFX_StereoMask]
	or		b
	ld		[DSFX_StereoMask],a
	xor		a
	ldh		[rNR10],a
	ret

; ----------------

macro kill_channel
	; force wave reload if on ch3
	if		\1 == 3
	ld		a,$ff
	ld		[GBM_LastWave],a
	endc
	xor		a
	ldh		[rNR\12],a
	dec		a ; ld a,$FF
	ld		[DSFX_CH\1Priority],a
	if		\1 != 3
	ld		a,$80
	ldh		[rNR\14],a
	endc
	ld		hl,GBM_PanFlags
	res		\1-1,[hl]
	; reset panning mask
	ld		a,[DSFX_StereoMask]
	ld		b,a
	ld		a,%00010001 << (\1 - 1)
	cpl
	and		b
	ld		[DSFX_StereoMask],a
	endm

; @param c: channel to kill
_DSFX_KillChannel::
	ld		a,c
	add		a
	ld		e,a
	ld		d,0
	ld		hl,.ptrs
	add		hl,de
	ld		a,[hl+]
	ld		h,[hl]
	ld		l,a
	jp		hl
.ptrs	dw	.ch1,.ch2,.ch3,.ch4
.ch1	kill_channel 1
		ret
.ch2	kill_channel 2
		ret
.ch3	kill_channel 3
		ret
.ch4	kill_channel 4
		ret

; ----------------

; @destroy: af, bc, de, hl
_DSFX_Update::
    xor     a
    ld      [GBM_SkipCH1],a
    ld      [GBM_SkipCH2],a
    ld      [GBM_SkipCH3],a
    ld      [GBM_SkipCH4],a
	ld		a,[DSFX_CH1Priority]
	add		a,a
	call	nc,DSFX_UpdateCH1
	ld		a,[DSFX_CH2Priority]
	add		a,a
	call	nc,DSFX_UpdateCH2
	ld		a,[DSFX_CH3Priority]
	add		a,a
	call	nc,DSFX_UpdateCH3
	ld		a,[DSFX_CH4Priority]
	add		a,a
	call	nc,DSFX_UpdateCH4
	
	; update panning
	
	ld		b,0
	ld		a,[DSFX_CH1Panning]
	or		b
	ld		b,a
	ld		a,[DSFX_CH2Panning]
	or		b
	ld		b,a
	ld		a,[DSFX_CH3Panning]
	or		b
	ld		b,a
	ld		a,[DSFX_CH4Panning]
	or		b
	ld		b,a
	ld		a,[DSFX_StereoMask]
	cpl
	ld		c,a
	cpl
	and		b
	ld		b,a
	ld		a,[DSFX_MusicPanning]
	and		c
	or		b
	ldh		[rNR51],a	 
	ret

macro dsfx_update_channel
DSFX_UpdateCH\1:
    ld      a,1
    ld      [GBM_SkipCH\1],a
	; do timer
	ld		hl,DSFX_CH\1Timer
	dec		[hl]
	jp		nz,DSFX_CH\1_Skip
	; get the command stream pointer
	ld		hl,DSFX_CH\1Pointer
	ld		a,[hl+]
	ld		h,[hl]
	ld		l,a
DSFX_CH\1_GetByte:
	ld		a,[hl+]
	push	hl
	add		a,a
	add		a,LOW(DSFX_CH\1_CommandTable)
	ld		l,a
	adc		a,HIGH(DSFX_CH\1_CommandTable)
	sub		l
	ld		h,a
	ld		a,[hl+]
	ld		h,[hl]
	ld		l,a
	bit     7,h
    jp      nz,CallHL_Error
    jp      hl

DSFX_CH\1_CommandTable:
	dw		.end
	dw		.pitch
	dw		.envelope
	dw		.pulse
	dw		.wait
	dw		.pan
	dw		.setprio
	dw		.slide
	dw		.restart
	dw		.pitchrange
	dw		.resetpitch

.end
	pop		hl
	kill_channel \1
	jp		.done

.pitch
	if		\1 != 4
	pop		hl
	ld		a,[DSFX_CH\1PitchOffset]
	add		[hl]
	ld		[DSFX_CH\1Pitch],a
	ldh		[rNR\13],a
	inc		hl	; does not affect flags
	ld		a,[DSFX_CH\1PitchOffset+1]
	adc		[hl]
	and		7
	ld		[DSFX_CH\1Pitch+1],a
	ldh		[rNR\14],a
	inc		hl
	else
	pop		hl
	ld		a,[hl+]
	ldh		[rNR\13],a
	endc
	jr		DSFX_CH\1_GetByte

.envelope
	pop		hl
	ld		a,[hl+]
	ldh		[rNR\12],a
	if		\1 == 3
		; don't restart envelope to avoid DMG wave corruption bug
	elif	\1 == 4
		; restart envelope
		ld		a,$80
		ldh		[rNR\14],a
	else
		; restart envelope, but don't overwrite high byte of pitch
		ld		a,[DSFX_CH\1Pitch+1]
		set		7,a
		ldh		[rNR\14],a
	endc
	jp		DSFX_CH\1_GetByte

.pulse	; only valid on CH1 and CH2
.wave	; only valid on CH3
	pop		hl
	; set pulse width (CH1 and CH2 only)
	if		(\1 == 1) | (\1 == 2)
	ld		a,[hl+]
	ldh		[rNR\11],a
	; load wave pointer (CH3 only)
	elif	\1 == 3
	ld		a,[hl+]
	push	hl
	ld		h,[hl]
	ld		l,a
	; gba antispike
	ldh		a,[rNR51]
	ld		e,a
	and		%10111011
	ldh		[rNR51],a
	; disable ch3
	xor		a
	ldh		[rNR30],a
	; load waveform
	; using an unrolled loop in an attempt to minimize overhead
	for		n,16
	ld		a,[hl+]
	ldh		[_AUD3WAVERAM + n],a
	endr
	; reenable ch3
	ld		a,$80
	ldh		[rNR30],a
	ldh		[rNR34],a	; retrigger
	ld		a,e
	ldh		[rNR51],a
	; done
	pop		hl
	inc		hl
	endc
	jp		DSFX_CH\1_GetByte

.loop
	pop		hl
	; TODO
	jp		DSFX_CH\1_GetByte

.wait
	pop		hl
	ld		a,[hl+]
	ld		[DSFX_CH\1Timer],a
	jp		.done

.pan
	pop		hl
	ld		a,[hl+]
	if		\1 != 1
	and		a
	rept	\1 - 1
	rla
	endr
	endc
	ld		[DSFX_CH\1Panning],a
	ld		a,[DSFX_StereoMask]
	or		%00010001 << (\1 - 1)
	ld		[DSFX_StereoMask],a
	jp		DSFX_CH\1_GetByte

.setprio
	pop		hl
	ld		a,[hl+]
	ld		[DSFX_CH\1Priority],a
	jp		DSFX_CH\1_GetByte

.slide
	pop		hl
	if		\1 != 4
	ld		a,[hl+]
	ld		[DSFX_CH\1SlideSpeed],a
	ld		a,[hl+]
	ld		[DSFX_CH\1SlideSpeed+1],a
	endc
	jp		DSFX_CH\1_GetByte

.restart
	if		\1 != 3
	ld		hl,rNR\14
	set		7,[hl]
	endc
	pop		hl
	jp		DSFX_CH\1_GetByte

.pitchrange	 
	pop		hl
	if		\1 != 4
	ld		a,[hl+]
	and		a
	jr		z,.norand
	ld		e,a
	push	hl
:	call	Math_Random
	ld b, a
	; ld	  b,a	  ; b already contains value of a after call to rand
	and		$7f
	cp		e
	jr		nc,:-
	pop		hl
	ld		a,b		
	bit		7,a
	jr		z,:+
	and		$7f
	cpl
	inc		a
	ld		[DSFX_CH\1PitchOffset],a
	rla
	sbc		a		
	ld		[DSFX_CH\1PitchOffset+1],a 
	jp		DSFX_CH\1_GetByte
:	ld		[DSFX_CH\1PitchOffset],a
	xor		a
	ld		[DSFX_CH\1PitchOffset+1],a
	; fall through		
.norand
	endc
	jp		DSFX_CH\1_GetByte

.resetpitch
	if		\1 != 4
	xor		a
	ld		[DSFX_CH\1PitchOffset],a
	ld		[DSFX_CH\1PitchOffset+1],a
	endc
	pop		hl
	jp		DSFX_CH\1_GetByte

.done
	ld		a,l
	ld		[DSFX_CH\1Pointer],a
	ld		a,h
	ld		[DSFX_CH\1Pointer+1],a
DSFX_CH\1_Skip:
	if		\1 != 4
	ld		hl,DSFX_CH\1SlideSpeed
	ld		a,[hl+]
	or		[hl]
	jr		z,.noslide

	ld		hl,DSFX_CH\1Pitch
	ld		a,[hl+]
	ld		b,[hl]
	ld		c,a
	ld		hl,DSFX_CH\1SlideSpeed
	ld		a,[hl+]
	ld		h,[hl]
	ld		l,a
	add		hl,bc
.continue
	ld		a,l
	ld		[DSFX_CH\1Pitch],a
	ldh		[rNR\13],a
	ld		a,h
	ld		[DSFX_CH\1Pitch+1],a
	and		7	; prevent unintentional retrigger
	ldh		[rNR\14],a
.noslide
	endc

	ret
endm

	dsfx_update_channel 1
	dsfx_update_channel 2
	dsfx_update_channel 3
	dsfx_update_channel 4
