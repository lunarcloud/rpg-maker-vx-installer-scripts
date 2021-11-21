#!/bin/bash
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ $# -eq 0 ]] ; then
    DATA_DIR="."
else
    DATA_DIR="$1"
fi

# Get Variables
GAMEFOLDER=$(find "$DATA_DIR" ! -path "*_i386*" ! -path "*_amd64/*" ! -path "*.app*" ! -path "*.App*" ! -path "*flatpak/*" ! -path "*gamedir/*" -name 'Game.exe' -printf '%h\n' | sort -ur | tr -d '\n' | tr -d '\r')

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

ID=$(grep 'Id' $DATA_DIR/gameinfo.conf | cut -d'=' -f 2 | tr -d '\n' | tr -d '\r' | tr -d '[:space:]')
VERSION=$(grep 'Version' $DATA_DIR/gameinfo.conf | cut -d'=' -f 2 | tr -d '\n' | tr -d '\r')
SHORT_DESCRIPTION=$(grep 'Description' $DATA_DIR/gameinfo.conf | cut -d'=' -f 2 | tr -d '\n' | tr -d '\r')
DESCRIPTION=$(sed -n '/Description/,$p' $DATA_DIR/gameinfo.conf | cut -d'=' -f 2- | sed ':a;N;$!ba;s/\n/\\n/g;s/	/ /g')
MAINTANER=$(grep 'Maintainer' $DATA_DIR/gameinfo.conf | cut -d'=' -f 2 | tr -d '\n' | tr -d '\r')
HOMEPAGE=$(grep 'Homepage' $DATA_DIR/gameinfo.conf | cut -d'=' -f 2 | tr -d '\n' | tr -d '\r')

PACKAGENAME="$COMPANY_LOWER_DASH"-"$TITLE_LOWER_DASH"
EXECUTABLENAME="$TITLE_LOWER_DASH"
DEBIANNAME="$PACKAGENAME"_"$VERSION"_armhf

# Create game launcher script
echo "Creating game launcher script..."
cp "$CURRENT_DIR/"game.sh "$CURRENT_DIR/"game.sh.temp
`sed -i "s|APPDIR=\(.*\)|APPDIR=\\$HOME/.local/share/$PACKAGENAME/|" "$CURRENT_DIR/"game.sh.temp`

# Create temp control file
echo "Creating control file..."
cp "$CURRENT_DIR/"control "$CURRENT_DIR/"control.temp
`sed -i "s/Version: \(.*\)/Version: $(echo "$VERSION" | sed -e 's/\./\\\./g')/"  "$CURRENT_DIR/"control.temp`
`sed -i "s/Description: \(.*\)/Description: $( echo "$DESCRIPTION" | sed -e 's/\./\\\./g')/"  "$CURRENT_DIR/"control.temp`
`sed -i "s/Maintainer: \(.*\)/Maintainer: $MAINTANER/"  "$CURRENT_DIR/"control.temp`
`sed -i "s/Homepage: \(.*\)/Homepage: $HOMEPAGE/"  "$CURRENT_DIR/"control.temp`
`sed -i "s/Package: \(.*\)/Package: $PACKAGENAME/"  "$CURRENT_DIR/"control.temp`

# Create temp desktop file
echo "Creating desktop file..."
cp "$CURRENT_DIR/"app.desktop "$CURRENT_DIR/"app.desktop.temp
`sed -i "s/Comment=\(.*\)/Comment=$( echo "$SHORT_DESCRIPTION" | sed -e 's/\./\\\./g')/" "$CURRENT_DIR/"app.desktop.temp`
`sed -i "s/Name=\(.*\)/Name=$TITLE_UPPER/"  "$CURRENT_DIR/"app.desktop.temp`
`sed -i "s/Exec=\(.*\)/Exec=\/opt\/"$PACKAGENAME"\/game.sh/"  "$CURRENT_DIR/"app.desktop.temp`
`sed -i "s/Path=\(.*\)/Path=\/opt\/"$PACKAGENAME"\//"  "$CURRENT_DIR/"app.desktop.temp`
`sed -i "s/Icon=\(.*\)/Icon=\/opt\/"$PACKAGENAME"\/$(echo "$ID" | sed -e 's/\./\\\./g').png/"  "$CURRENT_DIR/"app.desktop.temp`

# Remove old builds of same version
rm -r "$DEBIANNAME"
rm -r "$DEBIANNAME".deb

#Create 32bit first

# Create fakeroot
echo "Creating fakeroot..."
mkdir -p "$DEBIANNAME"/DEBIAN
mkdir -p "$DEBIANNAME"/opt/"$PACKAGENAME"
mkdir -p "$DEBIANNAME"/usr/share/applications/
mkdir -p "$DEBIANNAME"/usr/share/pixmaps/

# Copy file into them
echo "Populating fakeroot..."
cp "$CURRENT_DIR/"control.temp       "$DEBIANNAME"/DEBIAN/control
cp -r "$GAMEFOLDER"/*   "$DEBIANNAME"/opt/"$PACKAGENAME"/
cp "$CURRENT_DIR/"game.sh.temp              "$DEBIANNAME"/opt/"$PACKAGENAME"/game.sh
cp "$CURRENT_DIR/"mkxp.linux-arm.conf      "$DEBIANNAME"/opt/"$PACKAGENAME"/mkxp.conf

# Update icon location in config file
`sed -i "s/iconPath=\(.*\)/iconPath="$ID".png/"  "$DEBIANNAME"/opt/"$PACKAGENAME"/mkxp.conf`

#Copy script-dialog
mkdir "$DEBIANNAME"/opt/"$PACKAGENAME"/script-dialog
cp "$CURRENT_DIR/"script-dialog/script-dialog.sh "$DEBIANNAME"/opt/"$PACKAGENAME"/script-dialog/

if [ -f $DATA_DIR/license.txt ]; then
    cp -r $DATA_DIR/license.txt "$DEBIANNAME"/opt/"$PACKAGENAME"/LICENSE
fi

if [ -f $DATA_DIR/company.png ]; then
    cp $DATA_DIR/company.png "$DEBIANNAME"/opt/"$PACKAGENAME"/
fi

cp $DATA_DIR/game.png "$DEBIANNAME"/opt/"$PACKAGENAME"/$ID.png
cp "$CURRENT_DIR/"app.desktop.temp "$DEBIANNAME"/usr/share/applications/"$ID".desktop

# arch specific stuff
sed -i "s/Architecture: \(.*\)/Architecture: armhf/"  "$DEBIANNAME"/DEBIAN/control
cp -r mkxp-*/lib        "$DEBIANNAME"/opt/"$PACKAGENAME"/
cp mkxp-*/mkxp.arm      "$DEBIANNAME"/opt/"$PACKAGENAME"/"$EXECUTABLENAME".arm

# Build the package
echo "attempting to build $DEBIANNAME.deb ..."
dpkg-deb --build "$DEBIANNAME" "$DEBIANNAME".deb

# Cleanup
echo "Cleaning up..."
rm "$CURRENT_DIR/"control.temp
rm "$CURRENT_DIR/"app.desktop.temp
rm -r "$DEBIANNAME"

exit 0;

