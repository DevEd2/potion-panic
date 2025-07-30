Credits_RoleList:
    db  $01,$00 ; header
    db  $02,$03,$04,$05,$06 ; everything I did
    db  $07,$07,$07,$07 ; fonts
    db  $09,$09,$09,$09,$09,$09,$09,$09,$09 ; greets
    db  $08,$08,$08,$08,$08,$08 ; special thanks
    db  $0A ; thanks for playing
    db  $0B ; copyright
    db  $00,$ff ; loopback

Credits_NameList:
    db  $00,$15 ; intro
    db  $01,$01,$01,$01,$01 ; everything I did
    db  $02,$03,$04,$17 ; fonts
    db  $0b,$0c,$0d,$0e,$0f,$10,$11,$12,$13 ; greets
    db  $05,$06,$07,$08,$09,$0a,$16 ; special thanks
    db  $14 ; thanks for playing
    db  $15 ; copyright
    db  $15,$ff ; loopback

Credits_Roles:
    db      "                    " ; 00
    db      "    POTION PANIC    " ; 01
    db      "DESIGN:             " ; 02
    db      "PROGRAMMING:        " ; 03
    db      "MUSIC:              " ; 04
    db      "SFX:                " ; 05
    db      "GRAPHICS:           " ; 06
    db      "FONTS:              " ; 07
    db      "SPECIAL THANKS:     " ; 08
    db      "GREETINGS:          " ; 09
    db      "     THANKS FOR     " ; 0A
    db      "    © 2025 DEVED    " ; 0B

Credits_People:
    db      "   A GAME BY DEVED  " ; 00 Intro
    db      "               DEVED" ; 01 Design, programming, music, SFX, graphics
    db      "        DAMIEN GUARD" ; 02 Fonts - https://damieng.com/typography/zx-origins/zx-gona/
    db      "       DAMIEN GOSSET" ; 03 Fonts - https://www.dafont.com/8-bitanco.font
    db      "        KERRI SHOTTS" ; 04 Fonts - https://fontstruct.com/fontstructions/show/1208100/16-bit-7x9-nostalgia
    db      "   COLLIN VAN GINKEL" ; 05 Special thanks
    db      "            CALINDRO" ; 06 Special thanks
    db      "     MARTIJN WENTING" ; 07 Special thanks
    db      "      FARIED VERHEUL" ; 08 Special thanks
    db      "    ALBERTO GONZALEZ" ; 09 Special thanks
    db      "     HIROKAZU TANAKA" ; 0A Special thanks
    db      "                AYCE" ; 0B Greets
    db      "            WITCHBIZ" ; 0C Greets
    db      "            SNORPUNG" ; 0D Greets
    db      "            PHANTASY" ; 0E Greets
    db      "                CNCD" ; 0F Greets
    db      "  BATTLE OF THE BITS" ; 10 Greets
    db      "           FAIRLIGHT" ; 11 Greets
    db      "               TITAN" ; 12 Greets
    db      "              DALTON" ; 13 Greets
    db      "      PLAYING!      " ; 14 Thanks for playing
    db      "                    " ; 15 Copyright
    db      "          ...AND YOU" ; 16 Speical thanks
    db      "        FONT END DEV" ; 17 Fonts - https://fontenddev.com/fonts/grape-soda/
