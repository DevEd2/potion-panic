rsreset
def SFX_JUMP_NORMAL rb
def SFX_JUMP_TINY   rb
def SFX_JUMP_FAT    rb
def SFX_MENU_CURSOR rb
def SFX_PAUSE_CH1   rb
def SFX_PAUSE_CH2   rb
def SFX_PAUSE_CH3   rb

DSFX_SFXPointers:
    dw  SFX_JumpNormal
    dw  SFX_JumpTiny
    dw  SFX_JumpFat
    dw  SFX_MenuCursor
    dw  SFX_PauseCH1
    dw  SFX_PauseCH2
    dw  SFX_PauseCH3
    
    include "Audio/SFX/MenuCursor.asm"
    include "Audio/SFX/JumpNormal.asm"
    include "Audio/SFX/JumpTiny.asm"
    include "Audio/SFX/JumpFat.asm"
    include "Audio/SFX/PauseCH1.asm"
    include "Audio/SFX/PauseCH2.asm"
    include "Audio/SFX/PauseCH3.asm"