#!/bin/bash

if [[ ! -e mkxp-20150204.tar.xz ]]; then
    #Get copy of MKXP
    wget http://ancurio.bplaced.net/mkxp/generic/mkxp-20150204.tar.xz # or latest version
    tar xf mkxp*.tar.xz
fi

if [[ $# -eq 0 ]] ; then
    DATA_DIR="."
else
    DATA_DIR="$1"
    ARCH="$2"
fi

if [ "$ARCH" != "32" ] && [ "$ARCH" != "64" ] && [ "$ARCH" != "both" ]; then
    ARCH="both"
fi

# Get Variables
GAMEFOLDER=$(find "$DATA_DIR" ! -path "*_i386*" ! -path "*_amd64/*" ! -path "*.app*" -name 'Game.exe' -printf '%h\n' | sort -ur | tr -d '\n' | tr -d '\r')

if [[ ! -d "$GAMEFOLDER" ]]; then
    echo "No game folder found inside \"$DATA_DIR\""
    exit 31;
fi

TITLE_UPPER=$(grep 'Title' "$GAMEFOLDER"/Game.ini | cut -d'=' -f 2 | tr -d '\n' | tr -d '\r')
TITLE_LOWER=$(echo $TITLE_UPPER  | tr '[:upper:]' '[:lower:]')
TITLE_LOWER_UNDERSCORE=$(echo $TITLE_LOWER  | sed -e 's/ /_/g' | sed -e 's/\.//g')
TITLE_LOWER_DASH=$(echo $TITLE_LOWER  | sed -e 's/ /-/g' | sed -e 's/\.//g')

COMPANY_UPPER=$(grep 'Company' $DATA_DIR/gameinfo.conf | cut -d'=' -f 2- | tr -d '\n' | tr -d '\r')
COMPANY_LOWER=$(echo $COMPANY_UPPER  | tr '[:upper:]' '[:lower:]')
COMPANY_LOWER_UNDERSCORE=$(echo $COMPANY_LOWER  | sed -e 's/ /_/g')
COMPANY_LOWER_DASH=$(echo $COMPANY_LOWER  | sed -e 's/ /-/g')

VERSION=$(grep 'Version' $DATA_DIR/gameinfo.conf | cut -d'=' -f 2 | tr -d '\n' | tr -d '\r')
SHORT_DESCRIPTION=$(grep 'Description' $DATA_DIR/gameinfo.conf | cut -d'=' -f 2 | tr -d '\n' | tr -d '\r')
DESCRIPTION=$(sed -n '/Description/,$p' $DATA_DIR/gameinfo.conf | cut -d'=' -f 2- | sed ':a;N;$!ba;s/\n/\\n\t/g')
MAINTANER=$(grep 'Maintainer' $DATA_DIR/gameinfo.conf | cut -d'=' -f 2 | tr -d '\n' | tr -d '\r')
HOMEPAGE=$(grep 'Homepage' $DATA_DIR/gameinfo.conf | cut -d'=' -f 2 | tr -d '\n' | tr -d '\r')

PACKAGENAME="$COMPANY_LOWER_DASH"-"$TITLE_LOWER_DASH"
EXECUTABLENAME="$TITLE_LOWER_DASH"
DEBIANNAME32="$PACKAGENAME"_"$VERSION"_i386
DEBIANNAME64="$PACKAGENAME"_"$VERSION"_amd64

# Create temp control file
echo "Creating control file..."
cp control control.temp
`sed -i "s/Version: \(.*\)/Version: $(echo "$VERSION" | sed -e 's/\./\\\./g')/"  ./control.temp`
`sed -i "s/Description: \(.*\)/Description: $( echo "$DESCRIPTION" | sed -e 's/\./\\\./g')/"  ./control.temp`
`sed -i "s/Maintainer: \(.*\)/Maintainer: $MAINTANER/"  ./control.temp`
`sed -i "s/Homepage: \(.*\)/Homepage: $HOMEPAGE/"  ./control.temp`
`sed -i "s/Package: \(.*\)/Package: $PACKAGENAME/"  ./control.temp`

# Create temp desktop file
echo "Creating desktop file..."
cp app.desktop app.desktop.temp
`sed -i "s/Comment=\(.*\)/Comment=$( echo "$SHORT_DESCRIPTION" | sed -e 's/\./\\\./g')/" ./app.desktop.temp`
`sed -i "s/Name=\(.*\)/Name=$TITLE_UPPER/"  ./app.desktop.temp`
`sed -i "s/Exec=\(.*\)/Exec=\/opt\/"$PACKAGENAME"\/game.sh/"  ./app.desktop.temp`
`sed -i "s/Path=\(.*\)/Path=\/opt\/"$PACKAGENAME"\//"  ./app.desktop.temp`
`sed -i "s/Icon=\(.*\)/Icon=\/opt\/"$PACKAGENAME"\/game.png/"  ./app.desktop.temp`

#Create 32bit first

# Create fakeroot
echo "Creating fakeroot..."
mkdir -p "$DEBIANNAME32"/DEBIAN
mkdir -p "$DEBIANNAME32"/opt/"$PACKAGENAME"
mkdir -p "$DEBIANNAME32"/usr/share/applications/
mkdir -p "$DEBIANNAME32"/usr/share/pixmaps/

# Copy file into them
echo "Populating fakeroot..."
cp ./control.temp       "$DEBIANNAME32"/DEBIAN/control
cp -r "$GAMEFOLDER"/*   "$DEBIANNAME32"/opt/"$PACKAGENAME"/
cp game.sh              "$DEBIANNAME32"/opt/"$PACKAGENAME"/
cp mkxp.linux.conf      "$DEBIANNAME32"/opt/"$PACKAGENAME"/mkxp.conf

#Copy script-dialog
mkdir "$DEBIANNAME32"/opt/"$PACKAGENAME"/script-dialog
cp ./script-dialog/script-ui.sh "$DEBIANNAME32"/opt/"$PACKAGENAME"/script-dialog/

if [ -f $DATA_DIR/license.txt ]; then
    cp -r $DATA_DIR/license.txt "$DEBIANNAME32"/opt/"$PACKAGENAME"/LICENSE
fi

if [ -f $DATA_DIR/company.png ]; then
    cp $DATA_DIR/company.png "$DEBIANNAME32"/opt/"$PACKAGENAME"/
fi

cp $DATA_DIR/game.png "$DEBIANNAME32"/opt/"$PACKAGENAME"/
cp ./app.desktop.temp "$DEBIANNAME32"/usr/share/applications/"$PACKAGENAME".desktop

if [ "$ARCH" == "32" ] || [ "$ARCH" == "both" ]; then

    # arch specific stuff
    sed -i "s/Architecture: \(.*\)/Architecture: i386/"  "$DEBIANNAME32"/DEBIAN/control
    cp -r mkxp-*/lib        "$DEBIANNAME32"/opt/"$PACKAGENAME"/
    cp mkxp-*/mkxp.x86      "$DEBIANNAME32"/opt/"$PACKAGENAME"/"$EXECUTABLENAME".x86

    # Build the package
    echo "attempting to build $DEBIANNAME32.deb ..."
    dpkg-deb --build "$DEBIANNAME32" "$DEBIANNAME32".deb

    # Remove arch specific files
    rm "$DEBIANNAME32"/opt/"$PACKAGENAME"/"$EXECUTABLENAME".x86
    rm -r "$DEBIANNAME32"/opt/"$PACKAGENAME"/lib
fi

#Create 64bit

mv "$DEBIANNAME32" "$DEBIANNAME64"

if [ "$ARCH" == "64" ] || [ "$ARCH" == "both" ]; then

    # arch specific stuff
    cp mkxp-*/mkxp.amd64      "$DEBIANNAME64"/opt/"$PACKAGENAME"/"$EXECUTABLENAME".amd64
    cp -r mkxp-*/lib64        "$DEBIANNAME64"/opt/"$PACKAGENAME"/lib64

    #fix architecture
    `sed -i "s/Architecture: \(.*\)/Architecture: amd64/"  "$DEBIANNAME64"/DEBIAN/control`

    # Build the package
    echo "attempting to build $DEBIANNAME64.deb ..."
    dpkg-deb --build "$DEBIANNAME64" "$DEBIANNAME64".deb
fi

# Cleanup
echo "Cleaning up..."
rm control.temp
rm app.desktop.temp
rm -r "$DEBIANNAME64"

exit 0;

