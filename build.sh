#!/bin/sh
set -e
PROJECTNAME=potionpanic
PYTHON=python3
BASEDIR=`pwd`

#echo "Cleaning up previous build files..."
#find . -type f -name "*.gbc" -delete
#find . -type f -name "*.sym" -delete
#find . -type f -name "*.obj" -delete
#find . -type f -wholename "./Levels/*.inc" -delete
#find . -type f -wholename "./Levels/ObjectLayouts/*.inc" -delete
#find . -type f -wholename "./Levels/*.bin" -delete
#find . -type f -wholename "./Levels/*.bin.wle" -delete
#find . -type f -wholename "./Audio/Modules/*.gbm" -delete
#find . -type f -wholename "./GFX/Player/*.2bpp" -delete

echo "Converting maps..."
cd $BASEDIR/Levels
for f in *.json; do
    python3 $BASEDIR/Tools/convertmap.py `basename $f`
done

echo "Converting modules..."
cd $BASEDIR/Audio/Modules
for f in *.xm; do
	python3 $BASEDIR/Tools/xmconv.py $f $f.gbm
done

echo "Converting player sprites..."
cd $BASEDIR/GFX/Player
for f in *.png; do
	superfamiconv -M gbc -RDF -W 8 -H 16 -i $f -t $f.2bpp
done
cd $BASEDIR

echo "Assembling..."
rgbasm -o $PROJECTNAME.obj -p 255 Main.asm -Wno-unmapped-char
echo "Linking..."
rgblink -o $PROJECTNAME.gbc -p 255 -n $PROJECTNAME.sym $PROJECTNAME.obj -Wtruncation=1
echo "Fixing..."
rgbfix -v -p 255 $PROJECTNAME.gbc
echo "Build complete."
