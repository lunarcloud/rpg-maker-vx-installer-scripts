#!/usr/bin/env bash
CURRENT_DIR=$(dirname "$(readlink -f "$0")")/
source "$CURRENT_DIR"/script-dialog/script-ui.sh #folder local version

relaunchIfNotVisible

APP_NAME="Game Launcher"
WINDOW_ICON="$CURRENT_DIR/game.png"

LICENSE="$CURRENT_DIR"LICENSE
LICENSE_ACCEPTED="$LICENSE"-accepted

if [[ ! -f $LICENSE_ACCEPTED &&  -f $LICENSE ]]; then
    ACTIVITY="License"
    messagebox "You must accept the following license to use this software."
    displayFile "$CURRENT_DIR"/LICENSE
    yesno "Do you agree to and accept the license?";

    ANSWER=$?
    ACTIVITY="Declined"
    if [ $ANSWER -eq 0 ]; then
        touch "$LICENSE_ACCEPTED"
    else
        messagebox "Please uninstall this software or re-launch and accept the terms."
        exit 1;
    fi
fi

MACHINE_TYPE=`uname -m`
if [ ${MACHINE_TYPE} == 'x86_64' ]; then
    MKXP_SUPPORT=true
    LAUNCH="$CURRENT_DIR"$(find . -maxdepth 1 -name '*.amd64')
elif [ ${MACHINE_TYPE} == 'x86_64' ]; then
    MKXP_SUPPORT=true
    LAUNCH="$CURRENT_DIR"$(find . -maxdepth 1 -name '*x86')
else
    MKXP_SUPPORT=false
fi

if [[ ! -f $LAUNCH ]]; then
    echo "Application file not found";
    exit 2;
fi
if [[ ! -x $LAUNCH ]]; then
    echo "Application file does not have executable permission";
    exit 3;
fi


#detect wine
if command -v wine 2>/dev/null; then # have wine
    if [ $MKXP_SUPPORT == true ] ; then # also have mkxp executable
        ACTIVITY="Runtime Type"
        ANSWER=$(radiolist "How would you like to run the application? " 2  \
                "mkxp" "MKXP: Native APIs" ON\
                "wine" "Wine: Original Windows APIs" OFF )
        if [ ${ANSWER} == 'wine' ]; then # chose wine
            wine "$CURRENT_DIR"Game.exe
        elif [ ${ANSWER} == 'mkxp' ]; then # chose mkxp
            $LAUNCH
        else # chose neither
            exit 0
        fi
    else # don't have mkxp executable
        wine "$CURRENT_DIR"Game.exe
    fi
elif [ $MKXP_SUPPORT == true ] ; then # no wine, only mkxp
    $LAUNCH
else # neither wine nor mkxp
    ACTIVITY="Unable to launch"
    messagebox "Unable to launch on machine type $MACHINE_TYPE without wine installed";
fi

exit 0
