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
TITLE_LOWER_UNDERSCORE=$(echo $TITLE_LOWER  | sed -e 's/ /_/g')
TITLE_LOWER_DASH=$(echo $TITLE_LOWER  | sed -e 's/ /-/g')

COMPANY_UPPER=$(grep 'Company' ./gameinfo.conf | cut -d'=' -f 2 | tr -d '\n' | tr -d '\r')
COMPANY_LOWER=$(echo $COMPANY_UPPER  | tr '[:upper:]' '[:lower:]')
COMPANY_LOWER_UNDERSCORE=$(echo $COMPANY_LOWER  | sed -e 's/ /_/g')
COMPANY_LOWER_DASH=$(echo $COMPANY_LOWER  | sed -e 's/ /-/g')

VERSION=$(grep 'Version' ./gameinfo.conf | cut -d'=' -f 2 | tr -d '\n' | tr -d '\r')
DESCRIPTION=$(grep 'Description' ./gameinfo.conf | cut -d'=' -f 2 | tr -d '\n' | tr -d '\r')
MAINTANER=$(grep 'Maintainer' ./gameinfo.conf | cut -d'=' -f 2 | tr -d '\n' | tr -d '\r')
HOMEPAGE=$(grep 'Homepage' ./gameinfo.conf | cut -d'=' -f 2 | tr -d '\n' | tr -d '\r')

PACKAGENAME="$COMPANY_LOWER_UNDERSCORE"-"$TITLE_LOWER_DASH"
DEBIANNAME="$PACKAGENAME-$VERSION"_all

# Create temp control file
echo "Creating control file..."
cp control control.temp
`sed -i "s/Version: \(.*\)/Version: $VERSION/"  ./control.temp`
`sed -i "s/Description: \(.*\)/Description: $DESCRIPTION/"  ./control.temp`
`sed -i "s/Maintainer: \(.*\)/Maintainer: $MAINTANER/"  ./control.temp`
`sed -i "s/Homepage: \(.*\)/Homepage: $HOMEPAGE/"  ./control.temp`
`sed -i "s/Package: \(.*\)/Package: $PACKAGENAME/"  ./control.temp`

# Create temp desktop file
echo "Creating desktop file..."
cp app.desktop app.desktop.temp
`sed -i "s/Comment=\(.*\)/Comment=$DESCRIPTION/"  ./app.desktop.temp`
`sed -i "s/Name=\(.*\)/Name=$TITLE_UPPER/"  ./app.desktop.temp`
`sed -i "s/Name=\(.*\)/Name=$TITLE_UPPER/"  ./app.desktop.temp`
`sed -i "s/Exec=\(.*\)/Exec=wine \/opt\/"$PACKAGENAME"\/game.sh/"  ./app.desktop.temp`
`sed -i "s/Icon=\(.*\)/Icon=\/opt\/"$PACKAGENAME"\/game.png/"  ./app.desktop.temp`

# Create fakeroot
echo "Creating fakeroot..."
mkdir -p "$DEBIANNAME"/DEBIAN
mkdir -p "$DEBIANNAME"/opt/"$PACKAGENAME"
mkdir -p "$DEBIANNAME"/usr/share/applications/
mkdir -p "$DEBIANNAME"/usr/share/pixmaps/

# Copy file into them
echo "Populating fakeroot..."
cp ./control.temp "$DEBIANNAME"/DEBIAN/control
cp -r "$GAMEFOLDER"/* "$DEBIANNAME"/opt/"$PACKAGENAME"/
cp -r mkxp-*/* "$DEBIANNAME"/opt/"$PACKAGENAME"/
cp mkxp.conf "$DEBIANNAME"/opt/"$PACKAGENAME"/

#Copy script-dialog
mkdir "$DEBIANNAME"/opt/"$PACKAGENAME"/script-dialog
cp ./script-dialog/script-ui.sh "$DEBIANNAME"/opt/"$PACKAGENAME"/script-dialog/

# rename mkxp files
mv "$DEBIANNAME"/opt/"$PACKAGENAME"/mkxp.amd64 "$DEBIANNAME"/opt/"$PACKAGENAME"/"$PACKAGENAME".amd64
mv "$DEBIANNAME"/opt/"$PACKAGENAME".x86 "$DEBIANNAME"/opt/"$PACKAGENAME"/"$PACKAGENAME".x86

if [ -f ./license.txt ]; then
	cp -r ./license.txt "$DEBIANNAME"/opt/"$PACKAGENAME"/LICENSE
fi

cp ./game.png "$DEBIANNAME"/opt/"$PACKAGENAME"/
cp ./app.desktop.temp "$DEBIANNAME"/usr/share/applications/"$PACKAGENAME".desktop

# Build the package
dpkg-deb --build "$DEBIANNAME" "$DEBIANNAME".deb

# Cleanup
echo "Cleaning up..."
rm -r "$DEBIANNAME"

echo "Finished!"
exit 0


