include "Audio/GBMod_Player.asm"
include "Audio/DevSFX.asm"

macro incmus
section "GBMod module: \1",romx[$4000]
Mus_\1: incbin  "Audio/Modules/\1.xm.gbm"
endm

    incmus  LostInTranslation   ; placeholder for title screen music
    incmus  DarkForest
    ; incmus  Candyland
    incmus  Desert
    ; incmus  Winter
    ; incmus  Castle
    incmus  DevEdGames
    incmus  WorldMap