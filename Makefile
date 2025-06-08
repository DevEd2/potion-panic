PROJECTNAME=gbcompo25

PYTHON=python3

LEVELFILES:=$(shell find -iname "*.json")

all: *.asm Engine/*.asm GameModes/*.asm Audio/*.asm levels
	rgbasm -o $(PROJECTNAME).obj -p 255 Main.asm
	rgblink -p 255 -o $(PROJECTNAME).gbc -n $(PROJECTNAME).sym $(PROJECTNAME).obj
	rgbfix -v -p 255 $(PROJECTNAME).gbc

levels: $(LEVELFILES)
	cd Levels && $(PYTHON) ../Tools/convertmap.py -c $(subst Levels/,,$<)

clean:
	find . -type f -name "*.gbc" -delete
	find . -type f -name "*.sym" -delete
	find . -type f -name "*.obj" -delete
	find . -type f -wholename "./Levels/*.inc" -delete
	find . -type f -wholename "./Levels/ObjectLayouts*.inc" -delete
	find . -type f -wholename "./Levels/*.bin" -delete
	find . -type f -wholename "./Levels/*.bin.wle" -delete

.PHONY: all