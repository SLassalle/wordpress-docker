# Rapport de Déploiement

## 1 Préparation de l'environnement

- Installation de **Docker** et **Docker Compose** sur la machine.
- Création d'un répertoire de projet pour contenir les fichiers nécessaires.
- Création du fichier `docker-compose.yml` pour définir les services nécessaires :
  - **MySQL** comme base de données.
  - **WordPress** comme application principale.
  - **phpMyAdmin** pour l'administration de la base de données.
- Création d'un fichier `Dockerfile` pour personnaliser l'image docker wordpress en y intégrant la CLi directement.
- Création d'un fichier `.env` pour stocker les variables sensibles.

## 2 Rédaction des différents services dans le docker-compose.yml

### 2.1 Service pour la base de données MYSQL

- **Choix de l'image officielle sur le dockerhub** : Ne pas prendre la version latest mais plutôt une version stable et  
maintenue : `MYSQL:8.4.4`. 

- **Environnement** : Déclaration des variables d'environnements afin de sécuriser les secrets.

*Première difficulté rencontrée, la gestion des secrets. J'ai fait le choix de créer un fichier .env à la racine et d'y   
renseigner toutes mes variables mais par soucis de simplicité pour l'exercice. Une façon plus sécurisée est d'avoir un  
gestionnaire de secrets externe ou à minima d'utiliser Docker Secrets (via Swarm si on utilise cet orchestrateur ou  
même via Compose depuis la version 3.7 mais moins sécurisée car pas de chiffrement)*

- **volumes** : Montage du volume `db_data` sur le répertoire `/var/www/html` du conteneur.  

*Deuxième difficulté, le choix de la persistance des données. J'ai fait le choix d'utiliser les volumes nommés de Docker  
plutôt que des bind mount pour plusieurs raisons : facilité de la CI/CD, la portabilité de la configuration et éviter  
des potentiels problèmes de permissions. Dans quelques cas, il pourrait être intéressant d'utiliser des bind mounts  
tout de même.*

- **Réseau** : Définition d'un réseau qui sera commun à tous nos service afin qu'ils puissent communiquer ensemble :  
`wp-network`

### 2.2 Service pour wordpress ainsi que la WP-CLI

- **Choix de l'image officielle sur le dockerhub** : Création d'une image personnalisée sur la base de l'image  
officielle de wordpress via un `Dockerfile`.

*Troisième difficulté, l'intégration de la wp-cli. J'ai d'abord essayé via un conteneur séparé avec l'image officielle  
de `wordpress:cli` mais au final j'ai décidé d'installer directement la CLI dans le conteneur de l'application wordpress  
pour plusieurs raisons : Limiter le nombre de conteneurs, compatible CI/CD, facilité de maintenance*

*Quatrième difficulté, gestion des dépendances dans le `Dockerfile`. J'ai voulu installer la wp-cli via `apt` dans le  
conteneur mais la cli n'existe pas dans la bibliothèque de paquets Debian, j'ai donc directement dû aller la chercher  
via `curl` sur le Github officiel. Je télécharge directement le fichier dans `/usr/local/bin/wp` pour pouvoir exécuter  
la cli avec un simple `wp`, je donne les droits d'éxécution et finalement je nettoie les fichiers temporaires pour  
alléger le conteneur* 

- **depends_on** : Afin de donner un ordre de priorité à la base de donnée avant de lancer l'application `wordpress`  
(attention ça ne veut pas dire qu'il attend que la bdd soit totalement prête. On pourrait modifier le code avec un  
healthcheck pour attendre que `MYSQL` soit vraiment prêt).

- **Ports** : On expose le port `80` du conteneur vers le port `8080` de la machine hôte.

- **Environnement** : Déclaration des variables d'environnements afin de sécuriser les secrets.

- **volumes** : Montage du volume `wp_data` sur le répertoire `/var/www/html/wp-content` du conteneur.

*Cinquième difficulté, persistance des données du site web tout en laissant la possibilité d'upgrade la version de  
Wordpress. J'avais initialement monté le volume `/var/www/html` mais cela empêchait la montée en version de wordpress  
car il y avait persistance des données de l'ancienne version de wordpress donc même si l'image se mettait à jour,  
wordpress restait lui sur l'ancienne configuration. J'ai donc dû monter un volume plus précis contenant les contenus  
spécifiques au site web à savoir `/var/www/html/wp-content`.* 

- **Réseau** : Définition d'un réseau qui sera commun à tous nos service afin qu'ils puissent communiquer ensemble :  
`wp-network`  

### 2.3 Service pour phpmyadmin

- **Choix de l'image officielle sur le dockerhub** : Ne pas prendre la version latest mais plutôt une version  stable  
et maintenue : `MYSQL:5.2.2-apache`. 

- **depends_on** : Afin de donner un ordre de priorité à la base de donnée avant de lancer le conteneur `phpmyadmin`.

- **Ports** : On expose le port 80 du conteneur vers le port 8081 de la machine hôte.

- **Environnement** : Déclaration des variables d'environnements afin de sécuriser les secrets.

- **volumes** : Montage du volume `wp_data` sur le répertoire `/var/www/html` du conteneur.  

- **Réseau** : Définition d'un réseau qui sera commun à tous nos service afin qu'ils puissent communiquer ensemble :  
`wp-network`

## 3 Déclaration du réseau

- Déclaration du réseau `wp-network` en modde bridge de façon à ce que les conteneurs puissent communiquer entres-eux  
mais de manière isolés.

## 4 Déclaration des volumes

- Déclaration des volumes `wp_data`et `db_data` utilisés pour la persistance des données.

## 5 Exécution de la configuration

- Afin de de démarrer l'environnement, il suffit de taper la commande :

```bash
docker compose up -d
```

- Pour l'arrêter, il suffit de taper la commande :

```bash
docker compose down
```

- Si des modifications sont apportées au `Dockerfile` ou à la configuration, il est nécessaire de reconstruire l’image  
WordPress avec :

```bash
docker compose up --build -d
```

## 6 Conclusions et perspectives

Ce projet permet le déploiement d'un environnement wordpress avec MYSQL et phpMyAdmin à l'aide de Docker et Docker Compose.  
C'est une solution portable, qui est facilement reproductible.

Plusieurs pistes d'amélioration pourraient être envisagées :

- Gestion des secrets différente comme évoqué plus haut.
- Proposer une solution de monitoring  pour surveiller les conteneurs et les logs.
- L'ajout d'un proxy inversé pour la sécurité.
- Voir en fonction des besoins la nécessité de réplication de la bdd par exemple.
- Intégration d'une pipeline CI/CD pour automatiser le build, le test et le déploiement.

## 7 Captures d'écran

- `docker ps`

![docker_ps](/images/docker_ps.png)

- Interface Administrateur :

![Ininterface_admin](/images/wordpress_admin.png)

- Page wordpress :

![page](/images/wordpress_page.png)