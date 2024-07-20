#!/bin/bash

# Colors
orange="\033[0;33m"
green="\e[0;32m\033[1m"
gray='\033[0;37m'
black='\033[0;30m'
clear='\033[0m'
lightred="\033[1;31m"
red="\033[0;31m"
lightpurple="\033[1;35m"
purple="\033[0;35m"
cyan="\033[0;36m"
lightcyan="\033[1;36m"
white="\e[0;37m\033[1m"
blued="\033[1;34m"
blue="\e[0;34m\033[1m"
yellow="\e[0;33m\033[1m"

version=1.2

github="https://github.com/nightfall-network/vps-utils.git"
github_folder="vps-utils"
webserver_file="delight.conf"
webserver_folder="delight"
webserver_github="https://github.com/nightfall-network/delight-webserver.git"

function ctrl_c(){
    echo -e "${red}[!] ${white}Cerrando script...";echo -e "${white}"; tput cnorm; exit 0
}



pterodactyl_custom_theme(){
    echo -e "${lightpurple}[*] ${white}Instalando tema personalizado..."
    cd /var/www/
    tar -cvf Pterodactyl_Backup.tar.gz pterodactyl
    cd /var/www/pterodactyl
    rm -r $github_folder 2>/dev/null
    git clone $github
    cd $github_folder
    rm /var/www/pterodactyl/resources/scripts/NightFallTheme.css 2>/dev/null
    rm /var/www/pterodactyl/resources/scripts/index.tsx 2>/dev/null
    rm /var/www/pterodactyl/public/favicons/favicon.ico 2>/dev/null
    rm /var/www/pterodactyl/public/favicons/apple-touch-icon.png 2>/dev/null
    rm /var/www/pterodactyl/public/favicons/favicon-16x16.png 2>/dev/null
    rm /var/www/pterodactyl/public/favicons/favicon-32x32.png 2>/dev/null
    rm /var/www/pterodactyl/public/favicons/favicon-96x96.png 2>/dev/null
    mv index.tsx /var/www/pterodactyl/resources/scripts/index.tsx
    mv NightFallTheme.css /var/www/pterodactyl/resources/scripts/NightFallTheme.css
    mv favicon.ico /var/www/pterodactyl/public/favicons/favicon.ico
    mv apple-touch-icon.png /var/www/pterodactyl/public/favicons/apple-touch-icon.png
    mv favicon-16x16.png /var/www/pterodactyl/public/favicons/favicon-16x16.png
    mv favicon-32x32.png /var/www/pterodactyl/public/favicons/favicon-32x32.png
    mv favicon-96x96.png /var/www/pterodactyl/public/favicons/favicon-96x96.png
    cd /var/www/pterodactyl

    curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -
    apt update
    apt install -y nodejs

    npm i -g yarn
    yarn

    cd /var/www/pterodactyl
    yarn build:production
    sudo php artisan optimize:clear

    echo -e "${lightpurple}[*] ${white} Tema personalizado instalado con exito!"
    choosen_options;
}

