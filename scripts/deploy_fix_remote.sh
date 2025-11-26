#!/bin/bash
sudo cp /tmp/CookiebotLoader.tsx /var/www/estenomada/components/
sudo cp /tmp/layout.tsx /var/www/estenomada/app/\[locale\]/layout.tsx
sudo chown -R www-data:www-data /var/www/estenomada/components /var/www/estenomada/app
echo Файлы скопированы


