#!/bin/bash
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$CURRENT_DIR"/script-dialog/script-dialog.sh #folder local version

# Ensure we have the MKXP-Z build
if [[ ! -f "$CURRENT_DIR/engine/linux/mkxp.json" ]]; then
    echo "Please download linux 'mkxp-z' from 'https://github.com/mkxp-z/mkxp-z/actions' and extract files into $CURRENT_DIR/engine/linux/"
    mkdir -p "$CURRENT_DIR/engine/linux/"
    exit 32;
fi

APPIMAGETOOL="appimagetool-x86_64.AppImage"

if [[ ! -e "$CURRENT_DIR/resources/tool/$APPIMAGETOOL" ]]; then
    mkdir -p "$CURRENT_DIR/tool"
    cd "$CURRENT_DIR/tool" || exit 1
    curl -O -J -L https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage -o "$APPIMAGETOOL"
    superuser chmod +x "$APPIMAGETOOL"
    cd "$CURRENT_DIR" || exit 1
fi
APPIMAGETOOL="$CURRENT_DIR/resources/tool/$APPIMAGETOOL"


if [[ $# -eq 0 ]] ; then
    DATA_DIR="."
else
    DATA_DIR="$1"
    ARCH="$2"
    OUTPUT_DIR="$3"
fi

if [ "$OUTPUT_DIR" == "" ]; then
    OUTPUT_DIR="."
fi
# There only seems to be 64bit support right now anyway
if [ "$ARCH" == "" ] || [ "$ARCH" == "64" ] || [ "$ARCH" == "amd64" ]; then
    ARCH="x86_64"
fi

# Get Variables
GAMEFOLDER=$(find "$DATA_DIR" ! -path "*_i386*" ! -path "*_amd64/*" ! -path "*.app*" ! -path "*.App*" ! -path "*flatpak/*" ! -path "*gamedir/*" ! -path "*outputs/*" -name 'Game.exe' -printf '%h\n' | sort -ur | tr -d '\n' | tr -d '\r')

if [[ ! -d "$GAMEFOLDER" ]]; then
    echo "No game folder found inside \"$DATA_DIR\""
    exit 31;
fi

TITLE_UPPER=$(grep 'Title' "$GAMEFOLDER"/Game.ini | cut -d'=' -f 2 | tr -d '\n' | tr -d '\r')
TITLE_UNDERSCORE=$(echo "$TITLE_UPPER"  | sed -e 's/ /_/g' | sed -e 's/\.//g')
# shellcheck disable=SC2034  # May be used by other build scripts or future features
TITLE_DASH=$(echo "$TITLE_UPPER"  | sed -e 's/ /-/g' | sed -e 's/\.//g')
TITLE_LOWER=$(echo "$TITLE_UPPER"  | tr '[:upper:]' '[:lower:]')
# shellcheck disable=SC2034  # May be used by other build scripts or future features
TITLE_LOWER_UNDERSCORE=$(echo "$TITLE_LOWER"  | sed -e 's/ /_/g' | sed -e 's/\.//g')
TITLE_LOWER_DASH=$(echo "$TITLE_LOWER"  | sed -e 's/ /-/g' | sed -e 's/\.//g')

COMPANY_UPPER=$(grep 'Company' "$DATA_DIR"/gameinfo.conf | cut -d'=' -f 2- | tr -d '\n' | tr -d '\r')
# shellcheck disable=SC2034  # May be used by other build scripts or future features
COMPANY_UNDERSCORE=${COMPANY_UPPER// /_}
# shellcheck disable=SC2034  # May be used by other build scripts or future features
COMPANY_DASH=${COMPANY_UPPER// /-}
COMPANY_LOWER=$(echo "$COMPANY_UPPER"  | tr '[:upper:]' '[:lower:]')
# shellcheck disable=SC2034  # May be used by other build scripts or future features
COMPANY_LOWER_UNDERSCORE=${COMPANY_LOWER// /_}
COMPANY_LOWER_DASH=${COMPANY_LOWER// /-}

ID=$(grep 'Id' "$DATA_DIR"/gameinfo.conf | cut -d'=' -f 2 | tr -d '\n' | tr -d '\r' | tr -d '[:space:]')
# shellcheck disable=SC2034  # May be used by other build scripts or future features
VERSION=$(grep 'Version' "$DATA_DIR"/gameinfo.conf | cut -d'=' -f 2 | tr -d '\n' | tr -d '\r')
SHORT_DESCRIPTION=$(grep 'Description' "$DATA_DIR"/gameinfo.conf | cut -d'=' -f 2 | tr -d '\n' | tr -d '\r')
# shellcheck disable=SC2034  # May be used by other build scripts or future features
DESCRIPTION=$(sed -n '/Description/,$p' "$DATA_DIR"/gameinfo.conf | cut -d'=' -f 2- | sed ':a;N;$!ba;s/\n/\\n/g;s/	/ /g')
# shellcheck disable=SC2034  # May be used by other build scripts or future features
MAINTANER=$(grep 'Maintainer' "$DATA_DIR"/gameinfo.conf | cut -d'=' -f 2 | tr -d '\n' | tr -d '\r')
# shellcheck disable=SC2034  # May be used by other build scripts or future features
HOMEPAGE=$(grep 'Homepage' "$DATA_DIR"/gameinfo.conf | cut -d'=' -f 2 | tr -d '\n' | tr -d '\r')

PACKAGENAME="$COMPANY_LOWER_DASH"-"$TITLE_LOWER_DASH"
RELATIVEDIR="/opt/$PACKAGENAME"
EXECUTABLENAME="$TITLE_LOWER_DASH"

# Create game launcher script
echo "Creating game launcher script..."
cp "$CURRENT_DIR/resources/linux/game.sh" "$CURRENT_DIR/"game.sh.temp
sed -i "s|APPDIR=\(.*\)|APPDIR=\\$HOME/.local/share/$PACKAGENAME/|" "$CURRENT_DIR/"game.sh.temp

function createAppImage() {
    ARCH=$1
    echo "creating app image ($ARCH)"

    if [ "$ARCH" == "x86_64" ]; then
        APPDIR="$OUTPUT_DIR/$TITLE_UNDERSCORE.AppDir"
        APPIMAGE="$OUTPUT_DIR/$TITLE_UNDERSCORE.AppImage"
    else
        APPDIR="$OUTPUT_DIR/$TITLE_UNDERSCORE-$ARCH.AppDir"
        APPIMAGE="$OUTPUT_DIR/$TITLE_UNDERSCORE-$ARCH.AppImage"
    fi

    # Setup Folder
    rm -r "${APPDIR:?}/$RELATIVEDIR"
    mkdir -p "$APPDIR/$RELATIVEDIR"

    cp "$CURRENT_DIR/resources/linux/AppRun" "$APPDIR/"
    sed -i "s|GAME_DIR=\(.*\)|GAME_DIR=\"$RELATIVEDIR\"|" "$APPDIR/AppRun"
    sed -i "s|GAME_EXEC=\(.*\)|GAME_EXEC=\"game.sh\"|" "$APPDIR/AppRun"

    # Creating desktop file...
    DESKTOP_FILE="$APPDIR/$ID.desktop"
    cp "$CURRENT_DIR/resources/linux/app.desktop" "$DESKTOP_FILE"
    sed -i "s|Name=\(.*\)|Name=$TITLE_UPPER|" "$DESKTOP_FILE"
    sed -i "s|Comment=\(.*\)|Comment=${SHORT_DESCRIPTION//./\\.}|" "$DESKTOP_FILE"
    sed -i "s/Exec=\(.*\)/Exec=\"\/opt\/${PACKAGENAME}\/game.sh\"/" "$DESKTOP_FILE"
    sed -i "s|Icon=\(.*\)|Icon=\/opt\/${PACKAGENAME}\/${ID//./\\.}|"  "$DESKTOP_FILE"
    sed -i "s|Path=\(.*\)|Path=\/opt\/${PACKAGENAME}\/|"  "$DESKTOP_FILE"

    # Populating fakeroot...
    cp -r "$GAMEFOLDER"/* 				"$APPDIR/$RELATIVEDIR/"
    cp "$CURRENT_DIR"/game.sh.temp      "$APPDIR/$RELATIVEDIR/game.sh"
    cp "$CURRENT_DIR"/resources/mkxp.json   "$APPDIR/$RELATIVEDIR/mkxp.json"

    if [ "$ARCH" == "i386" ]; then
        cp "$CURRENT_DIR"/engine/linux/mkxp-z.x86   "$APPDIR/$RELATIVEDIR/$EXECUTABLENAME".x86
    else
        cp "$CURRENT_DIR"/engine/linux/mkxp-z.x86_64   "$APPDIR/$RELATIVEDIR/$EXECUTABLENAME".amd64
    fi
        cp -r "$CURRENT_DIR"/engine/linux/lib*        "$APPDIR/$RELATIVEDIR/"
    cp -r "$CURRENT_DIR"/engine/linux/stdlib        "$APPDIR/$RELATIVEDIR/"

    # Add script-dialog
    SCRIPT_DIAG_DIR="$APPDIR/$RELATIVEDIR/script-dialog/"
    mkdir -p "$SCRIPT_DIAG_DIR"
    cp "$CURRENT_DIR/script-dialog/script-dialog.sh" "$SCRIPT_DIAG_DIR"

    if [ -f "$DATA_DIR/license.txt" ]; then
        cp "$DATA_DIR/license.txt" "$APPDIR/$RELATIVEDIR/LICENSE"
    fi
    if [[ -e "$DATA_DIR"/company.png ]]; then
        cp "$DATA_DIR"/company.png "$APPDIR/$RELATIVEDIR/"
    fi

    # Icons

    ## Native Size
		cp "$DATA_DIR"/game.png "$APPDIR/$RELATIVEDIR/$ID.png"
		cp "$DATA_DIR"/game.png "$APPDIR/$RELATIVEDIR/game.png"
    cp "$DATA_DIR"/game.png "$APPDIR/$ID.png"
    mkdir -p "$APPDIR/usr/share/pixmaps"
    cp "$DATA_DIR"/game.png "$APPDIR/usr/share/pixmaps/$ID.png"

    ## hicolor sizes
    SIZES=( "128" "256" "512")
    for SIZE in "${SIZES[@]}"; do
        ICONDIR="$APPDIR/usr/share/icons/hicolor/${SIZE}x${SIZE}/apps/"
        mkdir -p "$ICONDIR"
        convert "$DATA_DIR"/game.png -resize "${SIZE}x${SIZE}" "$ICONDIR/$ID.png"
    done

    rm "$APPIMAGE" # delete previous
    if ARCH=$ARCH "$APPIMAGETOOL" -n "$APPDIR" "$APPIMAGE"; then
        # Cleanup if nothing to debug
        rm -r "$APPDIR"
    fi
}

createAppImage "$ARCH"

# Cleanup
rm "$CURRENT_DIR/"game.sh.temp

exit 0;
