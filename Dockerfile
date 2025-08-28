FROM php:7.4-cli
# Set the working directory inside the container
WORKDIR /var/www/html
ENV TZ=Europe/Moscow

# Install system dependencies
RUN apt-get update \
    && apt-get install -y \
        libicu-dev \
        libpq-dev \
        libcurl4-openssl-dev \
        libzip-dev \
        unzip \
        git \
        && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Install PHP extensions
RUN docker-php-ext-install \
    intl \
    zip \
    pcntl \
    curl



# Install Composer CLI
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN curl -sS https://get.symfony.com/cli/installer | bash
RUN mv /root/.symfony5/bin/symfony /usr/local/bin/symfony

RUN git config --global user.email "you@example.com"
RUN git config --global user.name "Your Name"
RUN git config --global --add safe.directory /var/www/html

RUN symfony new /var/www/html
RUN chmod -R 777 /var/www/html
RUN composer require symfony/console
RUN composer require guzzlehttp/guzzle
RUN composer require symfony/maker-bundle
RUN php /var/www/html/bin/console make:command ProxyChecker


RUN echo 'alias console="php /var/www/html/bin/console"' >> ~/.bashrc
RUN echo 'alias dsu="/var/www/html/bin/console d:s:u --force --complete"' >> ~/.bashrc
RUN echo "umask 0000" >> /root/.bashrc

ENV COMPOSER_ALLOW_SUPERUSER=1
RUN composer install  --no-scripts

COPY ./src/Command/ProxyCheckerCommand.php /var/www/html/src/Command/ProxyCheckerCommand.php

ENTRYPOINT ["./bin/console"]
CMD ["app:run"]