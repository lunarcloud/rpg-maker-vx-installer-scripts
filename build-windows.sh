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
if [ "$PACKAGING" != "folder" ] && [ "$PACKAGING" != "installer" ] && [ "$PACKAGING" != "both" ]; then
    PACKAGING="both"
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
INSTALLER_FILE="Install $NAME $VERSION.exe"

# Copy Original Game folder to the output one
if [[ -d "$OUTPUT_DIR/$NAME" ]]; then
    rm -r "$OUTPUT_DIR/$NAME"
fi
mkdir -p "$OUTPUT_DIR/$NAME"
cp -ra "$GAMEFOLDER/."   "$OUTPUT_DIR/$NAME"

# Update nsi file
echo "Creating nsi file..."
cp "$CURRENT_DIR"/resources/windows/game.nsi.template "$CURRENT_DIR"/game.nsi
sed -i "s#define APP_DIR \"\(.*\)\"#define APP_DIR \"$(echo "$OUTPUT_DIR/$NAME" | sed -e 's/\./\\\./g')\"#"  "$CURRENT_DIR/game.nsi"
sed -i "s/define PRODUCT_NAME \"\(.*\)\"/define PRODUCT_NAME \"$(echo "$NAME" | sed -e 's/\./\\\./g')\"/"  "$CURRENT_DIR/game.nsi"
sed -i "s/define PRODUCT_VERSION \"\(.*\)\"/define PRODUCT_VERSION \"$(echo "$VERSION" | sed -e 's/\./\\\./g')\"/"  "$CURRENT_DIR/game.nsi"
sed -i "s/define PRODUCT_PUBLISHER \"\(.*\)\"/define PRODUCT_PUBLISHER \"$(echo "$PUBLISHER" | sed -e 's/\./\\\./g')\"/"  "$CURRENT_DIR/game.nsi"
sed -i "s/define PRODUCT_WEB_SITE \"\(.*\)\"/define PRODUCT_WEB_SITE \"$(echo "$WEB_SITE" | sed -e 's/\./\\\./g')\"/"  "$CURRENT_DIR/game.nsi"
sed -i "s/define INSTALLER_FILE \"\(.*\)\"/define INSTALLER_FILE \"$(echo "$INSTALLER_FILE" | sed -e 's/\./\\\./g')\"/"  "$CURRENT_DIR/game.nsi"

if [ -f "$DATA_DIR"/installer.ico ]; then
    sed -i "s#define MUI_ICON \"\(.*\)\"#define MUI_ICON \"$DATA_DIR/installer.ico\"#"  "$CURRENT_DIR/game.nsi"
else
    sed -i "s#define MUI_ICON \"\(.*\)\"#define MUI_ICON \"\$\{NSISDIR\}\\\\Contrib\\\\Graphics\\\\Icons\\\\modern-install.ico\"#"  "$CURRENT_DIR/game.nsi"
fi

# Copy MKXP-Z Engine
cp -ra "$CURRENT_DIR/engine/windows/."   "$OUTPUT_DIR/$NAME/"

# Overwrite config
cp "$CURRENT_DIR/resources/mkxp.json"   "$OUTPUT_DIR/$NAME/mkxp.json"

function changeExeIcon() {
    EXECUTABLE=$1
    echo "updating icon ($EXECUTABLE)"

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

    cp "$DATA_DIR/game.ico" "$DATA_DIR/1.ico"

    wine "$CURRENT_DIR"/resources/tool/resource_hacker/ResourceHacker.exe -open "$EXECUTABLE" -save "$EXECUTABLE" -log "$CURRENT_DIR"/resources/tool/resource_hacker/resourcehacker.log -resource "$DATA_DIR/1.ico" -action addoverwrite -mask ICONGROUP,1,

    rm "$DATA_DIR/1.ico"
}

# Add icon for mkxp to use
if [[ -f "$DATA_DIR"/game.png ]]; then
    cp "$DATA_DIR/game.png" "$OUTPUT_DIR/$NAME/"
fi

# Update Exe Icons
if [[ -f "$DATA_DIR"/game.ico ]]; then
    EXECUTABLE=$(find "$OUTPUT_DIR/$NAME" ! -path "*_i386*" ! -path "*_amd64/*" ! -path "*.app*" -name 'Game.exe' -printf '%p')

    if [[ ! -e "$EXECUTABLE" ]]; then
        echo "No game executable found inside \"$DATA_DIR\""
        return
    fi

    # Update the Main's icon
    changeExeIcon "$EXECUTABLE"
    changeExeIcon "$OUTPUT_DIR/$NAME/mkxp-z.exe"
fi

# If "installer" or "both"
if [ "$PACKAGING" != "folder" ]; then
    # Build the installer
    cd "$CURRENT_DIR"
    makensis "$CURRENT_DIR/game.nsi"
    mv "$INSTALLER_FILE" "$OUTPUT_DIR/"
fi

# If not "folder" or "both"
if [ "$PACKAGING" == "installer" ]; then
    # Remove the folder
    rm -r "$OUTPUT_DIR/$NAME"
fi

# clean up
rm "$CURRENT_DIR/game.nsi"
