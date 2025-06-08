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

include "Audio/DevSFX.inc"

section "DevSFX RAM",wram0

DSFX_Enabled::          db  ; set to 0 to disable sound effects

; pointer to SFX sequence for each channel
DSFX_CH1Pointer:        dw
DSFX_CH2Pointer:        dw
DSFX_CH3Pointer:        dw
DSFX_CH4Pointer:        dw
; time until SFX sequence fetch is needed
DSFX_CH1Timer:          db
DSFX_CH2Timer:          db
DSFX_CH3Timer:          db
DSFX_CH4Timer:          db
; pitch offset (used for randomized pitch mode)
DSFX_CH1PitchOffset:    dw
DSFX_CH2PitchOffset:    dw
DSFX_CH3PitchOffset:    dw
; priority of currently playing sound effects
; If bit 7 is set, no SFX is playing on that channel.
DSFX_CH1Priority:       db
DSFX_CH2Priority:       db
DSFX_CH3Priority:       db
DSFX_CH4Priority:       db
; panning of currently playing sound effects
DSFX_CH1Panning:        db
DSFX_CH2Panning:        db
DSFX_CH3Panning:        db
DSFX_CH4Panning:        db
; slide speed of currently playing sound effects
DSFX_CH1SlideSpeed:     dw
DSFX_CH2SlideSpeed:     dw
DSFX_CH3SlideSpeed:     dw
;DSFX_CH4SlideSpeed:     dw
; current pitch of playing sound effects
DSFX_CH1Pitch:          dw
DSFX_CH2Pitch:          dw
DSFX_CH3Pitch:          dw
;DSFX_CH4Pitch:          dw

; =============================================================================

section "DevSFX routines",romx

DSFX_Thumbprint:
    pushc
    setcharmap  main
    db      "DevSFX sound effect engine by DevEd | deved8@gmail.com",0
    popc
    
DSFX_SFXPointers:
include "Audio/SFX/Pointers.inc"

; Init DSFX.
; @destroy: a
DSFX_Init::
    ld      a,$FF
    ld      [DSFX_CH1Priority],a
    ld      [DSFX_CH2Priority],a
    ld      [DSFX_CH3Priority],a
    ld      [DSFX_CH4Priority],a
    ld      [DSFX_Enabled],a
    ret

DSFX_PlaySound:
    ; get pointer to sound effect
    ld      l,e
    ld      h,0
    add     hl,hl
    ld      de,DSFX_SFXPointers
    add     hl,de
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    ; get channel
    ld      a,[hl]
    swap    a
    rra
    rra
    and     3
    jp      z,.ch1
    dec     a
    jr      z,.ch2
    dec     a
    jr      z,.ch3
    ; default case: fall through to channel 4 init
.ch4
    ld      a,[hl]
    and     SFX_PRIO_MIN
    ld      b,a
    ld      a,[DSFX_CH4Priority]
    cp      b
    ret     c   ; if priority of current sfx > priority of new sfx, exit
    ld      a,[hl+]
    and     SFX_PRIO_MIN
    ld      [DSFX_CH4Priority],a
    ld      a,1
    ld      [DSFX_CH4Timer],a
    ld      a,l
    ld      [DSFX_CH4Pointer],a
    ld      a,h
    ld      [DSFX_CH4Pointer+1],a
    ;ld      hl,hUGE_MutedChannels
    ;set     3,[hl]
    ld      a,$11 << 3
    ld      [DSFX_CH4Panning],a
    ret
.ch3
    ld      a,[hl]
    and     SFX_PRIO_MIN
    ld      b,a
    ld      a,[DSFX_CH3Priority]
    cp      b
    ret     c   ; if priority of current sfx > priority of new sfx, exit
    ld      a,[hl+]
    and     SFX_PRIO_MIN
    ld      [DSFX_CH3Priority],a
    xor     a
    ld      [DSFX_CH3SlideSpeed],a
    ld      [DSFX_CH3SlideSpeed+1],a
    ld      [DSFX_CH3PitchOffset],a
    ld      [DSFX_CH3PitchOffset+1],a
    inc     a
    ld      [DSFX_CH3Timer],a
    ld      a,l
    ld      [DSFX_CH3Pointer],a
    ld      a,h
    ld      [DSFX_CH3Pointer+1],a
    ;ld      hl,hUGE_MutedChannels
    ;set     2,[hl]
    ld      a,$11 << 2
    ld      [DSFX_CH4Panning],a
    ret
