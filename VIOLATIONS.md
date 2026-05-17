# Letterflop — Rapport de violations RGESN

> Rapport exhaustif des mauvaises pratiques intentionnellement présentes dans la codebase,
> organisé par couche technique. Chaque violation référence le fichier et la localisation exacte.

---

## Infrastructure & Conteneurs

### INF-1 — Image Docker backend surdimensionnée
**Fichier** : `backend/Dockerfile`, ligne 1  
**Critère RGESN** : 7.1 — Optimiser les images de conteneurs  
**Impact** : Image finale ~800 MB au lieu de ~200 MB  
L'image `eclipse-temurin:25` embarque le JDK complet (compilateur, outils de debug, man pages). Une image de production n'a besoin que du JRE. Sans multi-stage build, les sources Java et Maven sont aussi copiés dans l'image finale.  
**Correction** :
```dockerfile
FROM maven:3.9-eclipse-temurin-25-alpine AS build
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src ./src
RUN mvn package -DskipTests

FROM eclipse-temurin:25-jre-alpine
COPY --from=build /app/target/letterflop-*.jar app.jar
CMD ["java", "-jar", "app.jar"]
```

---

### INF-2 — Serveur de développement Vite en production
**Fichier** : `frontend/Dockerfile`, lignes 1 et 10  
**Critère RGESN** : 7.1, 7.2 — Optimiser les images / Utiliser un serveur adapté  
**Impact** : Image `node:24.15.0` ~1 GB ; serveur Vite dev actif en prod (pas de compression, pas de cache HTTP, hot-reload activé)  
`npm start` lance `vite --port 3000`, le serveur de développement. En production il faut builder les assets (`vite build`) et les servir avec nginx.  
**Correction** :
```dockerfile
FROM node:24.15.0-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
```

---

## Base de données

