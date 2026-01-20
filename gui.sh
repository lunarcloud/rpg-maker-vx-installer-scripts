#!/bin/bash
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# shellcheck source=./script-dialog.sh
source "$CURRENT_DIR"/script-dialog/script-dialog.sh #folder local version

relaunch-if-not-visible

# shellcheck disable=SC2034  # APP_NAME is used by script-dialog.sh functions
APP_NAME="RPG Maker Installer Builder"

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
    # shellcheck disable=SC2034  # WINDOW_ICON is used by script-dialog.sh functions
    WINDOW_ICON="$DATA_DIR/game.png"
fi

GAMEFOLDER=$(find "$DATA_DIR" ! -path "*_i386*" ! -path "*_amd64/*" ! -path "*.app*" ! -path "*.App*" -name 'Game.exe' -printf '%h\n' | sort -ur | tr -d '\n' | tr -d '\r')

if [[ ! -d "$GAMEFOLDER" ]]; then
    message-error "No game folder found inside \"$DATA_DIR\""
    exit 31;
fi

# Dialog 1: Choose Platforms
# shellcheck disable=SC2034  # ACTIVITY is used by script-dialog.sh functions
ACTIVITY="Choose Platforms"
mapfile -t PLATFORMS < <(checklist "Which platforms do you want to build for?" 3 \
                "windows" "Windows" ON \
                "macos" "macOS" ON \
                "linux" "Linux" ON)

if [[ "${#PLATFORMS[@]}" -eq 0 ]]; then
  exit 0;
fi

# Dialog 2 & 3: For each platform, choose packaging and engine options
WINDOWS_PACKAGING=""
WINDOWS_ENGINE=""
MACOS_PACKAGING=""
LINUX_ARCH=""

for platform in "${PLATFORMS[@]}"; do
  if [[ "$platform" == "windows" ]]; then
    # Dialog for Windows Packaging
    ACTIVITY="Windows Packaging"
    WINDOWS_PACKAGING=$(radiolist "Choose Windows packaging format:" 3 \
                        "both" "Both Folder and Installer" ON \
                        "installer" "Installer Only" OFF \
                        "folder" "Folder Only" OFF)
    
    if [[ "$WINDOWS_PACKAGING" == "" ]]; then
      exit 0;
    fi
    
    # Dialog for Windows Engine
    ACTIVITY="Windows Engine"
    WINDOWS_ENGINE=$(radiolist "Choose Windows engine:" 3 \
                     "both" "Both Classic and Enhanced" ON \
                     "enhanced" "Enhanced (MKXP-Z) Only" OFF \
                     "classic" "Classic (Original) Only" OFF)
    
    if [[ "$WINDOWS_ENGINE" == "" ]]; then
      exit 0;
    fi
  elif [[ "$platform" == "macos" ]]; then
    # Dialog for macOS Packaging
    ACTIVITY="macOS Packaging"
    MACOS_PACKAGING=$(radiolist "Choose macOS packaging format:" 3 \
                      "dmg" "DMG Only" ON \
                      "zip" "ZIP Only" OFF \
                      "both" "Both DMG and ZIP" OFF)
    
    if [[ "$MACOS_PACKAGING" == "" ]]; then
      exit 0;
    fi
  elif [[ "$platform" == "linux" ]]; then
    # Dialog for Linux Architecture
    ACTIVITY="Linux Architecture"
    LINUX_ARCH=$(radiolist "Choose Linux architecture:" 2 \
                 "64" "64-bit Only" ON \
                 "both" "Both 32-bit and 64-bit" OFF)
    
    if [[ "$LINUX_ARCH" == "" ]]; then
      exit 0;
    fi
  fi
done

# Build selected platforms
# shellcheck disable=SC2034  # ACTIVITY is used by script-dialog.sh functions
ACTIVITY="Building for ${#PLATFORMS[*]} platform(s)..."
{
  progressbar_update 1
  
  PLATFORM_COUNT=${#PLATFORMS[@]}
  PLATFORM_INDEX=0

  for platform in "${PLATFORMS[@]}"; do
    if [[ "$platform" == "linux" ]]; then
      bash "$CURRENT_DIR/build-linux.sh" "$DATA_DIR" "$LINUX_ARCH"
    elif [[ "$platform" == "macos" ]]; then
      bash "$CURRENT_DIR/build-macOS.sh" "$DATA_DIR" "$MACOS_PACKAGING"
    elif [[ "$platform" == "windows" ]]; then
      bash "$CURRENT_DIR/build-windows.sh" "$DATA_DIR" "$WINDOWS_PACKAGING" "" "$WINDOWS_ENGINE"
    fi
    
    PLATFORM_INDEX=$((PLATFORM_INDEX + 1))
    # Calculate progress as percentage completed: (completed / total) * 100
    CURRENT_PROGRESS=$((PLATFORM_INDEX * 100 / PLATFORM_COUNT))
    progressbar_update "$CURRENT_PROGRESS"
  done
  
  progressbar_update 100
  sleep 0.2
  progressbar_finish
} | progressbar

message-info "Finished building."
