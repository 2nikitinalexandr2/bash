 #!/bin/bash

      sudo apt-get update
      sudo apt-get install -y nginx php-fpm php-mysql wget curl tar
      sudo service nginx start
      sudo rm -f /etc/nginx/sites-enabled/default
      sudo ln -s /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/
      wget https://wordpress.org/latest.tar.gz -O /tmp/latest.tar.gz
      sudo tar -xzf /tmp/latest.tar.gz -C /tmp
      sudo mv /tmp/wordpress /var/www/wordpress
      sudo chown -R www-data:www-data /var/www/wordpress
      sudo wget -qO wpsucli https://git.io/vykgu && sudo chmod +x ./wpsucli && sudo install ./wpsucli /usr/local/bin/wpsucli
      sudo bash -c 'cat << EOF >> /etc/nginx/sites-available/wordpress
          server {
          listen 80 default_server;
          root /var/www/wordpress;
          index index.php;
          server_name _;  # Замените на ваше DNS

          location / {
              try_files \$uri \$uri/ =404;
          }

          error_page 404 /404.html;
          error_page 500 502 503 504 /50x.html;

          location = /50x.html {
              root /usr/share/nginx/html;
          }

          location ~ .php$ {
              try_files \$uri =404;
              fastcgi_split_path_info ^(.+.php)(/.+)\$;
              fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
              fastcgi_index index.php;
              fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
              include fastcgi_params;
          }
      }'

sudo cp /var/www/wordpress/wp-config-sample.php /var/www/wordpress/wp-config.php


    # Получение секретных ключей WordPress

      KEYS=$(curl --silent https://api.wordpress.org/secret-key/1.1/salt/)
sudo bash -c 'cat > /var/www/wordpress/wp-config.php <<EOF
<?php
// * MySQL settings * //
define('DB_NAME', '<DB_NAME>');
define('DB_USER', '<DB_USER>');
define('DB_PASSWORD', '<DB_PASSWORD>');
define('DB_HOST', '<DB_HOST>');

// * Authentication Unique Keys and Salts * //
$KEYS

// * Other settings * //
$table_prefix  = 'wp_';
define('WP_DEBUG', false);

if ( !defined('ABSPATH') )
    define('ABSPATH', dirname(__FILE__) . '/');

require_once(ABSPATH . 'wp-settings.php');'


   sudo sed -i "s/database_name_here/wp-mysql-tutorial-db/g" /var/www/wordpress/wp-config.php
   sudo sed -i "s/username_here/wordpress/g" /var/www/wordpress/wp-config.php
   sudo sed -i "s/password_here/password/g" /var/www/wordpress/wp-config.php
   sudo sed -i "s/localhost/$MYSQL_HOST_FQDN/" /var/www/wordpress/wp-config.php
     sudo systemctl restart php8.1-fpm
 sudo systemctl restart nginx
