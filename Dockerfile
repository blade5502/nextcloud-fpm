FROM php:5.6-fpm

RUN apt-get update && apt-get install -y \
	bzip2 \
	libcurl4-openssl-dev \
	libfreetype6-dev \
	libicu-dev \
	libjpeg-dev \
	libmcrypt-dev \
	libmemcached-dev \
	libpng12-dev \
	libpq-dev \
	libxml2-dev \
	&& rm -rf /var/lib/apt/lists/*

# https://doc.owncloud.org/server/8.1/admin_manual/installation/source_installation.html#prerequisites
RUN docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
	&& docker-php-ext-install gd exif intl mbstring mcrypt mysql opcache pdo_mysql pdo_pgsql pgsql zip

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=60'; \
		echo 'opcache.fast_shutdown=1'; \
		echo 'opcache.enable_cli=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini

# PECL extensions
RUN pecl install APCu-4.0.10 redis memcached \
	&& docker-php-ext-enable apcu redis memcached

ENV NEXTCLOUD_VERSION 9.0.50
VOLUME /var/www/html

RUN curl -fsSL -o nextcloud.tar.gz \
		"https://github.com/nextcloud/server/archive/v${NEXTCLOUD_VERSION}.tar.gz" \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& tar -xvf nextcloud.tar.gz -C /usr/src/ \
	&& rm nextcloud.tar.gz

COPY docker-entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["php-fpm"]