.ch2
    ld      a,[hl]
    and     SFX_PRIO_MIN
    ld      b,a
    ld      a,[DSFX_CH2Priority]
    cp      b
    ret     c   ; if priority of current sfx > priority of new sfx, exit
    ld      a,[hl+]
    and     SFX_PRIO_MIN
    ld      [DSFX_CH2Priority],a
    xor     a
    ld      [DSFX_CH2SlideSpeed],a
    ld      [DSFX_CH2SlideSpeed+1],a
    ld      [DSFX_CH2PitchOffset],a
    ld      [DSFX_CH2PitchOffset+1],a
    inc     a
    ld      [DSFX_CH2Timer],a
    ld      a,l
    ld      [DSFX_CH2Pointer],a
    ld      a,h
    ld      [DSFX_CH2Pointer+1],a
    ;ld      hl,hUGE_MutedChannels
    ;set     1,[hl]
    ld      a,$11 << 1
    ld      [DSFX_CH4Panning],a
    ret
.ch1
    ld      a,[DSFX_CH1Priority]
    cp      [hl]
    ret     c   ; if priority of current sfx > priority of new sfx, exit
    ld      a,[hl+]
    ld      [DSFX_CH1Priority],a
    xor     a
    ld      [DSFX_CH1SlideSpeed],a
    ld      [DSFX_CH1SlideSpeed+1],a
    ld      [DSFX_CH1PitchOffset],a
    ld      [DSFX_CH1PitchOffset+1],a
    inc     a
    ld      [DSFX_CH1Timer],a
    ld      a,l
    ld      [DSFX_CH1Pointer],a
    ld      a,h
    ld      [DSFX_CH1Pointer+1],a
    ;ld      hl,hUGE_MutedChannels
    ;set     0,[hl]
    ld      a,$11
    ld      [DSFX_CH4Panning],a
    xor     a
    ldh     [rNR10],a
    ret

; ----------------

; @destroy: af, bc, de, hl
DSFX_Update::
    ld      a,[DSFX_CH1Priority]
    add     a,a
    call    nc,DSFX_UpdateCH1
    ld      a,[DSFX_CH2Priority]
    add     a,a
    call    nc,DSFX_UpdateCH2
    ld      a,[DSFX_CH3Priority]
    add     a,a
    call    nc,DSFX_UpdateCH3
    ld      a,[DSFX_CH4Priority]
    add     a,a
    call    nc,DSFX_UpdateCH4
    ret

macro dsfx_update_channel
DSFX_UpdateCH\1:
    ; do timer
    ld      hl,DSFX_CH\1Timer
    dec     [hl]
    jp      nz,DSFX_CH\1_Skip
    ; get the command stream pointer
    ld      hl,DSFX_CH\1Pointer
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
DSFX_CH\1_GetByte:
    ld      a,[hl+]
    push    hl
    add     a,a
    add     a,LOW(DSFX_CH\1_CommandTable)
    ld      l,a
    adc     a,HIGH(DSFX_CH\1_CommandTable)
    sub     l
    ld      h,a
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    bit     7,a
    jr      z,.error
    jp      hl
.error
    push    af
    ld      a,ERR_INV_SFX_COMMAND
    ldh     [hErrType],a
    pop     af
    rst     Error

DSFX_CH\1_CommandTable:
    dw      .end
    dw      .pitch
    dw      .envelope
    dw      .pulse
    dw      .wait
    dw      .pan
    dw      .setprio
    dw      .slide
    dw      .restart
    dw      .pitchrange
    dw      .resetpitch

.end
    pop     hl
    ; force wave reload if on ch3
    if      \1 == 3
    ;ld      a,hUGE_NO_WAVE
    ;ld      [hUGE_LoadedWaveID],a
    endc
    xor     a
    ldh     [rNR\12],a
    dec     a ; ld a,$FF
    ld      [DSFX_CH\1Priority],a
    if      \1 != 3
    ld      a,$80
    ldh     [rNR\14],a
    endc
    ;ld      hl,hUGE_MutedChannels
    ;res     \1-1,[hl]
    jp      .done

.pitch
    if      \1 != 4
    pop     hl
    ld      a,[DSFX_CH\1PitchOffset]
    add     [hl]
    ld      [DSFX_CH\1Pitch],a
    ldh     [rNR\13],a
    inc     hl  ; does not affect flags
    ld      a,[DSFX_CH\1PitchOffset+1]
    adc     [hl]
    and     7
    ld      [DSFX_CH\1Pitch+1],a
    ldh     [rNR\14],a
    inc     hl
    else
    pop     hl
    ld      a,[hl+]
    ldh     [rNR\13],a
    endc
    jr      DSFX_CH\1_GetByte

