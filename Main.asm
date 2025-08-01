; =============================================================================
; Untitled GBCompo 2025 entry
; Copyright (C) 2025 DevEd
;
; This project is licensed under the terms of the MIT License. See the LICENSE
; file in the root directory of this repository for the full license terms.
; =============================================================================

    charmap "©",$a9

    include "hardware.inc/hardware.inc"
		
def BUILD_DEBUG = 1
def STACK_TOP = $d000

def BIT_A           equ 0
def BIT_B           equ 1
def BIT_SELECT      equ 2
def BIT_START       equ 3
def BIT_RIGHT       equ 4
def BIT_LEFT        equ 5
def BIT_UP          equ 6
def BIT_DOWN        equ 7

def BTN_A           equ 1 << BIT_A
def BTN_B           equ 1 << BIT_B
def BTN_START       equ 1 << BIT_START
def BTN_SELECT      equ 1 << BIT_SELECT
def BTN_RIGHT       equ 1 << BIT_RIGHT
def BTN_LEFT        equ 1 << BIT_LEFT
def BTN_UP          equ 1 << BIT_UP
def BTN_DOWN        equ 1 << BIT_DOWN

; =============================================================================

macro bankswitch_to_pointer
    assert warn, \1 > $3fff, "Bankswitchingh is unnecessary for calls to ROM0"
    assert \1 < $7fff, "Bankswitch target outside ROM!"
    ld      a,bank(\1)
    bankswitch_to_a
endm

macro bankswitch_to_a
    ldh     [hROMB0],a
    ld      [rROMB0],a
endm

macro farcall
    bankswitch_to_pointer \1
    call    \1
endm

macro farload
    bankswitch_to_pointer \2
    ld      \1,\2
endm

macro pushbank
    ldh     a,[hROMB0]
    push    af
endm

macro popbank
    pop     af
    ldh     [hROMB0],a
    ld      [rROMB0],a
endm

macro lb
    ld      \1,(\2 * 256) + \3
endm

macro wait_for_vram
:   ldh     a,[rSTAT]
    and     STATF_BUSY
    jr      nz,:-
endm

macro dwbank
    db      bank(\1)
    dw      \1
endm

macro dbw
    db      \1
    dw      \2
endm

macro rgb
    dw      \1 | \2 << 5 | \3 << 10
endm

macro rgb8
    dw (\1 >> 3) | (\2 >> 3) << 5 | (\3 >> 3) << 10
endm

; =============================================================================

section "Reset $00",rom0[$00]
WaitForVBlank: jp _WaitForVBlank

section "Reset $08",rom0[$08]
WaitForSTAT: jp _WaitForSTAT

section "Reset $10",rom0[$10]
CallHL:
    bit     7,h
    jr      nz,CallHL_Error
    jp      hl

section "Reset $18",rom0[$18]
Reset18: ret

section "Reset $20",rom0[$20]
Reset20: ret

section "Reset $28",rom0[$28]
Reset28: ret

section "Reset $30",rom0[$30]
Reset30: ret

section "Reset $38",rom0[$38]
Reset38:
    jr      _Reset38
    
; =============================================================================

section "VBlank interrupt vector",rom0[$40]
IRQ_VBlank: jp DoVBlank

section "LCD status interrupt vector",rom0[$48]
IRQ_STAT:   jp DoSTAT

section "Timer interrupt vector",rom0[$50]
IRQ_Timer:  jp DoTimer

section "Serial interrupt vector",rom0[$58]
IRQ_Serial: reti

section "Joypad interrupt vector",rom0[$60]
IRQ_Joypad: reti

; =============================================================================

CallHL_Error:
    push    af
    ld      a,ERR_JP_HL_OUTSIDE_ROM
    ldh     [hErrType],a
    pop     af
    jp      ErrorScreen

_Reset38:
    push    af
    ld      a,ERR_TRAP
    ldh     [hErrType],a
    pop     af
    jp      ErrorScreen

; =============================================================================

section "ROM header",rom0[$100]
Header_EntryPoint:  
    jr  ProgramStart                                    ;
    ds  2,0                                             ; padding
Header_NintendoLogo:    ds  48,0                        ; handled by rgbfix
Header_Title:           db  "POTION PANIC"              ; must be 15 chars or less!
                        ds  (Header_Title + 15) - @,0   ; padding
Header_GBCSupport:      db  CART_COMPATIBLE_GBC         ;
Header_NewLicenseCode:  dw  0                           ; not needed
Header_SGBSupport:      db  $00                         ; $03 = enable SGB features (requires old license code to be set to $33)
Header_CartridgeType:   db  CART_ROM_MBC5_RUMBLE        ; 
Header_ROMSize:         ds  1                           ; handled by rgbfix
Header_RAMSize:         db  0                           ; not used
Header_DestinationCode: db  1                           ; 0 = Japan, 1 = not Japan
Header_OldLicenseCode:  db  $33                         ; must be $33 for SGB support
Header_Revision:        db  -1                          ; revision (-1 for prerelease builds)
Header_Checksum:        db  0                           ; handled by rgbfix
Header_ROMChecksum:     dw  0                           ; handled by rgbfix

