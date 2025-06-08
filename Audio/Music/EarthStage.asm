Mus_EarthStage:
    db  5,5
    dw  Earth_CH1
    dw  Earth_CH2
    dw  Earth_CH3
    dw  Earth_CH4

; ================================================================

Earth_CH1:
    ; intro
.loop
    sound_instrument    Ins_EarthBass
    sound_call  .block1
    sound_loop  6,.loop
    sound_call  .block2
:   sound_call  .block1
    sound_loop  15,:-
    ; intro transition
:   sfixins Ins_EarthTom,2
    sound_instrument    Ins_EarthBass
    note    D_,2,2
    note    D_,2,2
    sound_loop 1,:-
    sfixins Ins_EarthTom,2
    sfix    2
    ; verse 1
    sound_instrument    Ins_EarthBass
:   sound_call  .block1
    sound_call  .block1
    sound_call  .block1
    sound_call  .block1
    sound_call  .block4
    sound_loop  2,:-
:   sound_call  .block5
    sound_loop  7,:-
:   sound_call  .block1
    sound_call  .block1
    sound_call  .block1
    sound_call  .block1
    sound_call  .block4
    sound_loop  2,:-
:   sound_call  .block5
    sound_loop  6,:-
    sound_call  .block2
    ; verse 2
:   note    C_,3,2
    note    C_,3,2
    sfixins Ins_EarthTom,2
    sound_instrument    Ins_EarthBass
    note    C_,3,2
    sound_loop  1,:-
:   note    A_,2,2
    note    A_,2,2
    sfixins Ins_EarthTom,2
    sound_instrument    Ins_EarthBass
    note    A_,2,2
    sound_loop  1,:-
:   sound_call  .block1
    sound_loop  1,:-
    note    B_,2,2
    note    B_,2,2
    sfixins Ins_EarthTom,2
    sound_instrument    Ins_EarthBass
    note    B_,2,2
    note    A_,2,2
    note    A_,2,2
    sfixins Ins_EarthTom,2
    sound_instrument    Ins_EarthBass
    note    A_,2,2
:   note    G_,2,2
    note    G_,2,2
    sfixins Ins_EarthTom,2
    sound_instrument    Ins_EarthBass
    note    G_,2,2
    sound_loop  3,:-
:   note    A_,2,2
    note    A_,2,2
    sfixins Ins_EarthTom,2
    sound_instrument    Ins_EarthBass
    note    A_,2,2
    sound_loop  1,:-
    note    B_,2,2
    note    B_,2,2
    sfixins Ins_EarthTom,2
    sound_instrument    Ins_EarthBass
    note    B_,2,2
    sound_call  .block2
    ; chorus
:   sound_call  .block6
    sound_call  .block7
    note    D_,2,6
    note    D_,3,2
    sfixins Ins_EarthTom,2
    sound_instrument    Ins_EarthBass
    note    D_,2,2
    note    A_,2,2
    note    B_,2,2
    sound_call  .block6
    sound_call  .block7
    note    E_,2,6
    note    E_,3,2
    sfixins Ins_EarthTom,2
    sound_instrument    Ins_EarthBass
    note    E_,2,2
    note    D_,3,2
    note    B_,2,2
    sound_call  .block6
    sound_call  .block7
    note    D_,2,6
    note    D_,3,2
    sfixins Ins_EarthTom,2
    sound_instrument    Ins_EarthBass
    note    D_,2,2
    note    A_,2,2
    note    B_,2,2
    sound_call  .block6
    sound_call  .block7
    note    E_,2,6
    note    E_,3,2
    sfixins Ins_EarthTom,2
    sound_instrument    Ins_EarthBass
    note    E_,2,2
    sfixins Ins_EarthTom,2
    sfix    2
    sound_jump  .loop
.block1
    note    E_,2,2
    note    E_,2,2
    sfixins Ins_EarthTom,2
    sound_instrument    Ins_EarthBass
    note    E_,2,2
    sound_ret