pterodactyl_dependencies(){
    echo -e "${lightpurple}[*] ${white}Descargando dependencias Y pterodactyl panel..."
    apt -y install software-properties-common curl apt-transport-https ca-certificates gnupg python3-certbot-apache
    LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
    curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list
    curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash
    apt update
    apt -y install php8.1 php8.1-{common,cli,gd,mysql,mbstring,bcmath,xml,fpm,curl,zip} mariadb-server nginx tar unzip git redis-server
    curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
    mkdir -p /var/www/pterodactyl
    cd /var/www/pterodactyl
    curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
    tar -xzvf panel.tar.gz
    chmod -R 755 storage/* bootstrap/cache/
    echo -e "${lightpurple}[*] ${white}Dependecias y pterodactyl panel descargado con exito!"
    choosen_options;
}

wings_dependencies(){
    echo -e "${lightpurple}[*] ${white}Descargando docker..."
    curl -sSL https://get.docker.com/ | CHANNEL=stable bash
    sudo systemctl enable --now docker
    sudo mkdir -p /etc/pterodactyl
    curl -L -o /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_$([[ "$(uname -m)" == "x86_64" ]] && echo "amd64" || echo "arm64")"
    sudo chmod u+x /usr/local/bin/wings
    echo -e "${lightpurple}[*] ${white}Docker instalado con exito!"
    choosen_options;
}

restore_backup(){
    echo -e "${lightpurple}[*] ${white}Cargando backup..."
    cd /var/www/
    tar -xvf Pterodactyl_Backup.tar.gz
    rm Pterodactyl_Backup.tar.gz
    cd /var/www/pterodactyl
    yarn build:production
    sudo php artisan optimize:clear
    echo -e "${lightpurple}[*] ${white}backup cargado con exito!"
    choosen_options;
}

repair_panel(){
    echo -e "${lightpurple}[*] ${white}Reparando panel..."
    cd /var/www/pterodactyl
    php artisan down
    rm -r /var/www/pterodactyl/resources
    curl -L https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz | tar -xzv
    chmod -R 755 storage/* bootstrap/cache
    composer install --no-dev --optimize-autoloader
    php artisan view:clear
    php artisan config:clear
    php artisan migrate --seed --force
    chown -R www-data:www-data /var/www/pterodactyl/*
    php artisan queue:restart
    php artisan up
    echo -e "${lightpurple}[*] ${white}Panel reparado con exito!"
    choosen_options;
}

function delight_webserver(){
    echo -e "${lightpurple}[*] ${white}Instalando dependencias...\n"
    sudo apt install -y python3-certbot-nginx
    echo -e "${lightpurple}[*] ${white}Dependencias instaladas con exit\n"
    cd /var/www/
    git clone $webserver_github
    mv delight-webserver $webserver_folder

    echo -ne "${lightpurple}[*] ${white}Dominio del servidor:${lightpurple}"; read -p " " domain
    
    echo -ne "${lightpurple}[*] ${white}Creando certificado ssl...\n"
    certbot certonly --nginx -d $domain
    certbot -d $domain --manual --preferred-challenges dns certonly
    echo -ne "${lightpurple}[*] ${white}Certificado ssl creador con exito!\n"
    
    cd /etc/nginx/sites-available/
    
    echo "
    server_tokens off;

server {
    listen 80;
    server_name $domain;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $domain;

    root /var/www/$webserver_folder;
    index index.php;

    access_log /var/log/nginx/$webserver_folder.app-access.log;
    error_log  /var/log/nginx/$webserver_folder.app-error.log error;

    # allow larger file uploads and longer script runtimes
    client_max_body_size 100m;
    client_body_timeout 120s;

    sendfile off;

    # SSL Configuration - Replace the example $domain with your domain
    ssl_certificate /etc/letsencrypt/live/$domain/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$domain/privkey.pem;
    ssl_session_cache shared:SSL:10m;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384";
    ssl_prefer_server_ciphers on;

    # See https://hstspreload.org/ before uncommenting the line below.
    # add_header Strict-Transport-Security "max-age=15768000; preload;";
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Robots-Tag none;
    add_header Content-Security-Policy "frame-ancestors 'self'";
    add_header X-Frame-Options DENY;
    add_header Referrer-Policy same-origin;

    location / {
        try_files $uri $uri/ /index.php;
    }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
        include /etc/nginx/fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
" > $webserver_file

    sudo ln -s /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf

    sudo systemctl restart nginx

    echo -e "${lightpurple}[*] ${white}Delight webserver creado con exito!"
    choosen_options;
}

function pterodactyl_webserver(){
    cd /etc/nginx/sites-available/
    echo -ne "${lightpurple}[*] ${white}Dominio:${lightpurple}"; read -p " " domain
    echo "
    server_tokens off;

server {
    listen 80;
    server_name $domain;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $domain;

    root /var/www/pterodactyl/public;
    index index.php;

    access_log /var/log/nginx/pterodactyl.app-access.log;
    error_log  /var/log/nginx/pterodactyl.app-error.log error;

    # allow larger file uploads and longer script runtimes
    client_max_body_size 100m;
    client_body_timeout 120s;

    sendfile off;

    # SSL Configuration - Replace the example $domain with your domain
    ssl_certificate /etc/letsencrypt/live/$domain/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$domain/privkey.pem;
    ssl_session_cache shared:SSL:10m;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384";
    ssl_prefer_server_ciphers on;

    # See https://hstspreload.org/ before uncommenting the line below.
    # add_header Strict-Transport-Security "max-age=15768000; preload;";
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Robots-Tag none;
    add_header Content-Security-Policy "frame-ancestors 'self'";
    add_header X-Frame-Options DENY;
    add_header Referrer-Policy same-origin;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
        include /etc/nginx/fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
" > pterodactyl.conf

    sudo ln -s /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf

    sudo systemctl restart nginx
    echo -e "${lightpurple}[*] ${white}Delight webserver creado con exit!"
    choosen_options;
}

function create_ssl_certificate(){
    echo -ne "${lightpurple}[*] ${white}Dominio:${lightpurple}"; read -p " " domain
    
    echo -ne "${lightpurple}[*] ${white}Creando certificado ssl...\n"
    certbot certonly --apache -d $domain
    certbot -d $domain --manual --preferred-challenges dns certonly
    echo -ne "${lightpurple}[*] ${white}Certificado ssl creador con exito!"
    choosen_options;
}

if (( $EUID != 0 )); then
    echo -e "${lightpurple}[*] ${white}Este script ocupa permisos de usuario root"
    ctrl_c;
fi

function invalid_option(){
    echo -e "${red}[!] ${white}Esta opción no existe.";
    choosen_options;
}

function choosen_options(){
    echo -e "\n"
    echo -e "${lightpurple}a) ${white}Instalar Tema Personalizado de Pterodactyl"
    echo -e "${lightpurple}b) ${white}Instalar Panel ${gray}(Panel & Dependencias)"
    echo -e "${lightpurple}c) ${white}Instalar Wings ${gray}(Dependencias)"
    echo -e "${lightpurple}d) ${white}Instalar Pterodactyl Webserver${gray}(setup)"
    echo -e "${lightpurple}e) ${white}Crear Certificado ssl"
    echo -e "${lightpurple}f) ${white}Cargar Backup"
    echo -e "${lightpurple}g) ${white}Reparar Panel"
    echo -e "${lightpurple}h) ${white}Pagina Web${gray}(Apache Dependencias && Setup)"
    echo -e "${lightpurple}i) ${white}Salir"
  	echo -e ""
    echo -ne "${lightpurple}[*] ${white}Selecciona una opción:${lightpurple}"; read -p " " opt
    case $opt in
        [Aa1]* )pterodactyl_custom_theme;;
        [Bb2]* )pterodactyl_dependencies;;
        [Cc3]* )wings_dependencies;;
        [Dd4]* )pterodactyl_webserver;;
        [Ee5]* )create_ssl_certificate;;
        [Ff6]* )restore_backup;;
        [Gg7]* )repair_panel;;
        [Hh8]* )delight_webserver;;
        [Ii9]* )ctrl_c;;
        * )invalid_option;;
    esac
}

function main(){
    echo -e "${purple}"
    echo -e "╭━━━╮  ╭╮    ╭╮ ╭╮"
    echo -e "╰╮╭╮┃  ┃┃    ┃┃╭╯╰╮"
    echo -e " ┃┃┃┣━━┫┃╭┳━━┫╰┻╮╭╯\t${lightpurple}VPS utils - ${green}v${version}${purple}"
    echo -e " ┃┃┃┃┃━┫┃┣┫╭╮┃╭╮┃┃"
    echo -e "╭╯╰╯┃┃━┫╰┫┃╰╯┃┃┃┃╰╮"
    echo -e "╰━━━┻━━┻━┻┻━╮┣╯╰┻━╯"
    echo -e "          ╭━╯┃"
    echo -e "          ╰━━╯"
    choosen_options;
}

clear; tput cnorm

main;
