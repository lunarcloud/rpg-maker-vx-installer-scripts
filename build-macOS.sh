#!/bin/bash
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Get Variables

if [[ $# -eq 0 ]] ; then
    DATA_DIR="."
else
    DATA_DIR="$1"
    PACKAGING="$2"
    OUTPUT_DIR="$3"
fi

if [ "$OUTPUT_DIR" == "" ]; then
    OUTPUT_DIR="."
fi
if [ "$PACKAGING" != "zip" ] && [ "$PACKAGING" != "dmg" ] && [ "$PACKAGING" != "both" ]; then
    PACKAGING="dmg"
fi

GAMEFOLDER=$(find "$DATA_DIR" ! -path "*_i386*" ! -path "*_amd64/*" ! -path "*.app*" ! -path "*.App*" ! -path "*flatpak/*" ! -path "*gamedir/*" ! -path "*outputs/*" -name 'Game.exe' -printf '%h\n' | sort -ur | tr -d '\n' | tr -d '\r')

if [[ ! -d "$GAMEFOLDER" ]]; then
    echo "No game folder found inside \"$DATA_DIR\""
    exit 31;
fi

BUNDLE_NAME=$(grep 'Title' "$GAMEFOLDER"/Game.ini | cut -d'=' -f 2 | tr -d '\n' | tr -d '\r')
ID=$(grep 'Id' $DATA_DIR/gameinfo.conf | cut -d'=' -f 2 | tr -d '\n' | tr -d '\r' | tr -d '[:space:]')
VERSION=$(grep 'Version' "$DATA_DIR"/gameinfo.conf | cut -d'=' -f 2 | tr -d '\n' | tr -d '\r')


BASE_APP="$CURRENT_DIR/engine/macos/mkxp.app"
if [[ ! -d "$BASE_APP" ]]; then
    echo "Please download 'mkxp' macos and extract mkxp.app into $CURRENT_DIR/engine/macos/"
    mkdir -p "$CURRENT_DIR/engine/macos/"
fi

# Ensure we have the MKXP[-Z] build
if [[ ! -d "$CURRENT_DIR/engine/macos/" ]]; then
    mkdir -p "$CURRENT_DIR/engine/macos/"
    exit 32;
fi

BASE_APP="$CURRENT_DIR/engine/macos/mkxp.app"
BASE_APP_GAMEDIR="$OUTPUT_DIR/$BUNDLE_NAME".app/Contents/Resources/
CONF_JSON=false

if [[ ! -d "$BASE_APP" ]]; then
    BASE_APP="$CURRENT_DIR/engine/macos/Z-universal.app"
    BASE_APP_GAMEDIR="$OUTPUT_DIR/$BUNDLE_NAME".app/Contents/Game/
    CONF_JSON=true

    if [[ ! -d "$BASE_APP" ]]; then
        echo "Please download 'mkxp-z' macos from 'https://github.com/mkxp-z/mkxp-z/actions' and extract Z-universal.app into $CURRENT_DIR/engine/macos/"
        exit 32;
    fi
fi

if [ "$CONF_JSON" = true ]; then
    echo "Using MKXP-Z macOS engine"
else
    echo "Using MKXP macOS engine"
fi

rm -rf "$OUTPUT_DIR/$BUNDLE_NAME".app
cp -r "$BASE_APP" "$OUTPUT_DIR/$BUNDLE_NAME".app
if [[ ! -d "$OUTPUT_DIR/$BUNDLE_NAME".app ]]; then
	echo "can't build mac bundle."
	exit 33
fi
mkdir -p "$BASE_APP_GAMEDIR"
mkdir -p "$OUTPUT_DIR/$BUNDLE_NAME.app/Contents/Resources/"
cp -r "$GAMEFOLDER"/* "$BASE_APP_GAMEDIR"

if [[ ! -f "$BASE_APP_GAMEDIR"/Game.exe ]]; then
    echo "Couldn't copy game files to $BASE_APP_GAMEDIR"
    exit 32
fi

if [[ -f "$DATA_DIR"/game.png ]]; then
    cp "$DATA_DIR"/game.png "$BASE_APP_GAMEDIR"

    # Overwrite the icon file
    png2icns "$OUTPUT_DIR/$BUNDLE_NAME.app/Contents/Resources/icon.icns" "$DATA_DIR"/game.png
fi

# Config
if [ "$CONF_JSON" = true ]; then
    cp "$CURRENT_DIR/resources/mkxp.json" "$OUTPUT_DIR/$BUNDLE_NAME.app/Contents/Game/mkxp.json"
else
    cp "$CURRENT_DIR/resources/macos/"mkxp.macos.conf   "$OUTPUT_DIR/$BUNDLE_NAME.app/Contents/Resources/mkxp.conf"
    sed -i "s|^.*iconPath=.*|iconPath=game.png|" 	    "$OUTPUT_DIR/$BUNDLE_NAME.app/Contents/Resources/mkxp.conf"
fi
PLIST="$OUTPUT_DIR/$BUNDLE_NAME.app/Contents/Info.plist"

# Things to update in the PFList
SAW_NAMELINE=false
SAW_ICONLINE=false
SAW_IDLINE=false
SAW_VERSIONLINE=false
LINE_NUM=0

#Update Name in PFList
while IFS= read -r line
do
	((LINE_NUM++))

	if [[ $SAW_NAMELINE == true ]]; then
		sed -i "${LINE_NUM}s|<string>.*</string>|<string>$BUNDLE_NAME</string>|" "$PLIST"
		SAW_NAMELINE=false
		continue
	elif [[ "$line" =~ "CFBundleName" ]] || [[ "$line" =~ "CFBundleGetInfoString" ]]; then
		SAW_NAMELINE=true
		continue
	fi

	if [[ $SAW_ICONLINE == true ]]; then
		sed -i "${LINE_NUM}s|<string>.*</string>|<string>icon</string>|" "$PLIST"
		SAW_ICONLINE=false
		continue
	fi
	if [[ "$line" =~ "CFBundleIconFile" ]]; then
		SAW_ICONLINE=true
		continue
	fi

	if [[ $SAW_IDLINE == true ]]; then
		sed -i "${LINE_NUM}s|<string>.*</string>|<string>$ID</string>|" "$PLIST"
		SAW_IDLINE=false
		continue
	elif [[ "$line" =~ "CFBundleIdentifier" ]]; then
		SAW_IDLINE=true
		continue
	fi

	if [[ $SAW_VERSIONLINE == true ]]; then
		sed -i "${LINE_NUM}s|<string>.*</string>|<string>$VERSION</string>|" "$PLIST"
		SAW_VERSIONLINE=false
		continue
	elif [[ "$line" =~ "CFBundleShortVersionString" ]]; then
		SAW_VERSIONLINE=true
		continue
	fi
done < "$PLIST"



if [ "$PACKAGING" == "zip" ] || [ "$PACKAGING" == "both" ]; then
    # create zip of the bundle
    ZIP_NAME="$BUNDLE_NAME $VERSION macOS.zip"

    if [ -f "$OUTPUT_DIR/$ZIP_NAME" ]; then
        rm -r "$OUTPUT_DIR/$ZIP_NAME"
    fi
    (cd "$OUTPUT_DIR" && zip -rq "$OUTPUT_DIR/$ZIP_NAME" "$BUNDLE_NAME".app)
    if [ -f $DATA_DIR/license.txt ]; then
        zip -ujq "$OUTPUT_DIR/$ZIP_NAME" "$DATA_DIR"/license.txt
    fi
fi

if [ "$PACKAGING" == "dmg" ] || [ "$PACKAGING" == "both" ]; then
    # create dmg for the bundle

    mv "$OUTPUT_DIR/$BUNDLE_NAME".app "$CURRENT_DIR/resources/macos/dmg-contents/$BUNDLE_NAME.app"
    png2icns "$CURRENT_DIR/dmg-contents/.VolumeIcon.icns" "$DATA_DIR/game.png"
    if [ -f $DATA_DIR/license.txt ]; then
        cp "$DATA_DIR"/license.txt "$CURRENT_DIR/"dmg-contents/
    fi

    genisoimage -V "$BUNDLE_NAME" -D -R -apple -no-pad -o "$OUTPUT_DIR/$BUNDLE_NAME $VERSION.dmg" "$CURRENT_DIR/"dmg-contents

    # clean up
    rm "$CURRENT_DIR/"dmg-contents/.VolumeIcon.icns
    rm "$CURRENT_DIR/"dmg-contents/license.txt
    rm -r "$CURRENT_DIR/"dmg-contents/"$BUNDLE_NAME".app
fi

if [ "$PACKAGING" == "zip" ]; then
    # clean up
    rm -r "$OUTPUT_DIR/$BUNDLE_NAME".app
fi

exit 0;
