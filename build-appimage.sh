#!/bin/bash
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$CURRENT_DIR"/script-dialog/script-dialog.sh #folder local version

if [[ ! -e 	mkxp-20180121.tar.xz ]]; then
    #Get copy of MKXP
    wget http://ancurio.bplaced.net/mkxp/generic/mkxp-20180121.tar.xz # or latest version
    tar xf mkxp*.tar.xz
fi

APPIMAGETOOL="appimagetool-x86_64.AppImage"

if [[ ! -e "$CURRENT_DIR/tool/$APPIMAGETOOL" ]]; then
    mkdir -p "$CURRENT_DIR/tool"
    cd "$CURRENT_DIR/tool"
    curl -O -J -L https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage -o "$APPIMAGETOOL"
    superuser chmod +x "$APPIMAGETOOL"
    cd "$CURRENT_DIR"
fi
APPIMAGETOOL="$CURRENT_DIR/tool/$APPIMAGETOOL"

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
TITLE_UNDERSCORE=$(echo $TITLE_UPPER  | sed -e 's/ /_/g' | sed -e 's/\.//g')
TITLE_DASH=$(echo $TITLE_UPPER  | sed -e 's/ /-/g' | sed -e 's/\.//g')
TITLE_LOWER=$(echo $TITLE_UPPER  | tr '[:upper:]' '[:lower:]')
TITLE_LOWER_UNDERSCORE=$(echo $TITLE_LOWER  | sed -e 's/ /_/g' | sed -e 's/\.//g')
TITLE_LOWER_DASH=$(echo $TITLE_LOWER  | sed -e 's/ /-/g' | sed -e 's/\.//g')

COMPANY_UPPER=$(grep 'Company' $DATA_DIR/gameinfo.conf | cut -d'=' -f 2- | tr -d '\n' | tr -d '\r')
COMPANY_UNDERSCORE=$(echo $COMPANY_UPPER  | sed -e 's/ /_/g')
COMPANY_DASH=$(echo $COMPANY_UPPER  | sed -e 's/ /-/g')
COMPANY_LOWER=$(echo $COMPANY_UPPER  | tr '[:upper:]' '[:lower:]')
COMPANY_LOWER_UNDERSCORE=$(echo $COMPANY_LOWER  | sed -e 's/ /_/g')
COMPANY_LOWER_DASH=$(echo $COMPANY_LOWER  | sed -e 's/ /-/g')

VERSION=$(grep 'Version' $DATA_DIR/gameinfo.conf | cut -d'=' -f 2 | tr -d '\n' | tr -d '\r')
SHORT_DESCRIPTION=$(grep 'Description' $DATA_DIR/gameinfo.conf | cut -d'=' -f 2 | tr -d '\n' | tr -d '\r')
DESCRIPTION=$(sed -n '/Description/,$p' $DATA_DIR/gameinfo.conf | cut -d'=' -f 2- | sed ':a;N;$!ba;s/\n/\\n/g;s/	/ /g')
MAINTANER=$(grep 'Maintainer' $DATA_DIR/gameinfo.conf | cut -d'=' -f 2 | tr -d '\n' | tr -d '\r')
HOMEPAGE=$(grep 'Homepage' $DATA_DIR/gameinfo.conf | cut -d'=' -f 2 | tr -d '\n' | tr -d '\r')

PACKAGENAME="$COMPANY_LOWER_DASH"-"$TITLE_LOWER_DASH"
RELATIVEDIR="/opt/$PACKAGENAME"

# Create game launcher script
echo "Creating game launcher script..."
cp game.sh game.sh.temp
`sed -i "s|APPDIR=\(.*\)|APPDIR=$HOME/.local/share/$PACKAGENAME/|" ./game.sh.temp`

