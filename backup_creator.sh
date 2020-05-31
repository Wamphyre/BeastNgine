#!/bin/bash

echo ; read -p "Please, give me a domain: " WEB;

FECHA=$(date -I)

mkdir /usr/local/www/backup/

mkdir /usr/local/www/backup/$WEB

mkdir /usr/local/www/backup/$WEB/$FECHA

tar -czvf $WEB-$FECHA.tar.gz /usr/local/www/public_html/$WEB

DATABASE=$(cat /usr/local/www/public_html/$WEB/wp-config.php | grep -i "DB_NAME" | cut -d "'" -f4)

PASSWD=$(cat /usr/local/www/public_html/$WEB/wp-config.php | grep -i "DB_PASSWORD" | cut -d "'" -f4)

mysqldump -u root -p$PASSWD $DATABASE > $DATABASE.sql

mv $WEB-$FECHA.tar.gz /usr/local/www/backup/$WEB/$FECHA/

mv $DATABASE.sql /usr/local/www/backup/$WEB/$FECHA/

echo "Backup completed on /usr/local/www/backup"
