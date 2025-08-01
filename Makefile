PROJECTNAME=gbcompo25

PYTHON=python3

LEVELFILES:=$(shell find -iname "*.json")
MODULEFILES:=$(shell find -iname "*.xm")
PLAYERSPRITEFILES:=$(shell find -iwholename "./GFX/Player/*.png")

all: *.asm Engine/*.asm GameModes/*.asm Audio/*.asm levels modules playersprites
	rgbasm -o $(PROJECTNAME).obj -p 255 Main.asm -Wno-unmapped-char
	rgblink -p 255 -o $(PROJECTNAME).gbc -n $(PROJECTNAME).sym $(PROJECTNAME).obj
	rgbfix -v -p 255 $(PROJECTNAME).gbc

levels:
	./Tools/convertmaps.sh

modules:
	./Tools/convertmodules.sh
    
playersprites:
	./Tools/convertplayersprites.sh

clean:
	find . -type f -name "*.gbc" -delete
	find . -type f -name "*.sym" -delete
	find . -type f -name "*.obj" -delete
	find . -type f -wholename "./Levels/*.inc" -delete
	find . -type f -wholename "./Levels/ObjectLayouts/*.inc" -delete
	find . -type f -wholename "./Levels/*.bin" -delete
	find . -type f -wholename "./Levels/*.bin.wle" -delete
	find . -type f -wholename "./Audio/Modules/*.gbm" -delete
	find . -type f -wholename "./GFX/Player/*.2bpp" -delete

.PHONY: all playersprites