; =============================================================================

section fragment "Program code",rom0[$150]
ProgramStart:
    di
    ld      sp,STACK_TOP
    ldh     [hIsGBC],a
    cp      $11
    jr      z,.gbc
    ld      a,c
    sub     $13
    jr      :+
.gbc
    xor     a
:   ldh     [hIsSGB],a
    ld      a,b
    ld      [hIsGBA],a
        
    ; initialize interrupt pointers
    ld      a,low(Int_Dummy)
    ldh     [hVBlankPointer],a
    ldh     [hSTATPointer],a
    ldh     [hTimerPointer],a
    ld      a,high(Int_Dummy)
    ldh     [hVBlankPointer+1],a
    ldh     [hSTATPointer+1],a
    ldh     [hTimerPointer+1],a
    
    ; clear OAM
    ld      hl,OAMBuffer
    ld      b,40*4
    xor     a
    ldh     [hOAMPos],a
    call    MemFillSmall
    
    ; copy OAM DMA routine
    ld      hl,_OAMDMA
    lb      bc,SIZEOF_OAMDMA,low(hOAMDMA)
:   ld      a,[hl+]
    ldh     [c],a
    inc     c
    dec     b
    jr      nz,:-
    
    call    hOAMDMA
    
    ; GBC check
    ldh     a,[hIsGBC]
    cp      $11
    jr      nz,@ ; TODO: Lockout screen
    ; Very Bad Amulator™ check
    ld      a,5
    add     a
    daa
    push    af
    pop     hl
    bit     5,l
    jr      nz,@ ; TODO: Lockout screen
    
    ; enable double speed mode
    xor     a
    ldh     [rIE],a
    ld      a,$30
    ldh     [rP1],a
    ld      a,1
    ldh     [rKEY1],a
    stop
    
    call    GBM_Stop
    
    xor     a
    
    ldh     [hPressedButtons],a
    ldh     [hHeldButtons],a
    ldh     [hReleasedButtons],a
    ldh     [hGlobalTick],a
    ld      [Level_ID],a
    ld      [Level_CameraX],a
    ld      [Level_CameraY],a
    
    call    Math_InitRandSeed
    
    jp      GM_Debug
    
    jr      @

; =============================================================================
; Support routines
; =============================================================================
    
; print a null-terminated string to DE
; INPUT: hl = pointer
;        de = destination
PrintString:
    ld      a,[hl+]
    and     a
    ret     z
    sub     " "
    ld      [de],a
    inc     de
    jr      PrintString
    
; print an FF-terminated string to DE
; INPUT: hl = pointer
;        de = destination
PrintString2:
    ld      a,[hl+]
    cp      -1
    ret     z
    sub     " "
    ld      [de],a
    inc     de
    jr      PrintString2

; print a null-terminated color inverted string to DE
; INPUT: hl = pointer
;        de = destination
PrintStringInverted:
    ld      a,[hl+]
    and     a
    ret     z
    sub     " "
    set     7,a
    ld      [de],a
    inc     de
    jr      PrintStringInverted

; Print hexadecimal number B at DE
; INPUT:  a = number
;        de = destination
PrintHex:
    ld      b,a
    swap    a
    and     $f
    cp      $a
    jr      nc,:+
    add     "0"-" "
    jr      :++
:   add     "A"-" "-$a
:   ld      [de],a
    inc     e
    ld      a,b
    and     $f
    cp      $a
    jr      nc,:+
    add     "0"-" "
    jr      :++
:   add     "A"-" "-$a
:   ld      [de],a
    inc     e
    ret

; INPUT: hl = source
;        de = destination
;        bc = size
CopyTiles1BPP:
    ld      a,[hl+]
    ld      [de],a
    inc     de
    ld      [de],a
    inc     de
    dec     bc
    ld      a,b
    or      c
    jr      nz,CopyTiles1BPP
    ret

CopyTiles1BPPLight:
    ld      a,[hl+]
    ld      [de],a
    inc     de
    inc     de
    dec     bc
    ld      a,b
    or      c
    jr      nz,CopyTiles1BPPLight
    ret


CopyTiles1BPPDark:
    ld      a,[hl+]
    inc     de
    ld      [de],a
    inc     de
    dec     bc
    ld      a,b
    or      c
    jr      nz,CopyTiles1BPPDark
    ret

