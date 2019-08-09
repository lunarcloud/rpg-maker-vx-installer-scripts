#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

LICENSE="$SCRIPT_DIR"/LICENSE
APPDIR="$HOME/Library/MyGame"
LICENSE_ACCEPTED="$APPDIR"/LICENSE-accepted

mkdir -p "$APPDIR"

if [[ ! -f $LICENSE_ACCEPTED && -f $LICENSE ]]; then
    osascript -e "display dialog \"You must accept the following license to use this software.\" buttons {\"OK\"} default button 1"

    text=$(< "$SCRIPT_DIR/LICENSE")
    ANSWER=$(osascript -e "display dialog \" $text \" buttons {\"Accept\", \"Decline\"} default button 2 ")

    if [ "$ANSWER" = "button returned:Accept" ]; then
        touch "$LICENSE_ACCEPTED"
    else
        osascript -e "display dialog \"Please uninstall this software or re-launch and accept the terms.\" buttons {\"OK\"} default button 1"
        exit 1;
    fi
fi

"$SCRIPT_DIR/mkxp"

exit 0
