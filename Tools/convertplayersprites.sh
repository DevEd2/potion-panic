#!/bin/sh
cd GFX/Player
for f in *.png; do
	superfamiconv -M gbc -RDF -W 8 -H 16 -i $f -t $f.2bpp
done
