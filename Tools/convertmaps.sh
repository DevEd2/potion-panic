#!/bin/sh
cd Levels
for f in *.json; do
	python3 ../Tools/convertmap.py -c $f
done
