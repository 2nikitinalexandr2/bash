   #!/bin/bash
      # Обновление системы
      sudo apt-get update

      # Установка необходимых пакетов
      sudo apt-get install -y nginx php-fpm php-mysql wget curl tar

      # Запуск nginx
      sudo systemctl start nginx

      # Настройка сайта nginx
      sudo cat > /etc/nginx/sites-available/wordpress <<EOF
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
              fastcgi_split_path_info ^(.+.php)(/.+)$;
              fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
              fastcgi_index index.php;
              fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
              include fastcgi_params;
          }
      }
EOF

      # Включение сайта
      sudo rm -f /etc/nginx/sites-enabled/default
      sudo ln -s /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/

      # Установка WordPress
      sudo wget https://wordpress.org/latest.tar.gz -O /tmp/latest.tar.gz
      sudo tar -xzf /tmp/latest.tar.gz -C /tmp
      sudo mv /tmp/wordpress /var/www/wordpress

      # Установка прав
      sudo chown -R www-data:www-data /var/www/wordpress

      # Получение секретных ключей WordPress
      sudo KEYS=$(curl --silent https://api.wordpress.org/secret-key/1.1/salt/)

      # Настройка wp-config.php
      sudo cat > /var/www/wordpress/wp-config.php <<EOF
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

require_once(ABSPATH . 'wp-settings.php');
EOF

      # Замените placeholders в wp-config.php на реальные значения
      sudo sed -i "s/<DB_NAME>/your_db_name/" /var/www/wordpress/wp-config.php
      sudo sed -i "s/<DB_USER>/your_db_user/" /var/www/wordpress/wp-config.php
      sudo sed -i "s/<DB_PASSWORD>/your_db_password/" /var/www/wordpress/wp-config.php
      sudo sed -i "s/<DB_HOST>/your_db_host/" /var/www/wordpress/wp-config.php

      # Вставка ключей
      sudo sed -i "/$KEYS/{
        r /dev/stdin
        d
      }" /var/www/wordpress/wp-config.php
      sudo echo "$KEYS" >> /var/www/wordpress/wp-config.php

      # Перезапуск служб
      sudo systemctl restart php8.1-fpm
      sudo systemctl restart nginx