.block2
    sfixins Ins_EarthTom,1
    sfix    1
    sfix    2
    sfix    2
    sfix    1
    sfix    1
    sound_instrument    Ins_EarthBass
    sound_ret
.block4
:   note    G_,2,2
    note    G_,2,2
    sfixins Ins_EarthTom,2
    sound_instrument    Ins_EarthBass
    note    G_,2,2
    note    G_,2,2
    note    G_,2,2
    sfixins Ins_EarthTom,2
    sound_instrument    Ins_EarthBass
    note    G_,2,2
    note    A_,2,2
    note    A_,2,2
    sfixins Ins_EarthTom,2
    sound_instrument    Ins_EarthBass
    note    A_,2,2
    note    A_,2,2
    note    A_,2,2
    sfixins Ins_EarthTom,2
    sound_instrument    Ins_EarthBass
    note    A_,2,2
    sound_ret
.block5
    note    B_,2,2
    note    B_,2,2
    sfixins Ins_EarthTom,2
    sound_instrument    Ins_EarthBass
    note    B_,2,2
    sound_ret
.block6
    note    C_,2,6
    note    C_,3,2
    sfixins Ins_EarthTom,2
    sound_instrument    Ins_EarthBass
    note    C_,2,2
    note    C_,3,4
    note    D_,2,6
    note    D_,3,2
    sfixins Ins_EarthTom,2
    sound_instrument    Ins_EarthBass
    note    D_,2,2
    note    A_,2,4
    sound_ret
.block7
    note    E_,2,6
    note    E_,3,2
    sfixins Ins_EarthTom,2
    sound_instrument    Ins_EarthBass
    note    E_,2,2
    note    E_,3,4
    sound_ret

; ================================================================

Earth_CH2:
    ; intro
.loop
    rest    64
    sound_instrument Ins_EarthPulseArp
    sound_set_arp_ptr Arp_059
:   note        A_,4,12
    note        A_,4,2
    note        B_,4,18
    note        A_,4,12
    note        A_,4,2
    sound_set_arp_ptr Arp_038
    note        C#,5,4
    sound_set_arp_ptr Arp_059
    note        B_,4,4
    note        A_,4,4
    note        B_,4,6
    sound_loop  1,:-
    sound_instrument Ins_EarthBass
    note        D_,3,2
    rest        4
    note        D_,3,2
    rest        4
    note        D_,3,2
    note        D_,3,2
    ; verse 1
    sound_call  .block1
    sound_call  .block2
    sound_call  .block1
    sound_call  .block3
    release     18
    sound_call  .block1
    sound_call  .block2
    sound_call  .block1
    sound_call  .block3
    release     14
    sound_instrument Ins_EarthPulseArp
    sound_set_arp_ptr Arp_EarthOctave
    note        B_,4,4
    ; verse 2
    note        C_,5,10
    note        D_,5,2
    note        E_,5,2
    note        D_,5,10
    note        A_,4,8
    note        B_,4,10
    note        A_,4,2
    note        B_,4,2
    note        E_,4,18
    note        B_,4,10
    note        A_,4,2
    note        B_,4,2
    note        G_,4,12
    note        E_,4,2
    note        G_,4,2
    note        A_,4,12
    note        F#,4,2
    note        A_,4,2
    note        B_,4,10
    sound_instrument Ins_EarthBass
    note        B_,2,2
    note        B_,2,2
    sound_slide_down $40
    wait        4
    ; chorus
:   sound_instrument Ins_EarthLead
    sound_call  .block4
    note        E_,4,4
    release     2
    note        B_,3,2
    note        D_,4,3
    release     1
    note        B_,3,3
    release     1
    note        A_,3,3
    release     1
    note        B_,3,3
    release     1
    note        F#,4,2
    sound_call  .block4
    sound_instrument Ins_EarthLeadLong
    note        E_,4,14
    release     12
    sound_loop  1,:-
    sound_jump  .loop
