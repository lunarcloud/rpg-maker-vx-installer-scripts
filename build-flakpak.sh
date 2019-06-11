#!/bin/bash
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

exit 32 # TODO

MKXP_PATH=mkxp-20180121
if [[ ! -e "$CURRENT_DIR"/$MKXP_PATH ]]; then
	if [[ ! -e "$CURRENT_DIR"/$MKXP_PATH.tar.xz ]]; then
		wget http://ancurio.bplaced.net/mkxp/generic/$MKXP_PATH.tar.xz -P "$CURRENT_DIR"/
	fi
    tar xf "$CURRENT_DIR"/$MKXP_PATH.tar.xz
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
GAMEFOLDER=$(find "$DATA_DIR" ! -path "*_i386*" ! -path "*_amd64/*" ! -path "*.app*" ! -path "*.App*" ! -path "*flatpak/*" ! -path "*gamedir/*" -name 'Game.exe' -printf '%h\n' | sort -ur | tr -d '\n' | tr -d '\r')

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
RELATIVEDIR="/opt/$PACKAGENAME"

# Copy game files to build path
GAMETAR="$CURRENT_DIR/gamedir.tar"
rm -r "$GAMETAR"
tar -cf "$GAMETAR" "$GAMEFOLDER"

# Create game launcher script
echo "Creating game launcher script..."
cp "$CURRENT_DIR/"game.sh "$CURRENT_DIR/"game.sh.temp
`sed -i "s|APPDIR=\(.*\)|APPDIR=$HOME/.local/share/$PACKAGENAME/|" "$CURRENT_DIR/"game.sh.temp`

# Create temp desktop file
echo "Creating desktop file..."
cp "$CURRENT_DIR/"app.desktop "$CURRENT_DIR/"app.desktop.temp
`sed -i "s/Comment=\(.*\)/Comment=$( echo "$SHORT_DESCRIPTION" | sed -e 's/\./\\\./g')/" "$CURRENT_DIR/"app.desktop.temp`
`sed -i "s/Name=\(.*\)/Name=$TITLE_UPPER/"  "$CURRENT_DIR/"app.desktop.temp`
`sed -i "s/Exec=\(.*\)/Exec=\/opt\/"$PACKAGENAME"\/game.sh/"  "$CURRENT_DIR/"app.desktop.temp`
`sed -i "s/Path=\(.*\)/Path=\/opt\/"$PACKAGENAME"\//"  "$CURRENT_DIR/"app.desktop.temp`
`sed -i "s/Icon=\(.*\)/Icon=\/opt\/"$PACKAGENAME"\/$(echo "$ID" | sed -e 's/\./\\\./g').png/"  "$CURRENT_DIR/"app.desktop.temp`

# Icons
mkdir -p "$CURRENT_DIR/icons"
cp "$DATA_DIR/game.png" "$CURRENT_DIR/icons/$ID.png"
SIZES=( "128" "256" "512")
for SIZE in "${SIZES[@]}"; do
	convert "$DATA_DIR/game.png" -resize ${SIZE}x${SIZE} "$CURRENT_DIR/icons/${SIZE}x${SIZE}.png"
done

#if [ -f "$DATA_DIR/license.txt" ]; then
#    cp "$DATA_DIR/license.txt" "$CURRENT_DIR/LICENSE"
#fi

# Create the $ID.json file
echo "Creating flatpak json..."
cp "$CURRENT_DIR/flatpak.example.json" "$CURRENT_DIR/$ID.json"
`sed -i "s/com\.mycompany\.MyGame/$(echo "$ID" | sed -e 's/\./\\\./g')/" "$CURRENT_DIR/$ID.json"`
RELATIVEDIR_ESCAPED=$(echo "$RELATIVEDIR" | sed -e 's/\./\\\./g' | sed -e 's/\//\\\//g')
`sed -i "s/relativepath/$RELATIVEDIR_ESCAPED/" "$CURRENT_DIR/$ID.json"`
CURRENT_DIR_ESCAPED=$(echo "$CURRENT_DIR" | sed -e 's/\./\\\./g' | sed -e 's/\//\\\//g')
`sed -i "s/currentpath/$CURRENT_DIR_ESCAPED/g" "$CURRENT_DIR/$ID.json"`
ICON_DIR_ESCAPED=$(echo "$CURRENT_DIR/icons" | sed -e 's/\./\\\./g' | sed -e 's/\//\\\//g')
`sed -i "s/iconspath/$ICON_DIR_ESCAPED/g" "$CURRENT_DIR/$ID.json"`

function createFlatpak() {
    ARCH=$1
    echo "creating flatpak ($ARCH)"

    # Setup Folder
    echo "Setting up temp folder..."
	rm -r "$CURRENT_DIR/flatpak"
	mkdir -p "$CURRENT_DIR/flatpak"

    # Prepare $ID.json
    MKXP_PATH_ESCAPED=$(echo "$MKXP_PATH" | sed -e 's/\./\\\./g' | sed -e 's/\//\\\//g')
	if [ "$ARCH" == "i386" ]; then
		echo "Setting up 32bit mkxp..."
		`sed -i "s/libpath/$MKXP_PATH_ESCAPED\/lib/g" "$CURRENT_DIR/$ID.json"`
		`sed -i "s/exename/$MKXP_PATH_ESCAPED\/mkxp\.x86/g" "$CURRENT_DIR/$ID.json"`
		`sed -i "s/exeout/$EXECUTABLENAME\.x86/g" "$CURRENT_DIR/$ID.json"`
	else
		echo "Setting up 64bit mkxp..."
		`sed -i "s/libpath/$MKXP_PATH_ESCAPED\/lib64/g" "$CURRENT_DIR/$ID.json"`
		`sed -i "s/exename/$MKXP_PATH_ESCAPED\/mkxp\.amd64/g" "$CURRENT_DIR/$ID.json"`
		`sed -i "s/exeout/$EXECUTABLENAME\.amd64/g" "$CURRENT_DIR/$ID.json"`
	fi

	# Delete previous
	echo "Preparing build..."
	if [[ -e "$CURRENT_DIR/$ID.$ARCH.flatpak" ]]; then
		rm "$CURRENT_DIR/$ID.$ARCH.flatpak"
	fi
	cd "$CURRENT_DIR/flatpak"

	echo "Building..."
	flatpak-builder --bundle-sources --force-clean --arch=$ARCH --repo=repo app "$CURRENT_DIR/$ID.json"
		#--filesystem=~/.$ID
	if [ $? -ne 0 ]; then
		echo "Error building"
		exit 1
	fi

	echo "Bundling..."
	flatpak build-bundle --arch=$ARCH repo "$CURRENT_DIR/$ID.$ARCH.flatpak" $ID
		if [ $? -ne 0 ]; then
		echo "Error bundling"
		exit 1
	fi

    # Cleanup
	echo "Cleaning up..."
	#rm -r "$CURRENT_DIR/flatpak"
	cd "$CURRENT_DIR"
}

if [ "$ARCH" == "32" ] || [ "$ARCH" == "both" ]; then
	createFlatpak "i386"
fi
if [ "$ARCH" == "64" ] || [ "$ARCH" == "both" ]; then
	createFlatpak "x86_64"
fi

# Cleanup
#rm -r "$CURRENT_DIR/$ID.json"
rm -r "$CURRENT_DIR/gamedir"

exit 0;
