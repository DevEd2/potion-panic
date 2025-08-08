rsreset
def SFX_MENU_CURSOR rb
def SFX_MENU_SELECT rb

DSFX_SFXPointers:
    dw  SFX_MenuCursor
    
    include "Audio/SFX/MenuCursor.asm"