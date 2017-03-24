#!/bin/bash
CURRENT_DIR=$(dirname "$(readlink -f "$0")")/
source "$CURRENT_DIR"/script-dialog/script-ui.sh #folder local version

relaunchIfNotVisible

APP_NAME="Test Script"
WINDOW_ICON="$CURRENT_DIR/game.png.example"


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

GAMEFOLDER=$(find "$DATA_DIR" ! -path "*.app*" -name 'Game.exe' -printf '%h\n' | sort -ur | tr -d '\n' | tr -d '\r')

if [[ ! -d "$GAMEFOLDER" ]]; then
    messagebox "No game folder found inside \"$DATA_DIR\""
    exit 404;
fi

ACTIVITY="Build Outputs"
ANSWER=($(checklist "What outputs do you want to build? " 5  \
                "deb32" "Linux: 32-bit Debian Package" ON\
                "deb64" "Linux: 64-bit Debian Package" ON\
                "win" "Windows: NSIS Installer" ON\
                "macdmg" "macOS: DMG with App Bundle and more inside" ON\
                "maczip" "macOS: Zipped App Bundle" OFF ))

if [[ "${ANSWER[@]}" == "" ]]; then
  exit 0;
fi

ACTIVITY="Building ${#ANSWER[*]} items..."
{
    echo "$DATA_DIR"
  progressbar_update 1

  if [[ " ${ANSWER[@]} " =~ "deb32" ]] && [[ " ${ANSWER[@]} " =~ "deb64" ]]; then
    bash build-debian.sh "$DATA_DIR" "both"
  elif [[ " ${ANSWER[@]} " =~ "deb32" ]]; then
    bash build-debian.sh "$DATA_DIR" "32"
  elif [[ " ${ANSWER[@]} " =~ "deb64" ]]; then
    bash build-debian.sh "$DATA_DIR" "64"
  fi
  progressbar_update 40

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

  sleep 1
} | progressbar
progressbar_finish