.block1
    sound_instrument Ins_EarthLead
    note        B_,3,2
    note        E_,4,2
    note        B_,4,7
    release     1
    note        B_,3,2
    note        E_,4,2
    note        B_,4,7
    release     1
    note        B_,4,2
    note        C#,5,2
    note        E_,5,2
    note        D_,5,5
    release     1
    note        B_,4,3
    release     1
    note        B_,4,2
    note        C#,5,2
    note        D_,5,2
    note        C#,5,5
    release     1
    note        A_,4,3
    release     1
    note        A_,4,2
    note        B_,4,2
    note        C#,5,2
    sound_ret
.block2
    note        B_,4,5
    release     1
    note        E_,4,3
    release     5
    sound_instrument Ins_EarthOctaveSoft
    note        A_,4,2
    note        B_,4,2
:   note        E_,4,2
    note        A_,4,2
    note        B_,4,2
    note        E_,4,2
    note        E_,5,2
    note        E_,4,2
    note        A_,4,2
    note        B_,4,2
    sound_loop  2,:-
    sound_ret
.block3
    sound_instrument Ins_EarthLeadLong
    note        B_,4,14
    release     12
    note        A_,4,2
    note        F#,4,2
    note        A_,4,2
    note        B_,4,16
    sound_ret
.block4
    note        G_,4,8
    release     2
    note        F#,4,2
    note        E_,4,3
    release     1
    note        D_,4,3
    release     1
    note        B_,3,3
    release     1
    note        D_,4,3
    release     1
    note        F#,4,3
    release     1
    note        F#,4,4
    release     2
    sound_ret

; ================================================================

Earth_CH3:
    ; intro
.loop
    sound_instrument    Ins_EarthWaveEchoSoft
:   note        B_,4,2
    note        E_,5,2
    note        F#,5,2
    note        B_,4,2
    note        E_,5,2
    note        F#,5,2
    note        B_,4,2
    note        B_,5,2
    sound_loop  11,:-
    sound_instrument    Ins_EarthWaveArp
    sound_set_arp_ptr   Arp_047
    note        D_,6,6
    note        D_,6,6
    note        D_,6,2
    note        D_,6,2
    ; verse 1
:   sound_call  .block1
    sound_call  .block1
    sound_call  .block1
    sound_call  .block2
    sound_loop  1,:-
    ; verse 2
    wait        4
    sound_set_arp_ptr   Arp_047
    note    C_,6,4
    note    C_,6,6
    sound_set_arp_ptr   Arp_037
    note    A_,5,6
    note    A_,5,4
    note    A_,5,4
    note    A_,5,8
    sound_set_arp_ptr   Arp_038
    note    G#,5,4
    note    G#,5,6
    note    G#,5,6
    note    G#,5,4
    sound_set_arp_ptr   Arp_049
    note    A_,5,4
    note    A_,5,8
    sound_set_arp_ptr   Arp_038
    note    B_,5,4
    note    B_,5,6
    note    B_,5,6
    note    B_,5,4
    note    B_,5,4
    note    B_,5,8
    sound_set_arp_ptr   Arp_049
    note    C_,6,4
    note    C_,6,6
    note    D_,6,6
    note    D_,6,4
    note    D_,6,4
    note    D_,6,4
    ; chorus
    sound_instrument    Ins_EarthWaveEcho
:   sound_call  .block3
    sound_call  .block4
    note        A_,5,2
    note        E_,5,2
    note        D_,5,2
    note        A_,5,2
    note        E_,5,2
    note        D_,5,2
    note        B_,4,2
    note        F#,5,2
    sound_call  .block3
    sound_call  .block4
    sound_call  .block4
    sound_loop  1,:-
    sound_jump  .loop
