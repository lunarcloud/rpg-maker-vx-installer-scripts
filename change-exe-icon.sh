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
    if [[ ! -d "$CURRENT_DIR"/tool/resource_hacker ]]; then
        if [[ ! -f "$CURRENT_DIR"/tool/resource_hacker.zip ]]; then
            # download the archive
            wget http://www.angusj.com/resourcehacker/resource_hacker.zip -P "$CURRENT_DIR"/tool
        fi
        unzip "$CURRENT_DIR"/tool/resource_hacker.zip -d "$CURRENT_DIR"/tool/resource_hacker
        if [[ ! -d "$CURRENT_DIR"/tool/resource_hacker ]]; then
            echo "resource hacker tool does not exist"
            exit 32;
        fi
        # remove the archive
        rm "$CURRENT_DIR"/tool/resource_hacker.zip
    fi

    #if [[ ! -e "$EXECUTABLE.bak" ]]; then
        #cp "$EXECUTABLE" "$EXECUTABLE.bak"
    #fi

    cp "$DATA_DIR/game.ico" "$DATA_DIR/1.ico"

    wine tool/resource_hacker/ResourceHacker.exe -open "$EXECUTABLE" -save "$EXECUTABLE" -log "$CURRENT_DIR"/tool/resource_hacker/resourcehacker.log -resource "$DATA_DIR/1.ico" -action addoverwrite -mask ICONGROUP,1,

    rm "$DATA_DIR/1.ico"
fi
