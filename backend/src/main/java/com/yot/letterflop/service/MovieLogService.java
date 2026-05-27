package com.yot.letterflop.service;

import com.yot.letterflop.dto.CreateLogRequest;
import com.yot.letterflop.dto.MovieLogDto;
import com.yot.letterflop.dto.UpdateLogRequest;
import com.yot.letterflop.entity.MovieLog;
import com.yot.letterflop.repository.MovieLogRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class MovieLogService {

    private static final String TMDB_IMAGE_BASE = "https://image.tmdb.org/t/p/w92";
    private static final String TMDB_URL_PREFIX_PATTERN = "https://image\\.tmdb\\.org/t/p/[^/]+";

    private final MovieLogRepository repository;

    public MovieLogService(MovieLogRepository repository) {
        this.repository = repository;
    }

    // 7.1a : une seule requête SQL, triée et paginée par la DB
    // Spring Data traduit findAllByOrderByWatchedAtDescCreatedAtDesc(Pageable) en :
    //
    //   SELECT * FROM movie_logs
    //   ORDER BY watched_at DESC, created_at DESC
    //   LIMIT :size OFFSET :page * :size
    //
    // Le tri et la pagination sont délégués à PostgreSQL.
    // Aucune entité hors de la page demandée n'est chargée en mémoire.
    public Page<MovieLogDto> getAllLogs(int page, int size) {
        return repository.findAllByOrderByWatchedAtDescCreatedAtDesc(PageRequest.of(page, size))
                .map(this::toDto);
    }

    public List<MovieLogDto> getLogsByTmdbId(Integer tmdbId) {
        return repository.findByTmdbId(tmdbId)
                .stream()
                .map(this::toDto)
                .toList();
    }

    public MovieLogDto createLog(CreateLogRequest request) {
        MovieLog log = new MovieLog();
        log.setTmdbId(request.getTmdbId());
        log.setTitle(request.getTitle());
        log.setYear(request.getYear());
        // 7.2b : stocker uniquement le chemin TMDB, pas l'URL complète
        log.setPosterPath(extractTmdbPath(request.getPosterPath()));
        log.setDirector(request.getDirector());
        log.setSynopsis(request.getSynopsis());
        log.setRating(request.getRating());
        log.setWatchedAt(request.getWatchedAt());
        log.setComment(request.getComment());

        return toDto(repository.save(log));
    }

    public MovieLogDto updateLog(Long id, UpdateLogRequest request) {
        MovieLog log = repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Log not found: " + id));

        log.setRating(request.getRating());
        log.setWatchedAt(request.getWatchedAt());
        log.setComment(request.getComment());

        return toDto(repository.save(log));
    }

    public void deleteLog(Long id) {
        repository.deleteById(id);
    }

    // 7.2b : chemin relatif TMDB → URL complète avec taille adaptée (w92 = vignette 60px)
    private MovieLogDto toDto(MovieLog log) {
        MovieLogDto dto = new MovieLogDto();
        dto.setId(log.getId());
        dto.setTmdbId(log.getTmdbId());
        dto.setTitle(log.getTitle());
        dto.setYear(log.getYear());
        dto.setPosterPath(log.getPosterPath() != null ? TMDB_IMAGE_BASE + log.getPosterPath() : null);
        dto.setDirector(log.getDirector());
        dto.setSynopsis(log.getSynopsis());
        dto.setRating(log.getRating());
        dto.setWatchedAt(log.getWatchedAt());
        dto.setComment(log.getComment());
        dto.setCreatedAt(log.getCreatedAt());

        return dto;
    }

    // Supprime le préfixe "https://image.tmdb.org/t/p/<size>" pour ne garder que le chemin
    private String extractTmdbPath(String posterPath) {
        if (posterPath == null) return null;
        return posterPath.replaceAll(TMDB_URL_PREFIX_PATTERN, "");
    }
}
