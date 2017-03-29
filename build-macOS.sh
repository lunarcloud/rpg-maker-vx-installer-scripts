#!/bin/bash

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

MKXP_MAC="mkxp-16-8-2015-withrubyzlib.zip"

if [[ ! -e $MKXP_MAC ]]; then
    echo "Please '$MKXP_MAC' download from 'https://app.box.com/v/mkxpmacbuilds'"
    exit 32;
fi

if [[ ! -d "mkxp_mac/mkxp.app" ]]; then
    unzip "$MKXP_MAC" -d "mkxp_mac"
fi

rm -rf ./"$BUNDLE_NAME".app
cp -r ./mkxp_mac/mkxp.app ./"$BUNDLE_NAME".app
cp -r "$GAMEFOLDER"/* ./"$BUNDLE_NAME".app/Contents/Resources/

if [[ -f "$DATA_DIR"/game.png ]]; then
    png2icns ./"$BUNDLE_NAME".app/Contents/Resources/app.icns "$DATA_DIR"/game.png
    # Modify "$BUNDLE_NAME".app/Contents/Info.plist to inclide the icon
fi

if [ "$PACKAGING" == "zip" ] || [ "$PACKAGING" == "both" ]; then
    # create zip of the bundle
    ZIP_NAME="$BUNDLE_NAME $VERSION macOS.zip"

    zip -r ./"$ZIP_NAME" ./"$BUNDLE_NAME".app
    if [ -f $DATA_DIR/license.txt ]; then
        zip -uj ./"$ZIP_NAME" "$DATA_DIR"/license.txt
    fi
fi

if [ "$PACKAGING" == "dmg" ] || [ "$PACKAGING" == "both" ]; then
    # create dmg for the bundle

    mv ./"$BUNDLE_NAME".app dmg-contents/"$BUNDLE_NAME".app
    png2icns dmg-contents/.VolumeIcon.icns $DATA_DIR/game.png
    if [ -f $DATA_DIR/license.txt ]; then
        cp "$DATA_DIR"/license.txt dmg-contents/
    fi

    genisoimage -V "$BUNDLE_NAME" -D -R -apple -no-pad -o "$BUNDLE_NAME $VERSION.dmg" dmg-contents

    # clean up
    rm dmg-contents/.VolumeIcon.icns
    rm dmg-contents/license.txt
    rm -r dmg-contents/"$BUNDLE_NAME".app
fi

if [ "$PACKAGING" == "zip" ]; then
    # clean up
    rm -r ./"$BUNDLE_NAME".app
fi

exit 0;
