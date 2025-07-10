#!/bin/sh
cd Audio/Modules
for f in *.xm; do
	python3 ../../Tools/xmconv.py $f $f.gbm
done
