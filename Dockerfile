# Création de l'image docker personnalisée intégrant la CLI-WP

FROM wordpress:6.7.2-php8.3

# Installation des dépendances (wp-cli indisponible dans la liste des paquets debian)
RUN apt-get update && apt-get install -y curl less \
    && curl -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x /usr/local/bin/wp \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Définit l'utilisateur par défaut dans le conteneur (www-data étant celui qu'utilise Apache pour exécuter wordpress)
USER www-data

# Répertoire par défaut où les commandes seront exécutées
WORKDIR /var/www/html