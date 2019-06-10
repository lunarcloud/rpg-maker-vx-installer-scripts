#!/bin/bash
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

TITLE_UPPER=$(grep 'Title' "$GAMEFOLDER"/Game.ini | cut -d'=' -f 2 | tr -d '\n' | tr -d '\r')
TITLE_LOWER=$(echo $TITLE_UPPER  | tr '[:upper:]' '[:lower:]')
TITLE_LOWER_UNDERSCORE=$(echo $TITLE_LOWER  | sed -e 's/ /_/g' | sed -e 's/\.//g')
TITLE_LOWER_DASH=$(echo $TITLE_LOWER  | sed -e 's/ /-/g' | sed -e 's/\.//g')

COMPANY_UPPER=$(grep 'Company' $DATA_DIR/gameinfo.conf | cut -d'=' -f 2- | tr -d '\n' | tr -d '\r')
COMPANY_LOWER=$(echo $COMPANY_UPPER  | tr '[:upper:]' '[:lower:]')
COMPANY_LOWER_UNDERSCORE=$(echo $COMPANY_LOWER  | sed -e 's/ /_/g')
COMPANY_LOWER_DASH=$(echo $COMPANY_LOWER  | sed -e 's/ /-/g')

ID=$(grep 'Id' $DATA_DIR/gameinfo.conf | cut -d'=' -f 2 | tr -d '\n' | tr -d '\r' | tr -d '[:space:]')
VERSION=$(grep 'Version' $DATA_DIR/gameinfo.conf | cut -d'=' -f 2 | tr -d '\n' | tr -d '\r')
SHORT_DESCRIPTION=$(grep 'Description' $DATA_DIR/gameinfo.conf | cut -d'=' -f 2 | tr -d '\n' | tr -d '\r')
DESCRIPTION=$(sed -n '/Description/,$p' $DATA_DIR/gameinfo.conf | cut -d'=' -f 2- | sed ':a;N;$!ba;s/\n/\\n/g;s/	/ /g')
MAINTANER=$(grep 'Maintainer' $DATA_DIR/gameinfo.conf | cut -d'=' -f 2 | tr -d '\n' | tr -d '\r')
HOMEPAGE=$(grep 'Homepage' $DATA_DIR/gameinfo.conf | cut -d'=' -f 2 | tr -d '\n' | tr -d '\r')

PACKAGENAME="$COMPANY_LOWER_DASH"-"$TITLE_LOWER_DASH"
EXECUTABLENAME="$TITLE_LOWER_DASH"

# TODO create the $ID.json file
cp "$CURRENT_DIR/flatpak.example.json" "$CURRENT_DIR/$ID.json"


echo "TODO"
exit 9001
flatpak-builder --bundle-sources --force-clean --repo=flatpak app $ID.json #--filesystem=~/.$ID
flatpak build-bundle flatpak $ID.flatpak $ID
rm -r flatpak
