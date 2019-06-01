#!/bin/bash
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Get Variables

if [[ $# -eq 0 ]] ; then
    DATA_DIR="."
else
    DATA_DIR="$1"
fi

GAMEFOLDER=$(find "$DATA_DIR" ! -path "*_i386*" ! -path "*_amd64/*" ! -path "*.app*" -name 'Game.exe' -printf '%h\n' | sort -ur | tr -d '\n' | tr -d '\r')

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
cp "$CURRENT_DIR"/game.nsi.template "$CURRENT_DIR"/game.nsi
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
"$CURRENT_DIR/change-exe-icon.sh"

cd "$CURRENT_DIR"
makensis "$CURRENT_DIR/game.nsi"

# clean up
rm "$CURRENT_DIR/game.nsi"
