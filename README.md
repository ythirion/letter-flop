# Letterflop — Application de démonstration RGESN

> Application intentionnellement **non optimisée** pour illustrer les critères du [RGESN](https://www.rgesn.fr/) lors d'un cours sur l'écoconception des services numériques.

## Stack technique

| Couche          | Technologie                              |
|-----------------|------------------------------------------|
| Base de données | PostgreSQL 15                            |
| API             | Spring Boot 3.5 (Java 25)                |
| Frontend        | Vanilla TypeScript + Tailwind CSS (Vite) |
| Infra           | Docker / docker-compose                  |

## Configuration

Copier le fichier d'exemple et renseigner ta clé TMDB :

```bash
cp .env.example .env
```

Éditer `.env` et remplacer `your_tmdb_api_key_here` par ta clé (disponible sur [themoviedb.org](https://www.themoviedb.org/) → Settings → API).

---

## Lancer l'application

### Stack complète (Docker)

```bash
# Premier lancement (ou après un changement de Dockerfile)
docker compose build --no-cache 
docker compose up

# Lancements suivants
docker compose up --build
```

- Frontend : http://localhost:3000
- Backend API : http://localhost:8080
- Swagger UI : http://localhost:8080/swagger-ui.html
- OpenAPI JSON : http://localhost:8080/v3/api-docs
- Base de données : localhost:5432

### Backend seul (développement)

Prérequis : Java 25 et Maven installés localement.

**1. Démarrer uniquement la base de données**

```bash
docker compose up db -d
```

**2. Lancer le backend**

```bash
cd backend
export $(grep -v '^#' ../.env | xargs) && mvn spring-boot:run
```

- Backend API : http://localhost:8080
- Swagger UI : http://localhost:8080/swagger-ui.html

**Arrêter la base de données**

```bash
docker compose stop db
```

### Benchmark API

Prérequis : `ab` (Apache Benchmark) et l'API démarrée.

```bash
# macOS
brew install httpd

# Debian/Ubuntu
sudo apt install apache2-utils
```

```bash
./scripts/benchmark.sh
```

Le rapport est généré dans `benchmark-YYYYMMDD-HHMMSS.md` à la racine du projet.

Variables d'environnement disponibles :

| Variable | Défaut | Description |
|---|---|---|
| `API_HOST` | `http://localhost:8080` | URL de l'API |
| `AB_REQUESTS` | `100` | Nombre de requêtes par route |
| `AB_CONCURRENCY` | `10` | Requêtes simultanées |
| `TMDB_MOVIE_ID` | `27205` | ID TMDB utilisé pour les routes film |
| `SEARCH_QUERY` | `inception` | Requête de recherche |

```bash
AB_REQUESTS=200 AB_CONCURRENCY=20 ./scripts/benchmark.sh
```

---

## Structure du projet

```
letterflop/
├── .env.example
├── .gitignore
├── docker-compose.yml
├── db/
│   └── init.sql                             ← schéma + ~330 visionnages de démo
├── backend/
│   ├── Dockerfile
│   ├── pom.xml
│   └── src/main/
│       ├── java/com/yot/letterflop/
│       │   ├── LetterflopApplication.java
│       │   ├── config/
│       │   │   ├── OpenApiConfig.java
│       │   │   └── RestTemplateConfig.java
│       │   ├── controller/
│       │   │   ├── LogController.java
│       │   │   └── MovieController.java
│       │   ├── dto/
│       │   │   ├── CreateLogRequest.java
│       │   │   ├── MovieDetailDto.java
│       │   │   ├── MovieLogDto.java
│       │   │   ├── MovieSearchResultDto.java
│       │   │   └── UpdateLogRequest.java
│       │   ├── entity/
│       │   │   └── MovieLog.java
│       │   ├── repository/
│       │   │   └── MovieLogRepository.java
│       │   └── service/
│       │       ├── MovieLogService.java
│       │       └── TmdbService.java
│       └── resources/
│           └── application.properties
└── frontend/
    ├── .dockerignore
    ├── Dockerfile
    ├── package.json
    ├── tsconfig.json
    ├── vite.config.ts
    ├── tailwind.config.js
    ├── postcss.config.js
    ├── index.html                           ← page Recherche
    ├── movie.html                           ← page Fiche film
    ├── history.html                         ← page Historique
    └── src/
        ├── style.css                        ← directives Tailwind
        ├── types.ts                         ← interfaces partagées
        ├── api/
        │   └── api.ts                       ← appels fetch vers le backend
        └── pages/
            ├── search.ts                    ← logique page recherche
            ├── movie.ts                     ← logique page fiche film
            └── history.ts                   ← logique page historique
```
