#!/bin/bash
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Ensure we have the MKXP-Z build
if [[ ! -d "$CURRENT_DIR/engine/macos/Z-universal.app" ]]; then
    echo "Please download 'mkxp-z' macos from 'https://github.com/mkxp-z/mkxp-z/actions' and extract Z-universal.app into $CURRENT_DIR/engine/macos/"
    mkdir -p "$CURRENT_DIR/engine/macos/"
    exit 32;
fi

# Get Variables

if [[ $# -eq 0 ]] ; then
    DATA_DIR="."
else
    DATA_DIR="$1"
    PACKAGING="$2"
fi

if [ "$PACKAGING" != "zip" ] && [ "$PACKAGING" != "dmg" ] && [ "$PACKAGING" != "both" ]; then
    PACKAGING="dmg"
fi

GAMEFOLDER=$(find "$DATA_DIR" ! -path "*_i386*" ! -path "*_amd64/*" ! -path "*.app*" ! -path "*.App*" ! -path "*flatpak/*" ! -path "*gamedir/*" -name 'Game.exe' -printf '%h\n' | sort -ur | tr -d '\n' | tr -d '\r')

if [[ ! -d "$GAMEFOLDER" ]]; then
    echo "No game folder found inside \"$DATA_DIR\""
    exit 31;
fi

BUNDLE_NAME=$(grep 'Title' "$GAMEFOLDER"/Game.ini | cut -d'=' -f 2 | tr -d '\n' | tr -d '\r')
ID=$(grep 'Id' $DATA_DIR/gameinfo.conf | cut -d'=' -f 2 | tr -d '\n' | tr -d '\r' | tr -d '[:space:]')
VERSION=$(grep 'Version' "$DATA_DIR"/gameinfo.conf | cut -d'=' -f 2 | tr -d '\n' | tr -d '\r')

rm -rf "$CURRENT_DIR/$BUNDLE_NAME".app
cp -r "$CURRENT_DIR/engine/macos/Z-universal.app" "$CURRENT_DIR/$BUNDLE_NAME".app
if [[ ! -d "$CURRENT_DIR/$BUNDLE_NAME".app ]]; then
	echo "can't build mac bundle."
	exit 33
fi
mkdir -p "$CURRENT_DIR/$BUNDLE_NAME".app/Contents/Game/
cp -r "$GAMEFOLDER"/* "$CURRENT_DIR/$BUNDLE_NAME".app/Contents/Game/

if [[ -f "$DATA_DIR"/game.png ]]; then
    cp "$DATA_DIR"/game.png "$CURRENT_DIR/$BUNDLE_NAME".app/Contents/Game/
    # Overwrite the icon file
    png2icns "$CURRENT_DIR/$BUNDLE_NAME.app/Contents/Resources/icon.icns" "$DATA_DIR"/game.png
    # Modify "$BUNDLE_NAME".app/Contents/Info.plist to include the icon
fi

# Config
cp "$CURRENT_DIR/"mkxp.macos.json      					"$CURRENT_DIR/$BUNDLE_NAME.app/Contents/Game/mkxp.json"
# TODO update the icon
#sed -i "s|^.*iconPath=.*|iconPath=game.png|" 	"$CURRENT_DIR/$BUNDLE_NAME.app/Contents/Game/mkxp.json"

PLIST="$CURRENT_DIR/$BUNDLE_NAME.app/Contents/Info.plist"

# Things to update in the PFList
SAW_NAMELINE=false
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

    zip -r "$CURRENT_DIR/$ZIP_NAME" "$BUNDLE_NAME".app
    if [ -f $DATA_DIR/license.txt ]; then
        zip -uj "$CURRENT_DIR/$ZIP_NAME" "$DATA_DIR"/license.txt
    fi
fi

if [ "$PACKAGING" == "dmg" ] || [ "$PACKAGING" == "both" ]; then
    # create dmg for the bundle

    mv "$CURRENT_DIR/$BUNDLE_NAME".app "$CURRENT_DIR/dmg-contents/$BUNDLE_NAME.app"
    png2icns "$CURRENT_DIR/dmg-contents/.VolumeIcon.icns" "$DATA_DIR/game.png"
    if [ -f $DATA_DIR/license.txt ]; then
        cp "$DATA_DIR"/license.txt "$CURRENT_DIR/"dmg-contents/
    fi

    genisoimage -V "$BUNDLE_NAME" -D -R -apple -no-pad -o "$CURRENT_DIR/$BUNDLE_NAME $VERSION.dmg" "$CURRENT_DIR/"dmg-contents

    # clean up
    rm "$CURRENT_DIR/"dmg-contents/.VolumeIcon.icns
    rm "$CURRENT_DIR/"dmg-contents/license.txt
    rm -r "$CURRENT_DIR/"dmg-contents/"$BUNDLE_NAME".app
fi

if [ "$PACKAGING" == "zip" ]; then
    # clean up
    rm -r "$CURRENT_DIR/$BUNDLE_NAME".app
fi

exit 0;