.block1
    wait        4
    sound_set_arp_ptr   Arp_037
    note        E_,6,4
    note        E_,6,6
    note        E_,6,4
    note        E_,6,6
    note        E_,6,4
    note        E_,6,8
    sound_set_arp_ptr   Arp_059
    note        D_,6,4
    note        D_,6,6
    sound_set_arp_ptr   Arp_038
    note        C#,6,4
    note        C#,6,6
    note        C#,6,4
    note        C#,6,4
    sound_ret
.block2
    wait        4
    sound_set_arp_ptr   Arp_057
    note        B_,5,4
    sound_set_arp_ptr   Arp_047
    note        B_,5,6
    sound_set_arp_ptr   Arp_057
    note        B_,5,6
    note        B_,5,4
    note        B_,5,4
    sound_set_arp_ptr   Arp_047
    note        B_,5,8
    sound_set_arp_ptr   Arp_057
    note        B_,5,4
    sound_set_arp_ptr   Arp_047
    note        B_,5,6
    sound_set_arp_ptr   Arp_057
    note        B_,5,6
    note        B_,5,4
    note        B_,5,4
    sound_set_arp_ptr   Arp_047
    note        B_,5,4
    sound_ret
.block3
    note        G_,5,2
    note        F#,5,2
    note        E_,5,2
    note        G_,5,2
    note        F#,5,2
    note        E_,5,2
    note        C_,5,2
    note        F#,5,2
    note        A_,5,2
    note        G_,5,2
    note        F#,5,2
    note        A_,5,2
    note        G_,5,2
    note        F#,5,2
    note        D_,5,2
    note        A_,5,2
    sound_ret
.block4
    note        A_,5,2
    note        G#,5,2
    note        E_,5,2
    note        A_,5,2
    note        G#,5,2
    note        E_,5,2
    note        B_,4,2
    note        E_,5,2
    sound_ret
    
; ================================================================

Earth_CH4:
    ; intro
    sound_call  .block1
    sound_call  .block2
:   sound_call  .block1
    sound_loop  3,:-
    sfixins     Ins_EarthSnare,2
    sfixins     Ins_EarthKick,2
    sfix        2
    sfixins     Ins_EarthSnare,2
    sfixins     Ins_EarthKick,2
    sfix        2
    sfixins     Ins_EarthSnare,2
    sfix        2
    ; verse 1
:   sound_call  .block1
    sound_loop  14,:-
    sound_call  .block2
    ; verse 2
:   sound_call  .block1
    sound_loop  2,:-
    sound_call  .block2
    ; chorus
:   sound_call  .block3
    sfix        2
    sfix        2
    sound_loop  6,:-
    sound_call  .block3
    sfixins     Ins_EarthSnare,2
    sfix        2
    sound_jump  Earth_CH4
.block1
    sfixins     Ins_EarthKick,2
    sfixins     Ins_EarthHat,2
    sfixins     Ins_EarthSnare,2
    sfixins     Ins_EarthHat,2
    sfixins     Ins_EarthKick,2
    sfix        2
    sfixins     Ins_EarthSnare,2
    sfixins     Ins_EarthHat,2
    sfixins     Ins_EarthKick,2
    sfixins     Ins_EarthHat,2
    sfixins     Ins_EarthSnare,2
    sfixins     Ins_EarthKick,2
    sfixins     Ins_EarthHat,2
    sfixins     Ins_EarthKick,2
    sfixins     Ins_EarthSnare,2
    sfixins     Ins_EarthHat,2
    sound_ret
.block2
    sfixins     Ins_EarthKick,2
    sfixins     Ins_EarthHat,2
    sfixins     Ins_EarthSnare,2
    sfixins     Ins_EarthHat,2
    sfixins     Ins_EarthKick,2
    sfix        2
    sfixins     Ins_EarthSnare,2
    sfixins     Ins_EarthHat,2
    sfixins     Ins_EarthKick,2
    sfixins     Ins_EarthHat,2
    sfixins     Ins_EarthSnare,2
    sfixins     Ins_EarthKick,2
    sfixins     Ins_EarthSnare,1
    sfix        1
    sfix        2
    sfix        2
    sfix        1
    sfix        1
    sound_ret
