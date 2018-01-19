---
layout: post
title:  "How to install Wordpress on Arch Linux"
date:   2018-01-19
---
<p class="intro"><span class="dropcap" align="justify">E</span></p><p align="justify">very time I've tried to install Wordpress on Arch Linux it was a tragedy. Sometimes a configuration was missing, sometimes stuff not well known was broken and I never found an updated and complete guide. So here you are!
<br>
<br>
<i>In all the following commands I've omitted "sudo". Please use it when it is necessary.</i>
<br>
<br>
Before starting make you sure that all the packages are updated.
{% highlight shell %}
pacman -Syu
{% endhighlight %}
</p>

<h2>Install Apache</h2>

<p align="justify">First of all you need to install and configure Apache, the web server.</p>
{% highlight shell %}
pacman -S apache
{% endhighlight %}
<p align="justify">After the installation you have to start Apache and if you want you can set the auto-start at boot time with the enable command.</p>
{% highlight shell %}
systemctl start httpd

systemctl enable httpd
{% endhighlight %}
<p align="justify">At this point you have to change some configurations of Apache. In order to do that, you can use your preferred editor like nano or vim. I'll use nano. (If you aren't a nano user here's some tip: to search a string you have to press ctrl+w; to exit you have to press ctrl+x and type 'y' or 'n' in order to save or not the file. Remember that the saving process can give an error if the file isn't opened as root and only the root user can edit it). 
<br>
<br>
So open the httpd.conf file</p>
{% highlight shell %}
nano /etc/httpd/conf/httpd.conf
{% endhighlight %}
<p align="justify">and uncomment (remove the #) the following string.</p>
{% highlight shell %}
#LoadModule unique_id_module modules/mod_unique_id.so
{% endhighlight %}

<p align="justify">At this point you have to restart Apache to apply the changes.</p>
{% highlight shell %}
systemctl restart httpd
{% endhighlight %}

<p align="justify">To make sure that all is correctly set and Apache is working you have to simply write an html file and put it into the <i>/srv/http</i> folder. So you can use again nano</p>

{% highlight shell %}
nano /srv/http/index.html
{% endhighlight %}

<p align="justify">to write this simple html file.</p>

{% highlight html %}
<html>
 
<title>Hello World</title>
 
<body>
<h1>This is a test. Apache Web Server is working</h1>
</body>
 
</html>
{% endhighlight %}

<p align="justify">Now open your broswer and go to http://localhost. If everything is up and running you should see a page like this:</p>

<img src="/assets/img/articles/01-18/apache_working.jpg" align="center">

<h2>Install PHP</h2>

<p align="justify">Now it is time to install PHP with the following command.</p>

{% highlight shell %}
pacman -S php php-cgi php-gd php-pgsql php-apache
{% endhighlight %}

<p align="justify">As you can image, you need to configure some stuff. Open again with your preferred editor the httpd.conf file:</p>

{% highlight shell %}
nano /etc/httpd/conf/httpd.conf
{% endhighlight %}

<p align="justify">comment (add a ';') this line</p>

{% highlight shell %}
LoadModule mpm_event_module modules/mod_mpm_event.so
{% endhighlight %}

<p align="justify">and uncomment (remove the ';') this one.</p>

{% highlight shell %}
;LoadModule mpm_prefork_module modules/mod_mpm_prefork.so
{% endhighlight %}

<p align="justify">Finally you have to add these lines at the bottom of the file.</p>

{% highlight shell %}
LoadModule php7_module modules/libphp7.so
AddHandler php7-script php
Include conf/extra/php7_module.conf
{% endhighlight %}

<p align="justify">Now it's time to configure the php.ini. Open the file</p>

{% highlight shell %}
nano /etc/php/php.ini
{% endhighlight %}

<p align="justify">and uncomment (remove the ';') the following lines.</p>

{% highlight shell %}
;extension=mysqli.so
;extension=gd
{% endhighlight %}

<p align="justify">Now PHP (should be) is correctly set. To check if all is working, you can write a simple info page inside <i>srv/http/</i>. Open the editor,</p>

{% highlight shell %}
nano /srv/http/info.php
{% endhighlight %}

<p align="justify">write the following line</p>

{% highlight php %}
<?php phpinfo(); ?>
{% endhighlight %}

<p align="justify">and restart the httpd service.</p>

{% highlight shell %}
systemctl restart httpd
{% endhighlight %}

<p align="justify">Now, if you open your broswer and you go to http://localhost/info.php, you should see a page like this:</p>

<img src="/assets/img/articles/01-18/php_working.jpg" align="center">

<h2>Install Maria DB</h2>

<p align="justify">Now you have to install and create the database. You are going to install Maria DB, the implementation of MySQL for Arch Linux.</p>

{% highlight shell %}
pacman -S mariadb libmariadbclient mariadb-clients
{% endhighlight %}

<p align="justify">After the installation you have to set some base configuration with this command.</p>

{% highlight shell %}
mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
{% endhighlight %}

<p align="justify">As you guess, you need to start and enable the service.</p>

{% highlight shell %}
systemctl start mysqld
systemctl enable mysqld
{% endhighlight %}

<p align="justify">Before creating the database, you have to set the root password and some other configurations. You can do it with this command</p>

{% highlight shell %}
mysql_secure_installation
{% endhighlight %}

<p align="justify">Finally now you can create your database. Connect to the MySQL console with this command.</p>

{% highlight shell %}
mysql -u root -p
{% endhighlight %}

<p align="justify">After you type the password, you can start to create the database. Of course you can change the name of the database and the user.</p>

{% highlight sql %}
CREATE DATABASE wordpress;
CREATE USER wpuser '@'localhost' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'localhost';
FLUSH PRIVILEGES;
{% endhighlight %}

<p align="justify">FINALLY it's time to install Wordpress inside the <i>/srv/http</i> folder.</p>

{% highlight shell %}
cd /srv/http
wget https://wordpress.org/latest.tar.gz
tar xvzf latest.tar.gz
cd wordpress
{% endhighlight %}

<p align="justify">Now you have to change the ownership of the folder wordpress to the http group.</p>

{% highlight shell %}
chown -R root:http /srv/http/wordpress
{% endhighlight %}

<p align="justify">The last step is to create the Wordpress config file starting from the default one.</p>

{% highlight shell %}
cp wp-config-sample.php wp-config.php
{% endhighlight %}

<p align="justify">All you have to do is opening the file</p>

{% highlight shell %}
nano wp-config.php
{% endhighlight %}

<p align="justify">and set the name of the database, the user and the password.</p>

{% highlight php %}
/** The name of the database for WordPress */
define('DB_NAME', 'wordpress');
/** MySQL database username */
define('DB_USER', 'wpuser');
/** MySQL database password */
define('DB_PASSWORD', 'password');
{% endhighlight %}

<p align="justify">Now everything is done. To check if is true, open the broswer and go to http://localhost/wordpress and you should see a page like this.</p>

<img src="/assets/img/articles/01-18/wordpress_working.jpg" align="center">

<p align="justify">Now you can go through the classic setup of Wordpress. Enjoy it!</p>