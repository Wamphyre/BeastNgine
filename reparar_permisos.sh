#!/bin/bash

chown -R www:www /usr/local/www/public_html/
chown -R www:www /usr/local/www/public_html/*

cd /usr/local/www/public_html/

find . -type f -exec chmod 664 {} +
find . -type d -exec chmod 775 {} +