### DB-1 — Aucun index sur les colonnes fréquemment requêtées
**Fichier** : `backend/src/main/java/com/yot/letterflop/entity/MovieLog.java`, lignes 18, 25  
**Critère RGESN** : 4.9 — Optimiser les requêtes à la source de données  
**Impact** : Full table scan à chaque requête. Sur 10 000 lignes, PostgreSQL parcourt toutes les lignes pour trouver les résultats.  
Colonnes concernées : `tmdb_id` (requêté à chaque affichage de fiche film), `watched_at` (trié à chaque chargement de l'historique).  
**Correction** :
```sql
CREATE INDEX idx_movie_logs_tmdb_id    ON movie_logs (tmdb_id);
CREATE INDEX idx_movie_logs_watched_at ON movie_logs (watched_at DESC);
CREATE INDEX idx_movie_logs_title      ON movie_logs USING gin (title gin_trgm_ops);
```

---

### DB-2 — SELECT * : toutes les colonnes ramenées en mémoire
**Fichier** : `backend/src/main/java/com/yot/letterflop/repository/MovieLogRepository.java`, ligne 11  
**Critère RGESN** : 4.9  
**Impact** : La colonne `synopsis TEXT` (jusqu'à plusieurs Ko par ligne) est transférée même pour l'affichage de la liste où seuls titre, note, date et affiche sont nécessaires.  
**Correction** : Utiliser une projection Spring Data JPA :
```java
interface MovieLogSummary {
    Long getId(); String getTitle(); BigDecimal getRating(); LocalDate getWatchedAt(); String getPosterPath();
}
List<MovieLogSummary> findAllProjectedBy();
```

---

### DB-3 — COUNT via chargement de tous les objets
**Fichier** : `backend/src/main/java/com/yot/letterflop/service/MovieLogService.java`, méthode `getTotalCount()`, ligne 53  
**Critère RGESN** : 4.9  
**Impact** : `repository.findAll().size()` instancie tous les objets `MovieLog` en mémoire juste pour compter.  
**Correction** : `repository.count()` → `SELECT COUNT(*) FROM movie_logs`

---

## Backend — Appels réseau & Cache

### NET-1 — Problème N+1 : un appel HTTP par film dans la recherche
**Fichier** : `backend/src/main/java/com/yot/letterflop/service/TmdbService.java`, méthode `searchMovies()`, ligne 43  
**Critère RGESN** : 4.7 — Limiter les appels réseau  
**Impact** : Une recherche retournant 20 films déclenche **21 appels HTTP** vers TMDB (1 search + 20 × `/credits`). Chaque appel supplémentaire mobilise un thread et rallonge le temps de réponse.  
**Correction** : Utiliser `append_to_response=credits` sur l'endpoint `/search/movie`, ou ne récupérer le réalisateur que sur la fiche détail.

---

### NET-2 — Aucun cache sur les appels TMDB
**Fichier** : `backend/src/main/java/com/yot/letterflop/service/TmdbService.java`, méthodes `searchMovies()` et `getMovieDetail()`  
**Critère RGESN** : 4.8 — Mettre en cache les données calculées  
**Impact** : Chaque visite de la fiche d'un film déclenche 2 appels HTTP vers TMDB, même si consulté 10 secondes auparavant. Les données TMDB sont quasi-statiques.  
**Correction** :
```java
@Cacheable("tmdb-movies")
public MovieDetailDto getMovieDetail(Integer tmdbId) { ... }
```

---

### NET-3 — RestTemplate sans timeout ni pool de connexions
**Fichier** : `backend/src/main/java/com/yot/letterflop/config/RestTemplateConfig.java`, ligne 11  
**Critère RGESN** : 4.7  
**Impact** : Un appel TMDB lent peut bloquer un thread indéfiniment. Pas de pool → chaque requête ouvre une nouvelle connexion TCP.  
**Correction** : Configurer `HttpComponentsClientHttpRequestFactory` avec `connectTimeout`, `readTimeout` et un pool via Apache HttpClient.

---

### NET-4 — Images TMDB en résolution "original"
**Fichier** : `backend/src/main/java/com/yot/letterflop/service/TmdbService.java`, lignes 47 et 70  
**Critère RGESN** : 4.2 — Adapter les médias à leur contexte d'affichage  
**Impact** : Images ~500 KB à 2 MB pour des vignettes affichées en 200 px. TMDB propose `w185`, `w342`, `w500`.  
**Correction** : `w185` pour les vignettes de liste, `w342` pour la fiche film.

---

## Backend — Qualité du code

### CODE-1 — Pagination en Java après chargement total depuis la DB
**Fichier** : `backend/src/main/java/com/yot/letterflop/service/MovieLogService.java`, méthode `getAllLogs()`, lignes 22–48  
**Critère RGESN** : 4.9, 4.10  
**Impact** : Tous les logs chargés en mémoire quel que soit le total, puis découpés. + `getTotalCount()` fait un second full table scan → **2 full table scans** par requête de liste.  
**Correction** :
```java
Page<MovieLog> findAllByOrderByWatchedAtDescCreatedAtDesc(Pageable pageable);
```

---

### CODE-2 — Mapping entity→DTO dupliqué trois fois
**Fichier** : `backend/src/main/java/com/yot/letterflop/service/MovieLogService.java`, méthodes `getAllLogs()` (ligne 36), `getLogsByTmdbId()` (ligne 60), `toDto()` (ligne 94)  
**Critère RGESN** : 4.10  
**Impact** : Le même bloc de 11 affectations est copié au lieu d'appeler `toDto()` partout.  
**Correction** : Appeler systématiquement `toDto()`, ou utiliser MapStruct.

---

### CODE-3 — Lambda avec liste intermédiaire inutile
**Fichier** : `backend/src/main/java/com/yot/letterflop/service/TmdbService.java`, méthode `getMovieDetail()`, ligne 80  
**Critère RGESN** : 4.10  
**Correction** :
```java
dto.setGenres(genres.stream().map(g -> (String) g.get("name")).toList());
```

---

## Frontend — Médias & Performance de chargement

### FRONT-1 — Images sans lazy loading
**Fichiers** : `frontend/src/pages/search.ts` (ligne 38), `frontend/src/pages/movie.ts` (ligne 44), `frontend/src/pages/history.ts` (ligne 36)  
**Critère RGESN** : 4.2  
**Impact** : Toutes les affiches de la grille (jusqu'à 20) et de l'historique (6 par page) se téléchargent simultanément, même celles hors écran. Sur mobile 4G, plusieurs MB de données inutiles.  
**Correction** : Ajouter `loading="lazy"` à chaque `<img>` généré dans les template literals.

---

### FRONT-2 — Images sans `width` et `height` → Layout Shift
**Fichiers** : `frontend/src/pages/search.ts` (ligne 38), `frontend/src/pages/movie.ts` (ligne 44)  
**Critère RGESN** : 4.2  
**Impact** : Sans dimensions explicites, le navigateur ne peut pas réserver l'espace. La page « saute » quand les images arrivent (CLS élevé).  
**Correction** : Ajouter `width="200" height="300"` (ou via `style`) sur chaque `<img>`.

---

### FRONT-3 — Google Fonts render-blocking
**Fichiers** : `frontend/index.html` (ligne 7), `frontend/movie.html` (ligne 7), `frontend/history.html` (ligne 7)  
**Critère RGESN** : 3.3 — Performances de chargement  
**Impact** : `display=block` bloque le rendu de tout le texte jusqu'au chargement de la police. Sans `preconnect`, la négociation DNS+TCP+TLS ajoute 200–500 ms.  
**Correction** :
```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&display=swap" rel="stylesheet">
```

---

### FRONT-4 — Appel API répété à chaque changement de page + filtrage côté client
**Fichier** : `frontend/src/pages/history.ts`, fonction `loadPage()`  
**Critère RGESN** : 4.9  
**Impact** : À chaque clic sur "Précédent" / "Suivant", `getLogs(0, 1000)` est rappelé — 1 000 logs complets (avec synopsis TEXT) sont retéléchargés pour en afficher 6. Le backend recharge lui-même toute la DB à chaque requête → triple inefficacité : N appels réseau × 1 000 lignes × full table scan.  
**Correction** : Appeler `getLogs(page, 6)` directement et laisser le backend paginer via `Pageable`.

---

### FRONT-5 — Aucun cache côté client
**Fichier** : `frontend/src/api/api.ts`  
**Critère RGESN** : 4.8  
**Impact** : Chaque navigation vers une page film déclenche deux `fetch()`, même si le film a été consulté dans la même session.  
**Correction** : Mémoïser les résultats dans une `Map` keyed par `tmdbId`, ou utiliser le Cache API du navigateur.

---

## Frontend — Accessibilité & Navigation clavier

### A11Y-1 — Cartes film inaccessibles au clavier
**Fichier** : `frontend/src/pages/search.ts`, ligne 53  
**Critère RGESN** : 10.2 — Navigation clavier  
**Impact** : Les cartes utilisent `addEventListener('click')` sur un `<div>` sans `tabIndex` ni handler `keydown`. Un utilisateur naviguant au clavier ne peut ni atteindre ni activer une carte.  
**Correction** :
```typescript
card.setAttribute('tabindex', '0');
card.setAttribute('role', 'button');
card.addEventListener('keydown', (e: KeyboardEvent) => {
  if (e.key === 'Enter') window.location.href = `/movie.html?id=${id}`;
});
```

---

### A11Y-2 — Notation par étoiles inaccessible au clavier
**Fichier** : `frontend/src/pages/movie.ts`, fonction `attachStarInput()`, ligne 120  
**Critère RGESN** : 10.2  
**Impact** : `mouseenter` / `mouseleave` / `click` uniquement. Un utilisateur au clavier ne peut pas noter un film — la fonctionnalité de log est totalement bloquée pour lui.  
**Correction** : Utiliser des `<input type="radio">` natifs avec `aria-label` :
```html
<input type="radio" name="rating" value="1" aria-label="1 étoile" />
```

---

### A11Y-3 — Absence de focus visible sur les éléments interactifs
**Fichiers** : `frontend/index.html` (classe `focus:outline-none` sur l'input, ligne 20), `frontend/src/pages/movie.ts` (classe sur les textareas/inputs)  
**Critère RGESN** : 10.2  
**Impact** : `focus:outline-none` (Tailwind) supprime l'indicateur de focus natif. Les utilisateurs au clavier ne savent pas où ils sont — violation WCAG 2.4.7.  
**Correction** : Remplacer par `focus:outline focus:outline-2 focus:outline-red-500` ou configurer un outline custom dans `tailwind.config.js`.

---

### A11Y-4 — Attributs `alt` vides sur les affiches de films
**Fichiers** : `frontend/src/pages/search.ts` (ligne 38), `frontend/src/pages/movie.ts` (ligne 44), `frontend/src/pages/history.ts` (ligne 36)  
**Critère RGESN** : 10.1 — Accessibilité du contenu  
**Impact** : `alt=""` est correct pour les images purement décoratives, mais les affiches de films sont du contenu informatif. Un lecteur d'écran les ignore totalement.  
**Correction** : Ajouter `alt="Affiche du film ${movie.title}"` dans chaque template literal.

---

### A11Y-5 — Champ de recherche sans label accessible
**Fichier** : `frontend/index.html`, ligne 20  
**Critère RGESN** : 10.1  
**Impact** : L'`<input>` n'a ni `<label>` associé ni `aria-label`. Un lecteur d'écran annonce juste « champ de saisie » sans contexte.  
**Correction** : `<input aria-label="Rechercher un film par titre" ... />`
