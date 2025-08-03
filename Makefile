PROJECTNAME=potionpanic

PYTHON=python3

LEVELFILES:=$(shell find -iname "*.json")
MODULEFILES:=$(shell find -iname "*.xm")
PLAYERSPRITEFILES:=$(shell find -iwholename "./GFX/Player/*.png")

all: *.asm Engine/*.asm GameModes/*.asm Audio/*.asm levels modules playersprites
	rgbasm -o $(PROJECTNAME).obj -p 255 Main.asm -Wno-unmapped-char
	rgblink -p 255 -o $(PROJECTNAME).gbc -n $(PROJECTNAME).sym $(PROJECTNAME).obj
	rgbfix -v -p 255 $(PROJECTNAME).gbc

levels:
	cd Levels
	for f in *.json; do
		python3 ../Tools/convertmap.py -c $f
	done

modules:
	cd Audio/Modules
	for f in *.xm; do
		python3 ../../Tools/xmconv.py $f $f.gbm
	done

playersprites:
	cd GFX/Player
	for f in *.png; do
		superfamiconv -M gbc -RDF -W 8 -H 16 -i $f -t $f.2bpp
	done

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

.PHONY: all
