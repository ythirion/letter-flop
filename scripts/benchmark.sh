#!/usr/bin/env bash
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

HOST="${API_HOST:-http://localhost:8080}"
N="${AB_REQUESTS:-100}"
C="${AB_CONCURRENCY:-10}"
TMDB_MOVIE_ID="${TMDB_MOVIE_ID:-27205}"
SEARCH_QUERY="${SEARCH_QUERY:-inception}"

REPORT="$ROOT/benchmark-$(date +%Y%m%d-%H%M%S).md"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# ─── helpers ────────────────────────────────────────────────────────────────

check_deps() {
    if ! command -v ab &>/dev/null; then
        echo "❌  Apache Benchmark (ab) introuvable."
        echo "    macOS       : brew install httpd"
        echo "    Debian/Ubuntu : sudo apt install apache2-utils"
        exit 1
    fi
    if ! command -v curl &>/dev/null; then
        echo "❌  curl introuvable."
        exit 1
    fi
}

check_api() {
    echo "Vérification de l'API ($HOST)..."
    if ! curl -sf --max-time 5 "$HOST/api/logs?size=1" &>/dev/null; then
        echo "❌  L'API n'est pas joignable sur $HOST"
        echo "    Lance d'abord : ./scripts/start-backend.sh"
        exit 1
    fi
    echo "✅  API joignable"
}

write() { printf '%s\n' "$*" >> "$REPORT"; }

extract() {
    local pattern="$1" field="$2"
    echo "$RAW" | grep "$pattern" | awk "{print \$$field}" | head -1 || true
}

extract_percentile() {
    local pct="$1"
    echo "$RAW" | grep -E "^\s+${pct}%" | awk '{print $2}' | head -1 || true
}

render_header() {
    cat >> "$REPORT" <<EOF
# Letterflop — Rapport de benchmark API

> Généré le $(date '+%d/%m/%Y à %H:%M:%S')
> Outil : \`$(ab -V 2>&1 | head -1)\`
> Paramètres : **$N requêtes**, concurrence **$C** | Hôte : \`$HOST\`

---

## Table des matières

- [GET /api/logs](#get-apilogs)
- [GET /api/logs?size=1000 — la mauvaise pratique](#get-apilogssize1000--la-mauvaise-pratique)
- [GET /api/logs/movie/{tmdbId}](#get-apilogsmovietmdbid)
- [GET /api/movies/search](#get-apimoviesearch)
- [GET /api/movies/{tmdbId}](#get-apimovietmdbid)
- [POST /api/logs](#post-apilogs)
- [PUT /api/logs/{id}](#put-apilogsid)

---
EOF
}

run_bench() {
    local title="$1" url="$2"
    shift 2
    local ab_extra=("$@")
    local exit_code=0

    echo "  → $title"

    RAW=$(ab -n "$N" -c "$C" "${ab_extra[@]}" "$url" 2>&1) || exit_code=$?

    write ""
    write "## $title"
    write ""
    write "**URL** : \`$url\`"
    write ""

    if [ "$exit_code" -ne 0 ]; then
        write "> ⚠️ **Erreur ab (code $exit_code)** — l'URL est peut-être invalide ou le serveur a refusé la connexion."
        write ""
        write '```'
        write "$RAW"
        write '```'
        write ""
        write "---"
        return
    fi

    local complete failed rps mean_time transfer p50 p95 p99
    complete=$(extract  "Complete requests"   3)
    failed=$(extract    "Failed requests"     3)
    rps=$(extract       "Requests per second" 4)
    mean_time=$(extract "Time per request"    4)
    transfer=$(extract  "Transfer rate"       3)
    p50=$(extract_percentile 50)
    p95=$(extract_percentile 95)
    p99=$(extract_percentile 99)

    cat >> "$REPORT" <<TABLE
| Métrique                  | Valeur                       |
|---------------------------|------------------------------|
| Requêtes complètes        | ${complete:-n/a}             |
| Requêtes échouées         | ${failed:-n/a}               |
| Requêtes / seconde        | ${rps:-n/a} req/s            |
| Temps moyen / requête     | ${mean_time:-n/a} ms         |
| Débit                     | ${transfer:-n/a} KB/s        |
| Latence p50               | ${p50:-n/a} ms               |
| Latence p95               | ${p95:-n/a} ms               |
| Latence p99               | ${p99:-n/a} ms               |

<details>
<summary>Sortie brute ab</summary>

\`\`\`
$RAW
\`\`\`

</details>

---
TABLE
}

# ─── setup ──────────────────────────────────────────────────────────────────

check_deps
check_api

echo ""
echo "Rapport : $REPORT"
echo "Lancement des benchmarks ($N requêtes, concurrence $C)..."
echo ""

render_header

cat > "$TMP/create_log.json" <<JSON
{
  "tmdbId": $TMDB_MOVIE_ID,
  "title": "Benchmark Film",
  "year": 2010,
  "posterPath": null,
  "director": "Christopher Nolan",
  "synopsis": "Synopsis de test généré par le script de benchmark.",
  "rating": 4.0,
  "watchedAt": "$(date +%Y-%m-%d)",
  "comment": "Commentaire de benchmark"
}
JSON

cat > "$TMP/update_log.json" <<JSON
{
  "rating": 3.5,
  "watchedAt": "$(date +%Y-%m-%d)",
  "comment": "Mis à jour par le benchmark"
}
JSON

# Création d'un log de référence pour les routes PUT/DELETE
echo "  → Création d'un log de référence..."
CREATE_RESPONSE=$(curl -sf -X POST "$HOST/api/logs" \
    -H "Content-Type: application/json" \
    -d @"$TMP/create_log.json" 2>&1) || CREATE_RESPONSE=""

LOG_ID=""
if [ -n "$CREATE_RESPONSE" ]; then
    LOG_ID=$(echo "$CREATE_RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2 || true)
fi

if [ -z "$LOG_ID" ]; then
    echo "  ⚠️  Impossible de créer un log de référence — PUT sera ignoré"
fi

echo ""

# ─── benchmarks ─────────────────────────────────────────────────────────────

run_bench "GET /api/logs" \
    "$HOST/api/logs?page=0&size=20"

run_bench "GET /api/logs?size=1000 — la mauvaise pratique" \
    "$HOST/api/logs?page=0&size=1000"

run_bench "GET /api/logs/movie/{tmdbId}" \
    "$HOST/api/logs/movie/$TMDB_MOVIE_ID"

run_bench "GET /api/movies/search" \
    "$HOST/api/movies/search?query=$SEARCH_QUERY"

run_bench "GET /api/movies/{tmdbId}" \
    "$HOST/api/movies/$TMDB_MOVIE_ID"

run_bench "POST /api/logs" \
    "$HOST/api/logs" \
    -p "$TMP/create_log.json" \
    -T "application/json"

if [ -n "$LOG_ID" ]; then
    run_bench "PUT /api/logs/{id}" \
        "$HOST/api/logs/$LOG_ID" \
        -p "$TMP/update_log.json" \
        -T "application/json" \
        -m PUT
else
    write ""
    write "## PUT /api/logs/{id}"
    write ""
    write "> ⚠️ **Ignoré** — aucun log de référence n'a pu être créé."
    write ""
    write "---"
fi

echo ""
echo "✅  Benchmark terminé → $REPORT"
