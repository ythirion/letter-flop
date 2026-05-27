-- =============================================================
-- Migration 7.2b : stocker le chemin TMDB, pas l'URL complète
-- Avant : "https://image.tmdb.org/t/p/original/pB8BM7pd.jpg"
-- Après : "/pB8BM7pd.jpg"
-- =============================================================

UPDATE movie_logs
SET poster_path = regexp_replace(
    poster_path,
    '^https://image\.tmdb\.org/t/p/[^/]+',
    ''
)
WHERE poster_path LIKE 'https://image.tmdb.org/t/p/%';

-- Vérification
SELECT id, title, poster_path FROM movie_logs LIMIT 5;
