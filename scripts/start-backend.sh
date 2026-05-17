#!/usr/bin/env bash
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if ! command -v mvn &>/dev/null; then
    echo "❌  mvn introuvable — installe Maven ou ajoute-le au PATH."
    exit 1
fi

echo "Démarrage de la base de données..."
docker compose -f "$ROOT/docker-compose.yml" up db -d

echo "Chargement des variables d'environnement..."
export $(grep -v '^#' "$ROOT/.env" | xargs)

echo "Lancement du backend..."
cd "$ROOT/backend"
mvn spring-boot:run
