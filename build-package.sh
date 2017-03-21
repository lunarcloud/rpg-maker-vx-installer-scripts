#!/bin/bash

if [[ ! -e mkxp-20150204.tar.xz ]]; then
    #Get copy of MKXP
    wget http://ancurio.bplaced.net/mkxp/generic/mkxp-20150204.tar.xz # or latest version
    tar xf mkxp*.tar.xz
fi

# Get Variables
GAMEFOLDER=$(find ./ -name 'Game.exe' -printf '%h\n' | sort -u | tr -d '\n' | tr -d '\r')

TITLE_UPPER=$(grep 'Title' "$GAMEFOLDER"/Game.ini | cut -d'=' -f 2 | tr -d '\n' | tr -d '\r')
TITLE_LOWER=$(echo $TITLE_UPPER  | tr '[:upper:]' '[:lower:]')
TITLE_LOWER_UNDERSCORE=$(echo $TITLE_LOWER  | sed -e 's/ /_/g' | sed -e 's/\.//g')
TITLE_LOWER_DASH=$(echo $TITLE_LOWER  | sed -e 's/ /-/g' | sed -e 's/\.//g')

COMPANY_UPPER=$(grep 'Company' ./gameinfo.conf | cut -d'=' -f 2- | tr -d '\n' | tr -d '\r')
COMPANY_LOWER=$(echo $COMPANY_UPPER  | tr '[:upper:]' '[:lower:]')
COMPANY_LOWER_UNDERSCORE=$(echo $COMPANY_LOWER  | sed -e 's/ /_/g')
COMPANY_LOWER_DASH=$(echo $COMPANY_LOWER  | sed -e 's/ /-/g')

VERSION=$(grep 'Version' ./gameinfo.conf | cut -d'=' -f 2 | tr -d '\n' | tr -d '\r')
SHORT_DESCRIPTION=$(grep 'Description' ./gameinfo.conf | cut -d'=' -f 2 | tr -d '\n' | tr -d '\r')
DESCRIPTION=$(sed -n '/Description/,$p' ./gameinfo.conf | cut -d'=' -f 2- | sed ':a;N;$!ba;s/\n/\\n\t/g')
MAINTANER=$(grep 'Maintainer' ./gameinfo.conf | cut -d'=' -f 2 | tr -d '\n' | tr -d '\r')
HOMEPAGE=$(grep 'Homepage' ./gameinfo.conf | cut -d'=' -f 2 | tr -d '\n' | tr -d '\r')

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
#`sed -i "s/Name=\(.*\)/Name=$TITLE_UPPER/"  ./app.desktop.temp`
`sed -i "s/Exec=\(.*\)/Exec=\/opt\/"$PACKAGENAME"\/game.sh/"  ./app.desktop.temp`
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
cp mkxp.conf            "$DEBIANNAME32"/opt/"$PACKAGENAME"/
cp -r mkxp-*/lib        "$DEBIANNAME32"/opt/"$PACKAGENAME"/
cp mkxp-*/mkxp.x86      "$DEBIANNAME32"/opt/"$PACKAGENAME"/"$EXECUTABLENAME".x86

#Copy script-dialog
mkdir "$DEBIANNAME32"/opt/"$PACKAGENAME"/script-dialog
cp ./script-dialog/script-ui.sh "$DEBIANNAME32"/opt/"$PACKAGENAME"/script-dialog/

#fix architecture
`sed -i "s/Architecture: \(.*\)/Architecture: i386/"  "$DEBIANNAME32"/DEBIAN/control`

if [ -f ./license.txt ]; then
	cp -r ./license.txt "$DEBIANNAME32"/opt/"$PACKAGENAME"/LICENSE
fi

cp ./game.png "$DEBIANNAME32"/opt/"$PACKAGENAME"/
cp ./app.desktop.temp "$DEBIANNAME32"/usr/share/applications/"$PACKAGENAME".desktop

# Build the package
echo "attempting to build $DEBIANNAME32.deb ..."
dpkg-deb --build "$DEBIANNAME32" "$DEBIANNAME32".deb

#Create 64bit

mv "$DEBIANNAME32" "$DEBIANNAME64"

#switch mkxp versions
rm "$DEBIANNAME64"/opt/"$PACKAGENAME"/"$EXECUTABLENAME".x86
cp mkxp-*/mkxp.amd64      "$DEBIANNAME64"/opt/"$PACKAGENAME"/"$EXECUTABLENAME".amd64
rm "$DEBIANNAME64"/opt/"$PACKAGENAME"/lib
cp -r mkxp-*/lib64        "$DEBIANNAME64"/opt/"$PACKAGENAME"/lib64

#fix architecture
`sed -i "s/Architecture: \(.*\)/Architecture: amd64/"  "$DEBIANNAME64"/DEBIAN/control`

# Build the package
echo "attempting to build $DEBIANNAME64.deb ..."
dpkg-deb --build "$DEBIANNAME64" "$DEBIANNAME64".deb

# Cleanup
echo "Cleaning up..."
rm -r "$DEBIANNAME64"


echo "Finished!"
exit 0


