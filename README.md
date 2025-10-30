Projet Todo App – Conteneurisation et Déploiement (Docker, Caddy, AWS)
Objectif
Mettre en place une application web (Todo App) conteneurisée avec Docker, puis la déployer sur une instance AWS EC2 à l’aide de Docker Compose et d’un reverse proxy Caddy, dans un premier temps en HTTP uniquement.

Étape 1 – Structure du projet
Arborescence initiale :
todo-app/
├── backend/
│   ├── package.json
│   ├── server.js
│   └── ...
├── frontend/
│   ├── package.json
│   ├── src/
│   └── ...
└── Dockerfile

L’application comprend :


un backend Node.js/Express


un frontend React, compilé et servi statiquement par le backend



Étape 2 – Création du Dockerfile
Créer le fichier Dockerfile à la racine du projet :
Étape 1 : build du frontend
FROM node:18 AS builder
WORKDIR /app
COPY frontend ./frontend
RUN cd frontend && npm install && npm run build

Étape 2 : backend + build du frontend
FROM node:18-alpine
WORKDIR /app

COPY backend ./backend
COPY --from=builder /app/frontend/build ./backend/public

WORKDIR /app/backend
RUN npm install

ENV PORT=3000
EXPOSE 3000

CMD ["npm", "start"]


Étape 3 – Test local
Construction de l’image
docker build -t todo-app:dev .

Exécution du conteneur
docker run -d --name app -p 3000:3000 todo-app:dev

Vérification
curl http://localhost:3000

L’application doit renvoyer le code HTML de la page Todo.

Étape 4 – Image de production & push Docker Hub
Tag de l’image
docker tag todo-app:dev katakuri31/todo-app:prod

Connexion à Docker Hub
docker login

Envoi de l’image
docker push katakuri31/todo-app:prod


Étape 5 – Création et configuration d’une instance AWS EC2


Créer une instance EC2 Debian ou Ubuntu (ex. t2.micro)


Associer une Elastic IP (EIP) à l’instance


Ouvrir les ports suivants dans le Security Group :


22 (SSH)


80 (HTTP)


443 (HTTPS, pour la suite)




Connexion à la machine :
ssh -i <fichier.pem> admin@<IP_EC2>


Étape 6 – Installation de Docker et Docker Compose sur la VM
sudo apt update && sudo apt upgrade -y
sudo apt install -y docker.io docker-compose-plugin
sudo systemctl enable --now docker


Étape 7 – Vérification de l’image sur la VM
sudo docker pull katakuri31/todo-app:prod
sudo docker run -d --name app -p 3000:3000 katakuri31/todo-app:prod
curl http://localhost:3000

L’application doit être accessible en local sur la VM.

Étape 8 – Configuration du domaine DuckDNS


Créer un compte sur https://www.duckdns.org


Créer un sous-domaine (exemple : katakuri31)


Mettre à jour l’adresse IP publique de l’instance :


export DUCKDNS_DOMAIN="katakuri31"
export DUCKDNS_TOKEN="TON_TOKEN_ICI"
export AWSIP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

curl "https://www.duckdns.org/update?domains=${DUCKDNS_DOMAIN}&token=${DUCKDNS_TOKEN}&ip=${AWSIP}"

Vérification :
dig +short katakuri31.duckdns.org

L’adresse IP retournée doit être celle de l’instance AWS.

Étape 9 – Mise en place du reverse proxy avec Caddy (HTTP)
Création du répertoire de déploiement
mkdir -p ~/todo-deploy
cd ~/todo-deploy

Fichier docker-compose-prod.yml
version: '3.8'

services:
  app:
    image: katakuri31/todo-app:prod
    container_name: todo-deploy-app
    expose:
      - "3000"
    networks:
      - web

  caddy:
    image: caddy:2
    container_name: todo-deploy-caddy
    ports:
      - "80:80"
      # - "443:443" (désactivé pour le mode HTTP)
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - caddy_data:/data
      - caddy_config:/config
    depends_on:
      - app
    networks:
      - web

networks:
  web:
    driver: bridge

volumes:
  caddy_data:
  caddy_config:

Fichier Caddyfile
{
  auto_https off
}

http://:80 {
  reverse_proxy app:3000
  log
}

Lancement de la stack
sudo docker compose -f docker-compose-prod.yml up -d


Étape 10 – Vérification du déploiement HTTP
Sur la VM :
curl -I http://localhost

Réponse attendue :
HTTP/1.1 200 OK

Depuis un poste externe :
curl -I http://katakuri31.duckdns.org

Réponse attendue :
HTTP/1.1 200 OK

L’application est alors accessible via :
http://katakuri31.duckdns.org

Étape 11 – Schéma de l’architecture
[ Navigateur ]
      │
      ▼
[ Caddy (port 80) ]
      │
      ▼
[ Conteneur app (port 3000) ]



Caddy joue le rôle de reverse proxy HTTP


Docker Compose gère la communication interne entre les conteneurs


DuckDNS fournit la résolution de domaine vers l’IP publique AWS


Le port 80 est ouvert et sert le trafic web


HTTPS peut être activé ultérieurement sans modification majeure



Étape 12 – Passage optionnel à HTTPS
Pour activer automatiquement HTTPS avec Let’s Encrypt :
Modifier le Caddyfile :
katakuri31.duckdns.org {
  reverse_proxy app:3000
  log
}

Recharger la configuration :
sudo docker exec todo-deploy-caddy caddy reload --config /etc/caddy/Caddyfile

Caddy obtiendra automatiquement un certificat TLS et redirigera HTTP → HTTPS.

Étape 13 – Résumé des commandes principales
ÉtapeCommandeConstruction de l’imagedocker build -t todo-app:dev .Test localdocker run -p 3000:3000 todo-app:devPublication Docker Hubdocker push katakuri31/todo-app:prodDéploiement sur AWSsudo docker run -d -p 3000:3000 katakuri31/todo-app:prodLancement de la stacksudo docker compose -f docker-compose-prod.yml up -dVérification externecurl -I http://katakuri31.duckdns.org

Conclusion
Le projet Todo App est entièrement conteneurisé et déployé sur AWS. L’application est accessible via un reverse proxy Caddy configuré en HTTP. La configuration est prête à évoluer vers une version sécurisée HTTPS avec Let’s Encrypt.

___________________________________________________________________________________________
___________________________________________________________________________________________

Voici la comande a copie colle pour faire le test 

git clone https://github.com/KaTaKuRi-31/app2.git
cd app2
docker compose -f docker-compose-prod.yml up -d
