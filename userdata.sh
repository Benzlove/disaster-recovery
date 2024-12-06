#!/bin/bash

yum update -y
yum install -y httpd php php-mysqlnd openssl mod_ssl
systemctl enable --now httpd
groupadd www
usermod -a -G www ec2-user
chown -R root:www /var/www
chmod 2775 /var/www
find /var/www -type d -exec sudo chmod 2775 {} +
find /var/www -type f -exec sudo chmod 0664 {} +
mkdir /var/www/inc


