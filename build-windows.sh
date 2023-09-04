#!/bin/bash
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Get Variables

if [[ $# -eq 0 ]] ; then
    DATA_DIR="."
else
    DATA_DIR="$1"
fi

GAMEFOLDER=$(find "$DATA_DIR" ! -path "*_i386*" ! -path "*_amd64/*" ! -path "*.app*" ! -path "*.App*" ! -path "*flatpak/*" ! -path "*gamedir/*" -name 'Game.exe' -printf '%h\n' | sort -ur | tr -d '\n' | tr -d '\r')

if [[ ! -d "$GAMEFOLDER" ]]; then
    echo "No game folder found inside \"$DATA_DIR\""
    exit 31;
fi

NAME=$(grep 'Title' "$GAMEFOLDER"/Game.ini | cut -d'=' -f 2 | tr -d '\n' | tr -d '\r')
VERSION=$(grep 'Version' $DATA_DIR/gameinfo.conf | cut -d'=' -f 2 | tr -d '\n' | tr -d '\r')
PUBLISHER=$(grep 'Company' $DATA_DIR/gameinfo.conf | cut -d'=' -f 2- | tr -d '\n' | tr -d '\r')
WEB_SITE=$(grep 'Homepage' $DATA_DIR/gameinfo.conf | cut -d'=' -f 2 | tr -d '\n' | tr -d '\r')

# Update nsi file
echo "Creating nsi file..."
cp "$CURRENT_DIR"/resources/windows/game.nsi.template "$CURRENT_DIR"/game.nsi
sed -i "s#define GAMEFOLDER \"\(.*\)\"#define GAMEFOLDER \"$(echo "$GAMEFOLDER" | sed -e 's/\./\\\./g')\"#"  "$CURRENT_DIR/game.nsi"
sed -i "s/define PRODUCT_NAME \"\(.*\)\"/define PRODUCT_NAME \"$(echo "$NAME" | sed -e 's/\./\\\./g')\"/"  "$CURRENT_DIR/game.nsi"
sed -i "s/define PRODUCT_VERSION \"\(.*\)\"/define PRODUCT_VERSION \"$(echo "$VERSION" | sed -e 's/\./\\\./g')\"/"  "$CURRENT_DIR/game.nsi"
sed -i "s/define PRODUCT_PUBLISHER \"\(.*\)\"/define PRODUCT_PUBLISHER \"$(echo "$PUBLISHER" | sed -e 's/\./\\\./g')\"/"  "$CURRENT_DIR/game.nsi"
sed -i "s/define PRODUCT_WEB_SITE \"\(.*\)\"/define PRODUCT_WEB_SITE \"$(echo "$WEB_SITE" | sed -e 's/\./\\\./g')\"/"  "$CURRENT_DIR/game.nsi"

if [ -f "$DATA_DIR"/installer.ico ]; then
    sed -i "s#define MUI_ICON \"\(.*\)\"#define MUI_ICON \"$DATA_DIR/installer.ico\"#"  "$CURRENT_DIR/game.nsi"
else
    sed -i "s#define MUI_ICON \"\(.*\)\"#define MUI_ICON \"\$\{NSISDIR\}\\\\Contrib\\\\Graphics\\\\Icons\\\\modern-install.ico\"#"  "$CURRENT_DIR/game.nsi"
fi


function changeExeIcon() {
    if [[ ! -f "$DATA_DIR"/game.ico ]]; then
        return
    fi

    # Get Variables
    EXECUTABLE=$(find "$DATA_DIR" ! -path "*_i386*" ! -path "*_amd64/*" ! -path "*.app*" -name 'Game.exe' -printf '%p')

    if [[ ! -e "$EXECUTABLE" ]]; then
        echo "No game executable found inside \"$DATA_DIR\""
        return
    fi

    # Ensure the tool exists
    if [[ ! -d "$CURRENT_DIR"/resources/tool/resource_hacker ]]; then
        if [[ ! -f "$CURRENT_DIR"/resources/tool/resource_hacker.zip ]]; then
            # download the archive
            wget http://www.angusj.com/resourcehacker/resource_hacker.zip -P "$CURRENT_DIR"/tool
        fi
        mkdir -p "$CURRENT_DIR"/resources/tool/
        unzip "$CURRENT_DIR"/resources/tool/resource_hacker.zip -d "$CURRENT_DIR"/resources/tool/resource_hacker
        if [[ ! -d "$CURRENT_DIR"/resources/tool/resource_hacker ]]; then
            echo "resource hacker tool does not exist"
            return
        fi
        # remove the archive
        rm "$CURRENT_DIR"/resources/tool/resource_hacker.zip
    fi

    #if [[ ! -e "$EXECUTABLE.bak" ]]; then
        #cp "$EXECUTABLE" "$EXECUTABLE.bak"
    #fi

    cp "$DATA_DIR/game.ico" "$DATA_DIR/1.ico"

    wine "$CURRENT_DIR"/resources/tool/resource_hacker/ResourceHacker.exe -open "$EXECUTABLE" -save "$EXECUTABLE" -log "$CURRENT_DIR"/resources/tool/resource_hacker/resourcehacker.log -resource "$DATA_DIR/1.ico" -action addoverwrite -mask ICONGROUP,1,

    rm "$DATA_DIR/1.ico"
}

# Update the executable's icon
changeExeIcon

cd "$CURRENT_DIR"
makensis "$CURRENT_DIR/game.nsi"

# clean up
rm "$CURRENT_DIR/game.nsi"
