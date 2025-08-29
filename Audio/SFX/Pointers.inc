rsreset
def SFX_JUMP_NORMAL     rb
def SFX_JUMP_TINY       rb
def SFX_JUMP_FAT        rb
def SFX_MENU_CURSOR     rb
def SFX_PAUSE_CH1       rb
def SFX_PAUSE_CH2       rb
def SFX_PAUSE_CH3       rb
def SFX_BIG_BUMP_CH2    rb
def SFX_BIG_BUMP_CH4    rb
def SFX_GET_FAT         rb
def SFX_MENU_SELECT_CH2 rb
def SFX_MENU_SELECT_CH1 rb
def SFX_HURT            rb
def SFX_BELLY_BUMP_CH2  rb
def SFX_BELLY_BUMP_CH4  rb

DSFX_SFXPointers:
    dw  SFX_JumpNormal
    dw  SFX_JumpTiny
    dw  SFX_JumpFat
    dw  SFX_MenuCursor
    dw  SFX_PauseCH1
    dw  SFX_PauseCH2
    dw  SFX_PauseCH3
    dw  SFX_BigBump_CH2
    dw  SFX_BigBump_CH4
    dw  SFX_GetFat
    dw  SFX_MenuSelect_CH2
    dw  SFX_MenuSelect_CH1
    dw  SFX_Hurt
    dw  SFX_BellyBump_CH2
    dw  SFX_BellyBump_CH4
    
    include "Audio/SFX/MenuCursor.asm"
    include "Audio/SFX/JumpNormal.asm"
    include "Audio/SFX/JumpTiny.asm"
    include "Audio/SFX/JumpFat.asm"
    include "Audio/SFX/PauseCH1.asm"
    include "Audio/SFX/PauseCH2.asm"
    include "Audio/SFX/PauseCH3.asm"
    include "Audio/SFX/BigBump_CH2.asm"
    include "Audio/SFX/BigBump_CH4.asm"
    include "Audio/SFX/GetFat.asm"
    include "Audio/SFX/MenuSelect.asm"
    include "Audio/SFX/Hurt.asm"
    include "Audio/SFX/BellyBump_CH2.asm"
    include "Audio/SFX/BellyBump_CH4.asm"