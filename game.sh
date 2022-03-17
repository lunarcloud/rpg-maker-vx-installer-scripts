#!/usr/bin/env bash
CURRENT_DIR=$(dirname "$(readlink -f "$0")")/
GUI=true
OPTIONS="$@"
source "$CURRENT_DIR"/script-dialog/script-dialog.sh #folder local version

relaunchIfNotVisible

APP_NAME="Game Launcher"
WINDOW_ICON="$CURRENT_DIR/game.png"

LICENSE="$CURRENT_DIR"LICENSE
APPDIR="$HOME"/.local/share/aoeu
LICENSE_ACCEPTED="$APPDIR"/LICENSE-accepted

mkdir -p "$APPDIR"

if [[ ! -f $LICENSE_ACCEPTED &&  -f $LICENSE ]]; then
    ACTIVITY="License"
    messagebox "You must accept the following license to use this software."
    displayFile "$CURRENT_DIR"/LICENSE
    yesno "Do you agree to and accept the license?";

    ANSWER=$?
    if [ $ANSWER -eq 0 ]; then
        touch "$LICENSE_ACCEPTED"
    else
		ACTIVITY="Declined"
        messagebox "Please uninstall this software or re-launch and accept the terms."
        exit 1;
    fi
fi

beginswith() { case $2 in "$1"*) true;; *) false;; esac; }

MACHINE_TYPE=`uname -m`

LAUNCH_AMD64=$(find "$CURRENT_DIR" -maxdepth 1 -name '*.amd64')
LAUNCH_X86=$(find "$CURRENT_DIR" -maxdepth 1 -name '*x86')

if [ ${MACHINE_TYPE} == 'x86_64' ]; then
    MKXP_SUPPORT=true
    LAUNCH=$LAUNCH_AMD64
    LIBPATH="$CURRENT_DIR/lib64"
    
    # Use 32bit if the 64bit isn't available
    if [[ ! -f $LAUNCH_AMD64 ]]; then
			LAUNCH=$LAUNCH_X86
    fi
    # Use 'lib' if there's no 'lib64'
    if [[ ! -f $LIBPATH ]]; then
			LIBPATH="$CURRENT_DIR/lib"
    fi    
elif [ ${MACHINE_TYPE} == 'x86' ]; then
    MKXP_SUPPORT=true
    LAUNCH=$LAUNCH_X86
    LIBPATH="$CURRENT_DIR/lib"
elif beginswith arm "$MACHINE_TYPE"; then
    MKXP_SUPPORT=true
    LAUNCH=$(find "$CURRENT_DIR" -maxdepth 1 -name '*arm')
    LIBPATH="$CURRENT_DIR/lib"
else
    MKXP_SUPPORT=false
fi

if [[ ! -f $LAUNCH ]]; then
    ACTIVITY="Unable to launch"
    messagebox "Application file not found";
    exit 2;
fi
if [[ ! -x $LAUNCH ]]; then
    ACTIVITY="Unable to launch"
    messagebox "Application file does not have executable permission";
    exit 3;
fi

#detect wine
if [ $MKXP_SUPPORT == true ] ; then # no wine, only mkxp
	LD_LIBRARY_PATH="$LIBPATH" $LAUNCH "$OPTIONS"
elif command -v wine 2>/dev/null; then # have wine
	wine "$CURRENT_DIR"Game.exe
else # neither wine nor mkxp
    ACTIVITY="Unable to launch"
    messagebox "Unable to launch on machine type $MACHINE_TYPE without wine installed";
fi

exit 0
