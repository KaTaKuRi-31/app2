# ---------- STAGE 1: Installation des dépendances ----------
FROM node:18-alpine AS deps
WORKDIR /app

# Copie les fichiers de dépendances
COPY package.json yarn.lock ./

# Installe les dépendances de production avec Yarn 1.x
RUN corepack enable && \
    yarn install --production --frozen-lockfile

# ---------- STAGE 2: Image finale (runtime) ----------
FROM node:18-alpine AS runtime

# Variables d'environnement
ENV NODE_ENV=production

WORKDIR /app

# Copie uniquement les node_modules de production depuis le stage précédent
COPY --from=deps /app/node_modules ./node_modules

# Copie le code source
COPY . .

# Expose le port 3000
EXPOSE 3000

# Healthcheck (vérifie que l'app répond)
HEALTHCHECK --interval=10s --timeout=3s --retries=5 \
  CMD wget -qO- http://localhost:3000/items || exit 1

# Lance l'application (SANS nodemon, en mode prod)
CMD ["node", "src/index.js"]
