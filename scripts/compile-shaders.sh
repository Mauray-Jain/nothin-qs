#!/bin/sh
# Compile every shell/shaders/*.frag to a .qsb next to it.
# --qsbversion 64 keeps the files loadable on Qt 6.4 and newer.
# Needs qsb from qt6-shadertools (development only). Usage: scripts/compile-shaders.sh [OUTDIR]
set -e
QSB=${QSB:-$(command -v qsb || echo /usr/lib/qt6/bin/qsb)}
cd "$(dirname "$0")/../shell/shaders"
out=${1:-.}
for f in *.frag; do
	"$QSB" --qt6 --qsbversion 64 -o "$out/$f.qsb" "$f"
done