CopyTiles1BPPInverted:
    ld      a,[hl+]
    cpl
    ld      [de],a
    inc     de
    ld      [de],a
    inc     de
    dec     bc
    ld      a,b
    or      c
    jr      nz,CopyTiles1BPPInverted
    ret
    
; INPUT: hl = source
;        de = destination
;        bc = dimensions (b = x, c = y)
LoadTilemap:
    push    bc
.loop
    ld      a,[hl+]
    ld      [de],a
    inc     de
    dec     b
    jr      nz,.loop
    pop     bc
    dec     c
    ret     z
    push    hl
    ld      a,e
    and     %11100000
    ld      e,a
    ld      hl,$20
    add     hl,de
    ld      d,h
    ld      e,l
    pop     hl
    push    bc
    jr      .loop

; INPUT: hl = source
;        de = destination
;        bc = dimensions (b = x, c = y)
LoadTilemapAttr:
    push    bc
.loop
    xor     a
    ldh     [rVBK],a
    ld      a,[hl+]
    ld      [de],a
    ld      a,1
    ldh     [rVBK],a
    ld      a,[hl+]
    ld      [de],a
    inc     de
    dec     b
    jr      nz,.loop
    pop     bc
    dec     c
    jr      z,.done
    push    hl
    ld      a,e
    and     %11100000
    ld      e,a
    ld      hl,$20
    add     hl,de
    ld      d,h
    ld      e,l
    pop     hl
    push    bc
    jr      .loop
.done
    xor     a
    ldh     [rVBK],a
    ret

; INPUT: hl = source
;        de = destination
;        bc = dimensions (b = x, c = y)
LoadBackgroundMap:
    push    bc
    push    de
    xor     a
    ldh     [rVBK],a
    push    bc
.loop
:   ldh     a,[rSTAT]
    and     STATF_BUSY
    jr      nz,:-
    ld      a,[hl+]
    add     $80
    ld      [de],a
    inc     de
    dec     b
    jr      nz,.loop
    pop     bc
    dec     c
    jr      z,.attr
    push    bc
    jr      .loop
.attr
    pop     de
    pop     bc
    ld      a,1
    ldh     [rVBK],a
    push    bc
.loop2
:   ldh     a,[rSTAT]
    and     STATF_BUSY
    jr      nz,:-
    ld      a,[hl+]
    inc     a   ; HACK
    ld      [de],a
    inc     de
    dec     b
    jr      nz,.loop2
    pop     bc
    dec     c
    ret     z
    push    bc
    jr      .loop2
    ret
    
; INPUT: hl = destination
;         e = fill byte
;        bc = size   
MemFill:
    ld      [hl],e
    inc     hl
    dec     bc
    ld      a,b
    or      c
    jr      nz,MemFill
    ret

; INPUT: hl = destination
;         a = fill byte
;         b = size
MemFillSmall:
    ld      [hl+],a
    dec     b
    jr      nz,MemFillSmall
    ret

; INPUT: hl = source
;        de = destination
;        bc = size
MemCopy:
    ld      a,[hl+]
    ld      [de],a
    inc     de
    dec     bc
    ld      a,b
    or      c
    jr      nz,MemCopy
    ret

MemCopySafe:
    ldh     a,[rSTAT]
    and     STATF_BUSY
    jr      nz,MemCopySafe
:   ld      a,[hl+]
    ld      [de],a
    inc     de
    dec     bc
    ld      a,b
    or      c
    jr      nz,MemCopy
    ret

; INPUT: hl = source
;        de = destination
;        b = size
MemCopySmall:
    ld      a,[hl+]
    ld      [de],a
    inc     de
    dec     b
    jr      nz,MemCopySmall
    ret

MemCopySmallSafe:
    ldh     a,[rSTAT]
    and     STATF_BUSY
    jr      nz,MemCopySmallSafe
:   ld      a,[hl+]
    ld      [de],a
    inc     de
    dec     b
    jr      nz,MemCopySmall
    ret

LCDOff:
    ldh     a,[rLCDC]
    bit     7,a
    ret     z
:   ldh     a,[rSTAT]
    and     STATF_VBL
    jr      z,:-
    xor     a
    ldh     [rLCDC],a
    ret

; WARNING: Assumes LCD is off!
ClearScreen:
    ld      a,1
    ldh     [rVBK],a
    ld      hl,_VRAM
    ld      bc,_SRAM-_VRAM
    push    hl
    push    bc
    ld      e,0
    call    MemFill
    xor     a
    ldh     [rVBK],a
    pop     bc
    pop     hl
    call    MemFill
    ld      hl,OAMBuffer
    ld      b,OAMBuffer.end-OAMBuffer
    call    MemFillSmall
    ; clear palettes
    ld      hl,sys_BGPalettes
    ld      b,(sys_ObjPalettes-sys_BGPalettes)*2
    dec     a
    call    MemFillSmall
    call    CopyPalettes
    jp      UpdatePalettes