.block3
    sfixins     Ins_EarthKick,2
    sfixins     Ins_EarthHat,2
    sfixins     Ins_EarthHat,2
    sfixins     Ins_EarthHat,2
    sfixins     Ins_EarthSnare,2
    sfixins     Ins_EarthHat,2
    sfixins     Ins_EarthHat,2
    sfixins     Ins_EarthKick,2
    sfixins     Ins_EarthHat,2
    sfixins     Ins_EarthKick,2
    sfixins     Ins_EarthKick,2
    sfixins     Ins_EarthHat,2
    sfixins     Ins_EarthSnare,2
    sfixins     Ins_EarthHat,2
    sound_ret

; ================================================================

Ins_EarthLead:
    dw  Vol_EarthLead,Arp_EarthLead,Pulse_EarthLead,Pitch_EarthLead
    dw  Vol_EarthLeadR,0,0,0

Ins_EarthLeadLong:
    dw  Vol_EarthLead,Arp_EarthLead,Pulse_EarthLead,Pitch_EarthLead
    dw  Vol_EarthLeadLongR,0,0,0

Ins_EarthBass:
    dw  Vol_EarthBass,Arp_EarthBass,Pulse_EarthBass,DSX_DummyPitch
    dw  0,0,0,0

Ins_EarthTom:
    dw  Vol_EarthTom,Arp_EarthTom,Pulse_Square,DSX_DummyPitch
    dw  0,0,0,0

Ins_EarthPulseArp:
    dw  Vol_EarthPulseArp,DSX_DummyTable,Pulse_EarthLead,DSX_DummyPitch
    dw  0,0,0,0

Ins_EarthKick:
    dw  Vol_EarthKick,Arp_EarthKick,Noise_EarthKick,DSX_DummyPitch
    dw  0,0,0,0

Ins_EarthSnare:
    dw  Vol_EarthSnare,Arp_EarthSnare,Noise_EarthSnare,DSX_DummyPitch
    dw  0,0,0,0

Ins_EarthHat:
    dw  Vol_EarthHat,Arp_EarthHat,DSX_DummyTable,DSX_DummyPitch
    dw  0,0,0,0

Ins_EarthWaveEcho:
    dw  Vol_EarthWaveEcho,DSX_DummyTable,Wave_EarthEcho,DSX_DummyPitch
    dw  0,0,0,0

Ins_EarthWaveEchoSoft:
    dw  Vol_EarthWaveEchoSoft,DSX_DummyTable,Wave_EarthEcho,DSX_DummyPitch
    dw  0,0,0,0

Ins_EarthOctaveSoft:
    dw  Vol_EarthOctaveSoft,Arp_EarthOctaveSoft,Pulse_EarthOctaveSoft,DSX_DummyPitch
    dw  0,0,0,0

Ins_EarthWaveArp:
    dw  Vol_EarthWaveArp,DSX_DummyTable,Wave_EarthArp,DSX_DummyPitch
    dw  0,0,0,0

; ================================================================

Vol_EarthLead:
    db  11,10,8,8,7
    db  seq_end

Vol_EarthLeadR:
    db  7,6,5,4,3,3,2,2,2
    db  1,seq_wait,4
    db  0
    db  seq_end

Vol_EarthLeadLongR:
    db  6,seq_wait,9
    db  5,seq_wait,9
    db  4,seq_wait,10
    db  3,seq_wait,11
    db  2,seq_wait,12
    db  1,seq_wait,13
    db  0
    db  seq_end

Vol_EarthBass:
    db  12,10,9,8,7,7,6,6,5
    db  seq_end

Vol_EarthTom:
    db  10,seq_wait,3
    db  5,seq_wait,3
    db  2,seq_wait,3
    db  1,seq_wait,3
    db  0
    db  seq_end

