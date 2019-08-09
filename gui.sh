#!/bin/bash
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$CURRENT_DIR"/script-dialog/script-dialog.sh #folder local version

relaunchIfNotVisible

APP_NAME="Test Script"
if [[ -e "$CURRENT_DIR/game.png" ]]; then
  WINDOW_ICON="$CURRENT_DIR/game.png"
else
  WINDOW_ICON="$CURRENT_DIR/game.png.example"
fi


if [[ $# -eq 0 ]] ; then
  ACTIVITY="Data Directory Discovery"
  messagebox "Select gameinfo.conf"
  DATA_DIR=$(dirname "$(filepicker "$CURRENT_DIR" "open")")
else
    DATA_DIR="$1"
fi

if [ "$DATA_DIR" == "" ]; then
  exit 0;
fi

if [[ -f "$DATA_DIR/game.png" ]]; then
    WINDOW_ICON="$DATA_DIR/game.png"
fi

GAMEFOLDER=$(find "$DATA_DIR" ! -path "*_i386*" ! -path "*_amd64/*" ! -path "*.app*" ! -path "*.App*" -name 'Game.exe' -printf '%h\n' | sort -ur | tr -d '\n' | tr -d '\r')

if [[ ! -d "$GAMEFOLDER" ]]; then
    messagebox "No game folder found inside \"$DATA_DIR\""
    exit 31;
fi

ACTIVITY="Build Outputs"
ANSWER=($(checklist "What outputs do you want to build? " 7  \
                "win" "Windows: NSIS Installer" ON\
                "macdmg" "macOS: DMG with App Bundle and more inside" ON\
                "maczip" "macOS: Zip with App Bundle and more inside" OFF\
                "lin32" "Linux: 32-bit AppImage" OFF\
                "lin64" "Linux: 64-bit AppImage" ON\
                "deb32" "Linux: 32-bit Debian Package" OFF\
                "deb64" "Linux: 64-bit Debian Package" OFF))

if [[ "${ANSWER[@]}" == "" ]]; then
  exit 0;
fi

if [[ " ${ANSWER[@]} " =~ "macdmg" ]] || [[ " ${ANSWER[@]} " =~ "maczip" ]]; then
    MKXP_MAC="mkxp-6-8-2018-withrubyzlib.zip"

    if [[ ! -f "$CURRENT_DIR/$MKXP_MAC" ]]; then
        messagebox "Please '$MKXP_MAC' download from 'https://app.box.com/v/mkxpmacbuilds' to \"$CURRENT_DIR\"."
        exit 32;
    fi
fi

ACTIVITY="Building ${#ANSWER[*]} items..."
{
  progressbar_update 1

  if [[ " ${ANSWER[@]} " =~ "lin32" ]] && [[ " ${ANSWER[@]} " =~ "lin64" ]]; then
    bash build-appimage.sh "$DATA_DIR" "both"
  elif [[ " ${ANSWER[@]} " =~ "lin32" ]]; then
    bash build-appimage.sh "$DATA_DIR" "32"
  elif [[ " ${ANSWER[@]} " =~ "lin64" ]]; then
    bash build-appimage.sh "$DATA_DIR" "64"
  fi
  progressbar_update 30

  if [[ " ${ANSWER[@]} " =~ "deb32" ]] && [[ " ${ANSWER[@]} " =~ "deb64" ]]; then
    bash build-debian.sh "$DATA_DIR" "both"
  elif [[ " ${ANSWER[@]} " =~ "deb32" ]]; then
    bash build-debian.sh "$DATA_DIR" "32"
  elif [[ " ${ANSWER[@]} " =~ "deb64" ]]; then
    bash build-debian.sh "$DATA_DIR" "64"
  fi
  progressbar_update 60

  if [[ " ${ANSWER[@]} " =~ "macdmg" ]] && [[ " ${ANSWER[@]} " =~ "maczip" ]]; then
    bash build-macOS.sh "$DATA_DIR" "both"
  elif [[ " ${ANSWER[@]} " =~ "macdmg" ]]; then
    bash build-macOS.sh "$DATA_DIR" "dmg"
  elif [[ " ${ANSWER[@]} " =~ "maczip" ]]; then
    bash build-macOS.sh "$DATA_DIR" "zip"
  fi
  progressbar_update 80

  if [[ " ${ANSWER[@]} " =~ "win" ]]; then
    bash build-windows.sh "$DATA_DIR"
  fi
  progressbar_update 100
  sleep 0.2
  progressbar_finish
} | progressbar

messagebox "Finished building."
