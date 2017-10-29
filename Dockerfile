FROM debian
LABEL motd="Server personal music"
VOLUME ["/media"]
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get dist-upgrade -y && apt-get install -y wget inotify-tools
RUN sh -c 'echo "deb http://www.deb-multimedia.org stretch main non-free" >> /etc/apt/sources.list'
RUN wget http://www.deb-multimedia.org/pool/main/d/deb-multimedia-keyring/deb-multimedia-keyring_2016.8.1_all.deb
RUN dpkg -i deb-multimedia-keyring_2016.8.1_all.deb
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y \	
	php \
	ntp \
	apache2 \
	deb-multimedia-keyring \
	build-essential checkinstall cvs subversion git git-core mercurial pkg-config apt-file \
	lame vorbis-tools flac ffmpeg libavcodec-extra*  \
	eyed3 \
	faad \
	php-gd \
	vorbis-tools \
	pwgen \
	lame \
	libvorbis-dev \
	vorbis-tools \
	flac \
	libmp3lame-dev \
	libavcodec-extra* \
	deluged deluge-web \
	libav-tools 
RUN rm -rf /var/lib/apt/lists/*

# Install composer for dependency management
RUN php -r "readfile('https://getcomposer.org/installer');" | php && \
	mv composer.phar /usr/local/bin/composer

# extraction / installation
WORKDIR /var/www
RUN rm -rf * && git clone https://github.com/ampache/ampache && mv ampache/* .
RUN composer install --prefer-source --no-interaction && \
RUN chown -R www-data ..

ADD ampache.cfg.php.dist /var/temp/ampache.cfg.php.dist
ADD run.sh /run.sh
RUN chmod 755 /*.sh

# setup apache with default ampache vhost
ADD 001-ampache.conf /etc/apache2/sites-available/
RUN rm -rf /etc/apache2/sites-enabled/*
RUN ln -s /etc/apache2/sites-available/001-ampache.conf /etc/apache2/sites-enabled/
RUN a2enmod rewrite


# Add job to cron to clean the library every night
RUN echo '30 7    * * *   www-data php /var/www/bin/catalog_update.inc' >> /etc/crontab

VOLUME ["/var/www/config"]
VOLUME ["/var/www/themes"]	
EXPOSE 80

CMD ["/run.sh"]
