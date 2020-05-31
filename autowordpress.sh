#!/bin/sh
echo "Autowordpress by Wamphyre"
echo "Version 1.0"

test $? -eq 0 || exit 1 "Need root to execute"

echo "Downloading Wordpress...";
fetch http://wordpress.org/latest.zip;
unzip -q latest.zip;

echo "Cleaning temp files...";
rm *.zip

mv wordpress/* .;
rm -rf wordpress;

echo "Repairing permissions..."

RUTA=$(pwd)

chown -R www:www $RUTA
chown -R www:www $RUTA*
find . -type f -exec chmod 664 {} +
find . -type d -exec chmod 775 {} +

echo "Completed!";
