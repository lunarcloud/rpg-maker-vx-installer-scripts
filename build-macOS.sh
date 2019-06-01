#!/bin/bash
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

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

GAMEFOLDER=$(find "$DATA_DIR" ! -path "*_i386*" ! -path "*_amd64/*" ! -path "*.app*" -name 'Game.exe' -printf '%h\n' | sort -ur | tr -d '\n' | tr -d '\r')

if [[ ! -d "$GAMEFOLDER" ]]; then
    echo "No game folder found inside \"$DATA_DIR\""
    exit 31;
fi

BUNDLE_NAME=$(grep 'Title' "$GAMEFOLDER"/Game.ini | cut -d'=' -f 2 | tr -d '\n' | tr -d '\r')
VERSION=$(grep 'Version' "$DATA_DIR"/gameinfo.conf | cut -d'=' -f 2 | tr -d '\n' | tr -d '\r')

MKXP_MAC="mkxp-6-8-2018-withrubyzlib.zip"

if [[ ! -e "$CURRENT_DIR/$MKXP_MAC" ]]; then
    echo "Please download '$MKXP_MAC' from 'https://app.box.com/v/mkxpmacbuilds' and place into $CURRENT_DIR"
    exit 32;
fi

if [[ ! -d "$CURRENT_DIR/mkxp_mac/mkxp.app" ]]; then
    unzip "$CURRENT_DIR/$MKXP_MAC" -d "$CURRENT_DIR/mkxp_mac"
fi

rm -rf "$CURRENT_DIR/$BUNDLE_NAME".app
cp -r "$CURRENT_DIR/mkxp_mac/mkxp.app" "$CURRENT_DIR/$BUNDLE_NAME".app
if [[ ! -d "$CURRENT_DIR/$BUNDLE_NAME".app ]]; then
	echo "can't build mac bundle."
	exit 33
fi
cp -r "$GAMEFOLDER"/* "$CURRENT_DIR/$BUNDLE_NAME".app/Contents/Resources/

if [[ -f "$DATA_DIR"/game.png ]]; then
    cp "$DATA_DIR"/game.png "$CURRENT_DIR/$BUNDLE_NAME".app/Contents/Resources/
    png2icns "$CURRENT_DIR/$BUNDLE_NAME".app/Contents/Resources/game.icns "$DATA_DIR"/game.png
    # Modify "$BUNDLE_NAME".app/Contents/Info.plist to include the icon
fi

sed -i "s|^.*iconPath=.*|iconPath=game.png|" "$CURRENT_DIR/$BUNDLE_NAME.app/Contents/Resources/mkxp.conf"

PLIST="$CURRENT_DIR/$BUNDLE_NAME.app/Contents/Info.plist"

#Update Icon in PFList
SAW_ICONLINE=false
LINE_NUM=0
while IFS= read -r line
do
	((LINE_NUM++))
	if [[ $SAW_ICONLINE == true ]]; then
		sed -i "${LINE_NUM}s|<string></string>|<string>game</string>|" "$PLIST"
		break;
	fi
	if [[ "$line" =~ "CFBundleIconFile" ]]; then
		SAW_ICONLINE=true
	fi
done < "$PLIST"

#Update Name in PFList
SAW_NAMELINE=false
LINE_NUM=0
while IFS= read -r line
do
	((LINE_NUM++))
	if [[ $SAW_NAMELINE == true ]]; then
		sed -i "${LINE_NUM}s|<string></string>|<string>$BUNDLE_NAME</string>|" "$PLIST"
		break;
	fi
	if [[ "$line" =~ "CFBundleName" ]]; then
		SAW_NAMELINE=true
	fi
done < "$PLIST"

if [ "$PACKAGING" == "zip" ] || [ "$PACKAGING" == "both" ]; then
    # create zip of the bundle
    ZIP_NAME="$BUNDLE_NAME $VERSION macOS.zip"

    zip -r "$CURRENT_DIR/$ZIP_NAME" "$CURRENT_DIR/$BUNDLE_NAME".app
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
