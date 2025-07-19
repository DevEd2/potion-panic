include "Audio/GBMod_Player.asm"


section "GBMod module: Lost In Translation",romx[$4000]
Mus_LostInTranslation:
    incbin  "Audio/Modules/LostInTranslation.xm.gbm"

section "GBMod module: Dark Forest",romx[$4000]
Mus_DarkForest:
    incbin  "Audio/Modules/DarkForest.xm.gbm"
