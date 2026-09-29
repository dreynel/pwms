# ========================================================
# PWMS - Plant Water Management System Backend API
# Render.com Docker Deployment (PHP 8.2 + Apache + PostgreSQL)
# ========================================================

FROM php:8.2-apache

# Install PostgreSQL (libpq-dev, pdo_pgsql, pgsql) and MySQL drivers
RUN apt-get update && apt-get install -y \
    libpq-dev \
    && docker-php-ext-install pdo pdo_pgsql pgsql pdo_mysql \
    && a2enmod rewrite headers \
    && rm -rf /var/lib/apt/lists/*

# Configure Apache to listen on Render's dynamic $PORT (Defaults to 10000)
RUN sed -i 's/Listen 80/Listen ${PORT}/g' /etc/apache2/ports.conf \
    && sed -i 's/:80/:${PORT}/g' /etc/apache2/sites-available/000-default.conf

# Set working directory
WORKDIR /var/www/html

# Copy all PHP API files into Apache root
COPY PHP/ /var/www/html/

# Set correct permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Default port for Render Web Services
ENV PORT=10000

EXPOSE 10000

CMD ["apache2-foreground"]
