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
├── VIOLATIONS.md                            ← rapport de violations RGESN
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

---

## Catalogue des mauvaises pratiques RGESN

### Hébergement & Infrastructure

| # | Fichier | Mauvaise pratique | Critère RGESN |
|---|---------|-------------------|---------------|
| H1 | `backend/Dockerfile` | Image `eclipse-temurin:25` (~800 MB) sans multi-stage build | 7.1 — Optimiser les images |
| H2 | `frontend/Dockerfile` | Image `node:24.15.0` (~1 GB) + serveur de dev Vite en production | 7.1, 7.2 |

### Base de données

| # | Fichier | Mauvaise pratique | Critère RGESN |
|---|---------|-------------------|---------------|
| DB1 | `MovieLog.java` | Aucun index sur `tmdb_id`, `watched_at` → full table scan | 4.9 |
| DB2 | `MovieLogRepository.java` | `SELECT *` : `synopsis TEXT` remonté même pour les listes | 4.9 |
| DB3 | `MovieLogService.java` | `findAll().size()` au lieu de `SELECT COUNT(*)` | 4.9 |

### Backend — Requêtes & Cache

| # | Fichier | Mauvaise pratique | Critère RGESN |
|---|---------|-------------------|---------------|
| B1 | `TmdbService.java:searchMovies()` | N+1 : 1 appel HTTP par film pour récupérer le réalisateur | 4.7 |
| B2 | `TmdbService.java` | Aucun cache sur les appels TMDB | 4.8 |
| B3 | `MovieLogService.java:getAllLogs()` | Charge tous les logs en mémoire, pagine en Java | 4.9 |
| B4 | `RestTemplateConfig.java` | RestTemplate sans timeout ni pool de connexions | 4.7 |
| B5 | `TmdbService.java` | Images TMDB en taille `original` pour des vignettes de 200 px | 4.2 |

### Backend — Code Java

| # | Fichier | Mauvaise pratique | Critère RGESN |
|---|---------|-------------------|---------------|
| J1 | `TmdbService.java:getMovieDetail()` | `forEach` + liste intermédiaire au lieu de `stream().map().toList()` | 4.10 |
| J2 | `MovieLogService.java` | Mapping entity→DTO dupliqué à 3 endroits | 4.10 |
| J3 | `LogController.java` | Deux requêtes DB séparées (liste + count) | 4.9 |

### Frontend — Médias & Performance

| # | Fichier | Mauvaise pratique | Critère RGESN |
|---|---------|-------------------|---------------|
| F1 | `search.ts`, `movie.ts`, `history.ts` | Images sans `loading="lazy"` | 4.2 |
| F2 | `search.ts`, `movie.ts` | Images sans `width`/`height` → Layout Shift | 4.2 |
| F3 | `index.html`, `movie.html`, `history.html` | Google Fonts sans `preconnect` ni `display=swap` | 3.3 |
| F4 | `history.ts` | `getLogs(0, 1000)` → pagination côté client sur 6 éléments | 4.9 |
| F5 | `api/api.ts` | Aucun cache côté client pour les appels API | 4.8 |

### Frontend — Accessibilité & Navigation clavier

| # | Fichier | Mauvaise pratique | Critère RGESN |
|---|---------|-------------------|---------------|
| A1 | `search.ts` | `<div>` cliquable sans `tabindex` ni `keydown` | 10.2 |
| A2 | `movie.ts:attachStarInput()` | Notation uniquement à la souris | 10.2 |
| A3 | `index.html`, `movie.ts` | `focus:outline-none` → focus invisible au clavier | 10.2 |
| A4 | `search.ts`, `movie.ts`, `history.ts` | `alt=""` vide sur les affiches de films | 10.1 |
| A5 | `index.html` | Input de recherche sans `aria-label` | 10.1 |

---

## Pistes d'optimisation (pour la partie "après" du cours)

### Hébergement
- Multi-stage build backend : `maven:3.9-eclipse-temurin-25-alpine` → `eclipse-temurin:25-jre-alpine`
- Frontend : `npm run build` (Vite) + `nginx:alpine` pour servir les assets statiques

### Base de données
```sql
CREATE INDEX idx_movie_logs_tmdb_id    ON movie_logs (tmdb_id);
CREATE INDEX idx_movie_logs_watched_at ON movie_logs (watched_at DESC);
```
- `Pageable` de Spring Data JPA au lieu de `findAll()`
- Projections SQL pour ne pas ramener `synopsis` dans les listes

### Cache backend
```java
@Cacheable("tmdb-movies")
public MovieDetailDto getMovieDetail(Integer tmdbId) { ... }
```

### Frontend
```typescript
// Lazy loading images
`<img src="${url}" loading="lazy" width="200" height="300" alt="Affiche du film ${title}">`

// Accessibilité clavier sur les cartes
card.setAttribute('tabindex', '0');
card.addEventListener('keydown', (e) => { if (e.key === 'Enter') navigate(); });

// Cache simple en mémoire
const cache = new Map<number, MovieDetail>();
```
- Tailles d'images adaptées : `w185` pour les vignettes, `w342` pour la fiche film
- `<input aria-label="Rechercher un film par titre">` + `focus:outline` Tailwind