.envelope
    pop     hl
    ld      a,[hl+]
    ldh     [rNR\12],a
    if      \1 != 3 ; restart sound unless we're on ch3 to avoid DMG wave corruption bug
    push    hl
    ld      hl,rNR\14
    set     7,[hl]
    pop     hl
    endc
    jp      DSFX_CH\1_GetByte

.pulse  ; only valid on CH1 and CH2
.wave   ; only valid on CH3
    pop     hl
    ; set pulse width (CH1 and CH2 only)
    if      (\1 == 1) | (\1 == 2)
    ld      a,[hl+]
    ldh     [rNR\11],a
    ; load wave pointer (CH3 only)
    elif    \1 == 3
    ld      a,[hl+]
    push    hl
    ld      h,[hl]
    ld      l,a
    ; gba antispike
    ldh     a,[rNR51]
    ld      e,a
    and     %10111011
    ldh     [rNR51],a
    ; disable ch3
    xor     a
    ldh     [rNR30],a
    ; load waveform
    ; using an unrolled loop in an attempt to minimize overhead
    for     n,16
    ld      a,[hl+]
    ldh     [_AUD3WAVERAM + n],a
    endr
    ; reenable ch3
    ld      a,$80
    ldh     [rNR30],a
    ldh     [rNR34],a   ; retrigger
    ld      a,e
    ldh     [rNR51],a
    ; done
    pop     hl
    inc     hl
    endc
    jp      DSFX_CH\1_GetByte

.loop
    pop     hl
    ; TODO
    jp      DSFX_CH\1_GetByte

.wait
    pop     hl
    ld      a,[hl+]
    ld      [DSFX_CH\1Timer],a
    jp      .done

.pan
    pop     hl
    ld      a,[hl+]
    if      \1 != 1
    and     a
    rept    \1 - 1
    rla
    endr
    endc
    ld      [DSFX_CH\1Panning],a
    jp      DSFX_CH\1_GetByte

.setprio
    pop     hl
    ld      a,[hl+]
    ld      [DSFX_CH\1Priority],a
    jp      DSFX_CH\1_GetByte

.slide
    pop     hl
    if      \1 != 4
    ld      a,[hl+]
    ld      [DSFX_CH\1SlideSpeed],a
    ld      a,[hl+]
    ld      [DSFX_CH\1SlideSpeed+1],a
    endc
    jp      DSFX_CH\1_GetByte

.restart
    if      \1 != 3
    ld      hl,rNR\14
    set     7,[hl]
    endc
    pop     hl
    jp      DSFX_CH\1_GetByte

.pitchrange  
;    pop     hl
;    if      \1 != 4
;    ld      a,[hl+]
;    and     a
;    jr      z,.norand
;    ld      e,a
;    push    hl
;:   call    rand
;    ; ld      b,a     ; b already contains value of a after call to rand
;    and     $7f
;    cp      e
;    jr      nc,:-
;    pop     hl
;    ld      a,b     
;    bit     7,a
;    jr      z,:+
;    and     $7f
;    cpl
;    inc     a
;    ld      [DSFX_CH\1PitchOffset],a
;    rla
;    sbc     a       
;    ld      [DSFX_CH\1PitchOffset+1],a 
;    jp      DSFX_CH\1_GetByte
;:   ld      [DSFX_CH\1PitchOffset],a
;    xor     a
;    ld      [DSFX_CH\1PitchOffset+1],a
;    ; fall through      
;.norand
;    endc
    jp      DSFX_CH\1_GetByte

.resetpitch
    if      \1 != 4
    xor     a
    ld      [DSFX_CH\1PitchOffset],a
    ld      [DSFX_CH\1PitchOffset+1],a
    endc
    pop     hl
    jp      DSFX_CH\1_GetByte

.done
    ld      a,l
    ld      [DSFX_CH\1Pointer],a
    ld      a,h
    ld      [DSFX_CH\1Pointer+1],a
DSFX_CH\1_Skip:
    if      \1 != 4
    ld      hl,DSFX_CH\1SlideSpeed
    ld      a,[hl+]
    or      [hl]
    jr      z,.noslide

    ld      hl,DSFX_CH\1Pitch
    ld      a,[hl+]
    ld      b,[hl]
    ld      c,a
    ld      hl,DSFX_CH\1SlideSpeed
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    add     hl,bc
.continue
    ld      a,l
    ld      [DSFX_CH\1Pitch],a
    ldh     [rNR\13],a
    ld      a,h
    ld      [DSFX_CH\1Pitch+1],a
    and     7   ; prevent unintentional retrigger
    ldh     [rNR\14],a
.noslide
    endc

    ret
endm

    dsfx_update_channel 1
    dsfx_update_channel 2
    dsfx_update_channel 3
    dsfx_update_channel 4
