rsreset
def SFX_JUMP_NORMAL rb
def SFX_JUMP_TINY   rb
def SFX_JUMP_FAT    rb
def SFX_MENU_CURSOR rb

DSFX_SFXPointers:
    dw  SFX_JumpNormal
    dw  SFX_JumpTiny
    dw  SFX_JumpFat
    dw  SFX_MenuCursor
    
    include "Audio/SFX/MenuCursor.asm"
    include "Audio/SFX/JumpNormal.asm"
    include "Audio/SFX/JumpTiny.asm"
    include "Audio/SFX/JumpFat.asm"