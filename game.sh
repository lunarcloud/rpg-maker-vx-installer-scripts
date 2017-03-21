#!/usr/bin/env bash
CURRENT_DIR=$(dirname "$(readlink -f "$0")")/
source "$CURRENT_DIR"/script-dialog/script-ui.sh #folder local version


relaunchIfNotVisible

APP_NAME="Game Launcher"
WINDOW_ICON="$CURRENT_DIR/game.png"

MACHINE_TYPE=`uname -m`
if [ ${MACHINE_TYPE} == 'x86_64' ]; then
  LAUNCH="$CURRENT_DIR"$(find . -maxdepth 1 -name '*.amd64')
else
  LAUNCH="$CURRENT_DIR"$(find . -maxdepth 1 -name '*x86')
fi

if [[ ! -f $LAUNCH ]]; then
    echo "Application file not found";
    exit 1;
fi
if [[ ! -x $LAUNCH ]]; then
    echo "Application file does not have executable permission";
    exit 2;
fi


#detect wine
if command -v wine 2>/dev/null; then
    ACTIVITY="Runtime Type"
    ANSWER=$(radiolist "How would you like to run the application? " 4  \
            "native" "MKXP: Native APIs" ON\
            "wine" "Wine: Original Windows APIs" OFF )
    if [ ${ANSWER} == 'wine' ]; then
        wine "$CURRENT_DIR"Game.exe
    else
        $LAUNCH
    fi
else
  $LAUNCH
fi
