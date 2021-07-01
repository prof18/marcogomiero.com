# How to install Wordpress on Arch Linux


{{< figure src="/img/arch/wordpress_arch.png" alt="image" >}}

Every time I've tried to install Wordpress on Arch Linux it was a tragedy. Sometimes a configuration was missing, sometimes stuff not well known was broken and I never found an updated and complete guide. So here you are!

*In all the following commands I've omitted "sudo". Please use it when it is necessary.*

Before starting make you sure that all the packages are updated.

```bash
pacman -Syu
```

## Install Apache

First of all, you need to install and configure Apache, the web server.

```bash
pacman -S apache
```

After the installation you have to start Apache and if you want you can set the auto-start at boot time with the enable command.

```bash
systemctl start httpd

systemctl enable httpd
```

At this point you have to change some configurations of Apache. In order to do that, you can use your preferred editor like nano or vim. I'll use nano. (If you aren't a nano user here's some tip: to search a string you have to press ctrl+w; to exit you have to press ctrl+x and type 'y' or 'n' in order to save or not the file. Remember that the saving process can give an error if the file isn't opened as root and only the root user can edit it).

So open the httpd.conf file

```bash
nano /etc/httpd/conf/httpd.conf
```
and uncomment (remove the #) the following string.

```bash
#LoadModule unique_id_module modules/mod_unique_id.so
```

At this point you have to restart Apache to apply the changes.
```bash
systemctl restart httpd
```

To make sure that all is correctly set and Apache is working you have to simply write an html file and put it into the */srv/http* folder. So you can use again nano

```bash
nano /srv/http/index.html
```

to write this simple html file.

```html
<html>
    <title>Hello World</title>
    <body>
        <h1>This is a test. Apache Web Server is working</h1>
    </body>
</html>
```

Now open your broswer and go to http://localhost. If everything is up and running you should see a page like this:

{{< figure src="/img/arch/apache.jpeg" alt="image" >}}

## Install PHP

Now it is the time to install PHP with the following command.

```bash
pacman -S php php-cgi php-gd php-pgsql php-apache
```

As you can image, you need to configure some stuff. Open again with your preferred editor the httpd.conf file:

```bash
nano /etc/httpd/conf/httpd.conf
```

comment (add a '#') this line

```bash
LoadModule mpm_event_module modules/mod_mpm_event.so
```

and uncomment (remove the '#') this one.

```bash
#LoadModule mpm_prefork_module modules/mod_mpm_prefork.so
```

Finally you have to add these lines at the bottom of the file.

```bash
LoadModule php7_module modules/libphp7.so
AddHandler php7-script php
Include conf/extra/php7_module.conf
```

Now it's the time to configure the php.ini. Open the file

```bash
nano /etc/php/php.ini
```

and uncomment (remove the ';') the following lines.

```bash
;extension=mysqli.so
;extension=gd
```

Now PHP (should be) is correctly set. To check if all is working, you can write a simple info page inside *srv/http/*. Open the editor,

```bash
nano /srv/http/info.php
```

write the following line

```php
<?php phpinfo(); ?>
```

and restart the httpd service.

```bash
systemctl restart httpd
```

Now, if you open your broswer and you go to http://localhost/info.php, you should see a page like this:

{{< figure src="/img/arch/php.jpeg" alt="image" >}}

## Install Maria DB

Now you have to install and create the database. You are going to install Maria DB, the implementation of MySQL for Arch Linux.

```bash
pacman -S mariadb libmariadbclient mariadb-clients
```

After the installation you have to set some base configuration with this command.

```bash
mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
```

As you guess, you need to start and enable the service.

```bash
systemctl start mysqld
systemctl enable mysqld
```

Before creating the database, you have to set the root password and some other configurations. You can do it with this command

```bash
mysql_secure_installation
```

Finally now you can create your own database. Connect to the MySQL console with this command.

```bash
mysql -u root -p
```

After you type the password, you can start to create the database. Of course you can change the name of the database and the user.

```sql
CREATE DATABASE wordpress;
CREATE USER 'wpuser'@'localhost' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'localhost';
FLUSH PRIVILEGES;
```

FINALLY it's time to install Wordpress inside the */srv/http* folder.

```bash
cd /srv/http
wget https://wordpress.org/latest.tar.gz
tar xvzf latest.tar.gz
cd wordpress
```

Now you have to change the ownership of the folder wordpress to the http group.

```bash
chown -R root:http /srv/http/wordpress
```

The last step is to create the Wordpress config file starting from the default one.

```bash
cp wp-config-sample.php wp-config.php
```

All you have to do is opening the file

```bash
nano wp-config.php
```

and set the name of the database, the user and the password.

```php
/** The name of the database for WordPress */
define('DB_NAME', 'wordpress');
/** MySQL database username */
define('DB_USER', 'wpuser');
/** MySQL database password */
define('DB_PASSWORD', 'password');
```

Now everything is done. To check if it is true, open the broswer and go to http://localhost/wordpress and you should see a page like this.

{{< figure src="/img/arch/wordpress.jpeg" alt="image" >}}

Now you can go through the classic setup of Wordpress. Enjoy it!