_OAMDMA: ; copied to HRAM on boot
    ld      a,high(OAMBuffer)
    ldh     [rDMA],a
    ; wait 160 cycles for transfer to complete
    ld      a,160/4
:   dec     a
    jr      nz,:-
    ret
def SIZEOF_OAMDMA = @-_OAMDMA

; ================================================================

_WaitForVBlank:
:   halt
    ldh     a,[hVBlankFlag]
    and     a
    jr      z,:-
    xor     a
    ldh     [hVBlankFlag],a
    ret

_WaitForSTAT:
:   halt
    ldh     a,[hSTATFlag]
    and     a
    jr      z,:-
    xor     a
    ldh     [hSTATFlag],a
    ret

_WaitForTimer:
:   halt
    ldh     a,[hTimerFlag]
    and     a
    jr      nz,:-
    xor     a
    ldh     [hTimerFlag],a
    ret

DoVBlank:
    push    af
    push    hl
    ld      hl,hVBlankPointer
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    rst     CallHL
    ld      a,1
    ldh     [hVBlankFlag],a
    pop     hl    
    pop     af
    reti

DoSTAT:
    push    af
    push    hl
    ld      hl,hSTATPointer
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    rst     CallHL
    ld      a,1
    ldh     [hSTATFlag],a
    pop     hl
    pop     af
    reti

DoTimer:
    push    af
    push    hl
    ld      hl,hTimerPointer
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    rst     CallHL
    ld      a,1
    ldh     [hTimerFlag],a
    pop     hl
    pop     af
    reti


; Actual interrupt routines.
; Use IntV for vblank, IntS for STAT, and IntT for timer.
; BC and DE need to be preserved.
IntV_Dummy:
IntS_Dummy:
IntT_Dummy:
Int_Dummy:
    ret

IntV_Default:
    push    bc
    push    de
    ; do OAM DMA
    call    hOAMDMA
    ; get input
    ld      a,[hHeldButtons]
    ld      c,a
    ld      a,P1F_5
    ldh     [rP1],a
    ldh     a,[rP1]
    ldh     a,[rP1]
    cpl
    and     $f
    swap    a
    ld      b,a
    ld      a,P1F_4
    ldh     [rP1],a
    ldh     a,[rP1]
    ldh     a,[rP1]
    ldh     a,[rP1]
    ldh     a,[rP1]
    ldh     a,[rP1]
    ldh     a,[rP1]
    cpl
    and     $f
    or      b
    ld      b,a
    ld      a,[hHeldButtons]
    xor     b
    and     b
    ld      [hPressedButtons],a     ; store buttons pressed this frame
    ld      e,a
    ld      a,b
    ld      [hHeldButtons],a        ; store held buttons
    xor     c
    xor     e
    ld      [hReleasedButtons],a    ; store buttons released this frame
    ld      a,P1F_5|P1F_4
    ld      [rP1],a
    ; clear OAM
    ld      hl,OAMBuffer
    ld      b,40*4
    xor     a
    call    MemFillSmall
    ld      hl,hGlobalTick
    inc     [hl]
    pop     de
    pop     bc
    ret

; =============================================================================

include "Engine/Math.asm"
include "Engine/Canvas.asm"
include "Engine/PerFade.asm"
include "Engine/Metatile.asm"
include "Engine/WLE_Decode.asm"
include "Engine/Object.asm"

; =============================================================================

include "GameModes/DebugMenu.asm"
include "GameModes/CanvasTest.asm"
include "GameModes/Level.asm"
include "GameModes/TitleScreen.asm"
include "GameModes/Credits.asm"

; =============================================================================

include "Engine/ErrorHandler.asm"

; =============================================================================

include "Audio/Audio.asm"

; =============================================================================

Font:   incbin  "GFX/font.1bpp"
.end

; =============================================================================

section "OAM buffer",wram0,align[8]
OAMBuffer:  ds  40*4
.end
section "System variables",hram[$ff80]

hOAMDMA:        	ds SIZEOF_OAMDMA
def hOAMPage        equ hOAMDMA + 1
hOAMPos:            db
hROMB0:         	db

hHeldButtons:   	db
hPressedButtons:    db
hReleasedButtons:	db

hGlobalTick:        db

hVBlankFlag:    	db
hSTATFlag:      	db
hTimerFlag:         db
hVBlankPointer:     dw
hSTATPointer:       dw
hTimerPointer:      dw

hTempPtr1:          dw
hTempPtr2:          dw
hTemp1:             db
hTemp2:             db
hTemp3:             db
hTemp4:             db

hIsGBC:             db ; $01 if on GBC or GBA, $00 otherwise
hIsGBA:             db ; $01 if on GBC, $FF if on DMG0, otherwise $00
hIsSGB:             db ; $01 if on SGB, otherwise $00