Vol_EarthWaveArp:
    db  $20,seq_wait,4
    db  $40,seq_wait,3
    db  $60,seq_wait,8
    db  $00
    db  $00
    db  $40,seq_wait,4
    db  $60,seq_wait,10
    db  $00,
    db  seq_end

Vol_EarthOctaveSoft:
    db  8,5,2,2,2
    db  1,seq_wait,10
    db  0
    db  seq_end

Vol_EarthOctaveLead:
Vol_EarthPulseArp:
    db  9
    db  8,seq_wait,6
    db  7,seq_wait,6
    db  6,seq_wait,6
    db  5,seq_wait,6
    db  4,seq_wait,6
    db  3
    db  seq_end

Vol_EarthWaveEcho:
    db  $20,seq_wait,4
    db  $80|$40
    db  seq_end

Vol_EarthWaveEchoSoft:
    db  $40,seq_wait,4
    db  $80|$60
    db  seq_end

Vol_EarthKick:
    db  9,8,7,6,5,4,3,2,1,0
    db  seq_end

Vol_EarthSnare:
    db  10,8,7,6,5,4,3,3,2,2,2
    db  1,seq_wait,3
    db  0
    db  seq_end

Vol_EarthHat:
    db  9,6,5,4,3,2,2,1,1,0
    db  seq_end

; ================================================================

Pulse_EarthLead:
Pulse_EarthArp:
Pulse_EarthOctaveLead:
:   db  0,seq_wait,3
    db  1,seq_wait,3
    db  2,seq_wait,3
    db  3,seq_wait,3
    db  seq_loop,(:- -@)-1

Pulse_EarthBass:
    db  2,2,2,1
    db  seq_end

Pulse_Square:
Pulse_EarthTom:
Pulse_EarthOctaveSoft:
    db  2
    db  seq_end

Wave_EarthEcho:
    db  1,seq_end

Wave_EarthArp:
    db  2,seq_end

Noise_EarthKick:
    db  1
Noise_EarthSnare:
    db  1,1
Noise_EarthHat:
    db  0
    db  seq_end

; ================================================================

Arp_EarthLead:
    db  12
    ; fall through
Arp_EarthBass:
    db  12,0
    db  seq_end

Arp_EarthTom:
:   db  $80|23
    db  $80|21
    db  $80|19
    db  $80|17
    db  seq_loop,(:- -@)-1

Arp_EarthOctave:
:   db  12,seq_wait,3
    db  0,seq_wait,3
    db  seq_loop,(:- -@)-1

Arp_EarthOctaveSoft:
:   db  12,12,12
    db  0,0,0
    db  seq_loop,(:- -@)-1

Arp_037:
:   db  0,0,3,3,7,7
    db  seq_loop,(:- -@)-1

Arp_047:
:   db  0,0,4,4,7,7
    db  seq_loop,(:- -@)-1

Arp_057:
:   db  0,0,5,5,7,7
    db  seq_loop,(:- -@)-1

Arp_038:
:   db  0,0,3,3,8,8
    db  seq_loop,(:- -@)-1

Arp_049:
:   db  0,0,4,4,9,9
    db  seq_loop,(:- -@)-1
    
Arp_059:
:   db  0,0,5,5,9,9
    db  seq_loop,(:- -@)-1

; ================================================================

Arp_EarthKick:
    db  26
    db  22
    db  18
    db  14
    db  10
    db  45
    db  seq_end

Arp_EarthSnare:
    db  32
    db  25
    db  17
    db  28
    db  seq_end

Arp_EarthHat:
    db  44
    db  seq_end
    
; ================================================================

Pitch_EarthLead:
    db  14
:   db  1,2,2,1,0
    db  -1,-2,-2,-1,-0
    db  pitch_loop,(:- -@)-1

; ================================================================

    db  "END",0
