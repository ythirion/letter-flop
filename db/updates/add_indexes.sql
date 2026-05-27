-- =============================================================
-- Index manquants sur movie_logs
-- À jouer une fois sur la base existante
-- =============================================================

-- Index sur tmdb_id : utilisé par findByTmdbId (ouverture d'une fiche film)
-- Remplace un full table scan O(n) par une lecture B-tree O(log n)
CREATE INDEX IF NOT EXISTS idx_movie_logs_tmdb_id
    ON movie_logs(tmdb_id);

-- Index composite sur watched_at + created_at : utilisé par ORDER BY
-- Remplace un tri en mémoire sur toute la table par une lecture ordonnée
CREATE INDEX IF NOT EXISTS idx_movie_logs_watched_at
    ON movie_logs(watched_at DESC, created_at DESC);
