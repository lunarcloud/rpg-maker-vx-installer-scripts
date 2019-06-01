 #!/bin/bash
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ $# -eq 0 ]] ; then
    DATA_DIR="."
else
    DATA_DIR="$1"
fi

if [[ -f "$DATA_DIR"/game.ico ]]; then

    # Get Variables
    EXECUTABLE=$(find "$DATA_DIR" ! -path "*_i386*" ! -path "*_amd64/*" ! -path "*.app*" -name 'Game.exe' -printf '%p')

    if [[ ! -e "$EXECUTABLE" ]]; then
        echo "No game executable found inside \"$DATA_DIR\""
        exit 31;
    fi

    # Ensure the tool exists
    if [[ ! -e "$CURRENT_DIR"/resource_hacker ]]; then
        if [[ ! -e "$CURRENT_DIR"/resource_hacker.zip ]]; then
            wget http://www.angusj.com/resourcehacker/resource_hacker.zip  -P "$CURRENT_DIR"/
        fi
        unzip "$CURRENT_DIR"/resource_hacker.zip -d "$CURRENT_DIR"/resource_hacker
        if [[ ! -e "$CURRENT_DIR"/resource_hacker ]]; then
            echo "resource hacker tool does not exist"
            exit 32;
        fi
    fi

    if [[ ! -e "$EXECUTABLE.bak" ]]; then
        cp "$EXECUTABLE" "$EXECUTABLE.bak"
    fi

    cp "$DATA_DIR/game.ico" "$DATA_DIR/1.ico"

    wine resource_hacker/ResourceHacker.exe -open "$EXECUTABLE" -save "$EXECUTABLE" -log "$CURRENT_DIR"/resourcehacker.log -resource "$DATA_DIR/1.ico" -action addoverwrite -mask ICONGROUP,1,

    rm "$DATA_DIR/1.ico"
fi
