 #!/bin/bash

if [[ ! -e resource_hacker.zip ]]; then
    #Get copy of Resource Hacker
    wget http://www.angusj.com/resourcehacker/resource_hacker.zip # or latest version
    unzip resource_hacker.zip -d resource_hacker
fi


if [[ $# -eq 0 ]] ; then
    DATA_DIR="."
else
    DATA_DIR="$1"
fi

# Get Variables
EXECUTABLE=$(find "$DATA_DIR" ! -path "*_i386*" ! -path "*_amd64/*" ! -path "*.app*" -name 'Game.exe' -printf '%p')

if [[ ! -e "$EXECUTABLE" ]]; then
    echo "No game executable found inside \"$DATA_DIR\""
    exit 31;
fi

cp "$EXECUTABLE" "$EXECUTABLE.bak"
cp "$DATA_DIR/game.ico" "$DATA_DIR/1.ico"

wine resource_hacker/ResourceHacker.exe -open "$EXECUTABLE" -save "$EXECUTABLE" -log ./resourcehacker.log -resource "$DATA_DIR/1.ico" -action addoverwrite -mask ICONGROUP,MAINICON,

rm "$DATA_DIR/1.ico"
