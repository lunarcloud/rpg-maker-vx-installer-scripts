#!/bin/sh
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ ! -e "$CURRENT_DIR"/mkxp-20180121 ]]; then
	if [[ ! -e "$CURRENT_DIR"/mkxp-20180121.tar.xz ]]; then
		wget http://ancurio.bplaced.net/mkxp/generic/mkxp-20180121.tar.xz -P "$CURRENT_DIR"/
	fi
    tar xf "$CURRENT_DIR"/mkxp*.tar.xz
fi

if [[ $# -eq 0 ]] ; then
    DATA_DIR="."
else
    DATA_DIR="$1"
    ARCH="$2"
fi

if [ "$ARCH" != "32" ] && [ "$ARCH" != "64" ] && [ "$ARCH" != "both" ]; then
    ARCH="both"
fi

# Get Variables
GAMEFOLDER=$(find "$DATA_DIR" ! -path "*_i386*" ! -path "*_amd64/*" ! -path "*.app*" ! -path "*.App*" -name 'Game.exe' -printf '%h\n' | sort -ur | tr -d '\n' | tr -d '\r')

if [[ ! -d "$GAMEFOLDER" ]]; then
    echo "No game folder found inside \"$DATA_DIR\""
    exit 31;
fi

ID=$(grep 'Id' $DATA_DIR/gameinfo.conf | cut -d'=' -f 2 | tr -d '\n' | tr -d '\r' | tr -d '[:space:]')

# TODO create the $ID.json file

flatpak-builder --bundle-sources --force-clean --repo=repo app $ID.json #--filesystem=~/.$ID
flatpak build-bundle repo $ID.flatpak $ID
rm -r repo app
