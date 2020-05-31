#!/bin/sh
echo "Autowordpress by Wamphyre"
echo "Version 1.0"

test $? -eq 0 || exit 1 "Necesitas ser root para ejecutar este script"

echo "Descargando Wordpress...";
fetch http://wordpress.org/latest.zip;
unzip -q latest.zip;

echo "Descargando e instalando Cloudflare SSL Fix"
fetch https://downloads.wordpress.org/plugin/cloudflare-flexible-ssl.1.3.0.zip
unzip -q  cloudflare-flexible-ssl.1.3.0.zip;
mv cloudflare-flexible-ssl wordpress/wp-content/plugins/

echo "Limpiando directorio y archivos temporales...";
rm *.zip

mv wordpress/* .;
rm -rf wordpress;

echo "Reparando y estableciendo permisos..."

RUTA=$(pwd)

chown -R www:www $RUTA
chown -R www:www $RUTA*
find . -type f -exec chmod 664 {} +
find . -type d -exec chmod 775 {} +

echo "Finalizado!";
