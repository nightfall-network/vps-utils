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
    cd ../../../../../../../../../../
    cd root
    echo -e "${lightpurple}[*] ${white}Instalando dependencias...\n"
    apt -y install php8.1 php8.1-{common,cli,gd,mysql,mbstring,bcmath,xml,fpm,curl,zip} libapache2-mod-php python3-certbot-apache
    echo -e "${lightpurple}[*] ${white}Dependencias instaladas con exit\n"

    echo -ne "${lightpurple}[*] ${white}Dominio del servidor:${lightpurple}"; read -p " " domain
    
    echo -ne "${lightpurple}[*] ${white}Creando certificado ssl...\n"
    certbot certonly --apache -d $domain
    certbot -d $domain --manual --preferred-challenges dns certonly
    echo -ne "${lightpurple}[*] ${white}Certificado ssl creador con exito!\n"
    
    cd /etc/apache2/sites-available

    echo "<VirtualHost *:80>
  ServerName $domain
  ErrorLog /var/www/delight/db/error.log
  
  RewriteEngine On
  RewriteCond %{HTTPS} !=on
  RewriteCond %{REQUEST_FILENAME} !-f
  RewriteCond %{REQUEST_FILENAME} !-d
  RewriteRule ^/?(.*) https://%{SERVER_NAME}/index.php?request=$1 [QSA,NC,L]
</VirtualHost>

<VirtualHost *:443>
  ServerName $domain
  DocumentRoot "/var/www/$webserver_folder"

  AllowEncodedSlashes On
  
  php_value upload_max_filesize 100M
  php_value post_max_size 100M

  <Directory "/var/www/$webserver_folder">
    Options FollowSymLinks Indexes
	AllowOverride None 
	Order deny,allow 
	deny from all 
  </Directory>

  SSLEngine on
  SSLCertificateFile /etc/letsencrypt/live/$domain/fullchain.pem
  SSLCertificateKeyFile /etc/letsencrypt/live/$domain/privkey.pem
</VirtualHost> " > $webserver_file
    
    sudo ln -s /etc/apache2/sites-available/$webserver_file /etc/apache2/sites-enabled/$webserver_file
    sudo a2enmod rewrite
    sudo a2enmod ssl
    sudo systemctl restart apache2
    
    echo -e "${lightpurple}[*] ${white}Delight webserver creado con exito!"
    choosen_options;
}

function pterodactyl_webserver(){
    cd ../../../../../../../../../../
    cd /etc/apache2/sites-available
    echo -ne "${lightpurple}[*] ${white}Dominio:${lightpurple}"; read -p " " domain
    echo "<VirtualHost *:80>
  ServerName $domain
  
  RewriteEngine On
  RewriteCond %{HTTPS} !=on
  RewriteRule ^/?(.*) https://%{SERVER_NAME}/$1 [R,L] 
</VirtualHost>

<VirtualHost *:443>
  ServerName $domain
  DocumentRoot "/var/www/pterodactyl/public"

  AllowEncodedSlashes On
  
  php_value upload_max_filesize 100M
  php_value post_max_size 100M

  <Directory "/var/www/pterodactyl/public">
    Require all granted
    AllowOverride all
  </Directory>

  SSLEngine on
  SSLCertificateFile /etc/letsencrypt/live/$domain/fullchain.pem
  SSLCertificateKeyFile /etc/letsencrypt/live/$domain/privkey.pem
</VirtualHost>" > pterodactyl.conf

    sudo ln -s /etc/apache2/sites-available/pterodactyl.conf /etc/apache2/sites-enabled/pterodactyl.conf
    sudo a2enmod rewrite
    sudo a2enmod ssl
    sudo systemctl restart apache2
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