function createAppImage() {
    ARCH=$1
    echo "creating app image ($ARCH)"

    APPDIR="$CURRENT_DIR/$TITLE_UNDERSCORE-$ARCH.AppDir"
    APPIMAGE="$CURRENT_DIR/$TITLE_UNDERSCORE-$ARCH.AppImage"

    # Setup Folder
    rm -r "$APPDIR/$RELATIVEDIR"
    mkdir -p "$APPDIR/$RELATIVEDIR"

    cp "linux-appimage/AppRun" "$APPDIR/"
    `sed -i "s|GAME_DIR=\(.*\)|GAME_DIR=\"$RELATIVEDIR\"|" "$APPDIR/AppRun"`
    `sed -i "s|GAME_EXEC=\(.*\)|GAME_EXEC=\"game.sh\"|" "$APPDIR/AppRun"`

    # Creating desktop file...
    DESKTOP_FILE="$APPDIR/$PACKAGENAME.desktop"
    cp "app.desktop" "$DESKTOP_FILE"
    `sed -i "s|Name=\(.*\)|Name=$TITLE_UPPER|" "$DESKTOP_FILE"`
    `sed -i "s|Comment=\(.*\)|Comment=$( echo "$SHORT_DESCRIPTION" | sed -e 's/\./\\\./g')|" "$DESKTOP_FILE"`
    `sed -i "s/Exec=\(.*\)/Exec=\"\/opt\/"$PACKAGENAME"\/game.sh\"/" "$DESKTOP_FILE"`
    `sed -i "s|Icon=\(.*\)|Icon=$PACKAGENAME|"  "$DESKTOP_FILE"`
    `sed -i "s|Path=\(.*\)|Path=\/opt\/"$PACKAGENAME"\/|"  "$DESKTOP_FILE"`

    # Populating fakeroot...
    cp -r "$GAMEFOLDER"/* 				"$APPDIR/$RELATIVEDIR/"
	cp "$CURRENT_DIR"/game.sh.temp      "$APPDIR/$RELATIVEDIR/game.sh"
	cp "$CURRENT_DIR"/mkxp.linux.conf   "$APPDIR/$RELATIVEDIR/"

	if [ "$ARCH" == "i386" ]; then
		cp "$CURRENT_DIR"/mkxp-*/mkxp.x86   "$APPDIR/$RELATIVEDIR/$EXECUTABLENAME".x86
		cp -r "$CURRENT_DIR"/mkxp-*/lib        "$APPDIR/$RELATIVEDIR/lib"
	else
		cp "$CURRENT_DIR"/mkxp-*/mkxp.amd64   "$APPDIR/$RELATIVEDIR/$EXECUTABLENAME".amd64
		cp -r "$CURRENT_DIR"/mkxp-*/lib64        "$APPDIR/$RELATIVEDIR/lib"
	fi

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

    # native size
    cp "$DATA_DIR"/game.png "$APPDIR/$PACKAGENAME.png"
    mkdir -p "$APPDIR/usr/share/pixmaps"
    cp "$DATA_DIR"/game.png "$APPDIR/usr/share/pixmaps/$PACKAGENAME.png"

    # hicolor sizes
    SIZES=( "128" "256" "512")
    for SIZE in "${SIZES[@]}"; do
        ICONDIR="$APPDIR/usr/share/icons/hicolor/${SIZE}x${SIZE}/apps/"
        mkdir -p "$ICONDIR"
        convert "$DATA_DIR"/game.png -resize ${SIZE}x${SIZE} "$ICONDIR/$PACKAGENAME.png"
    done

    rm $APPIMAGE # delete previous
    ARCH=$ARCH "$APPIMAGETOOL" -n "$APPDIR" "$APPIMAGE"

    # Cleanup
    if [ $? -eq 0 ]; then
        rm -r "$APPDIR"
    fi
}

if [ "$ARCH" == "32" ] || [ "$ARCH" == "both" ]; then
    createAppImage "i386"
fi
if [ "$ARCH" == "64" ] || [ "$ARCH" == "both" ]; then
    createAppImage "x86_64"
fi

exit 0;
