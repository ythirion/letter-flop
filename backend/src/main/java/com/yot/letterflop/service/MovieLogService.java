package com.yot.letterflop.service;

import com.yot.letterflop.dto.CreateLogRequest;
import com.yot.letterflop.dto.MovieLogDto;
import com.yot.letterflop.dto.UpdateLogRequest;
import com.yot.letterflop.entity.MovieLog;
import com.yot.letterflop.repository.MovieLogRepository;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class MovieLogService {

    private final MovieLogRepository repository;

    public MovieLogService(MovieLogRepository repository) {
        this.repository = repository;
    }

    public List<MovieLogDto> getAllLogs(int page, int size) {
        List<MovieLog> allLogs = repository.findAllOrderByWatchedAtDesc();

        List<MovieLog> sorted = allLogs.stream()
                .sorted(Comparator.comparing(MovieLog::getWatchedAt).reversed()
                        .thenComparing(Comparator.comparing(MovieLog::getCreatedAt).reversed()))
                .toList();

        int start = page * size;
        int end = Math.min(start + size, sorted.size());

        if (start >= sorted.size()) {
            return new ArrayList<>();
        }

        return sorted.subList(start, end)
                .stream()
                .map(log -> {
                    MovieLogDto dto = new MovieLogDto();
                    dto.setId(log.getId());
                    dto.setTmdbId(log.getTmdbId());
                    dto.setTitle(log.getTitle());
                    dto.setYear(log.getYear());
                    dto.setPosterPath(log.getPosterPath());
                    dto.setDirector(log.getDirector());
                    dto.setSynopsis(log.getSynopsis());
                    dto.setRating(log.getRating());
                    dto.setWatchedAt(log.getWatchedAt());
                    dto.setComment(log.getComment());
                    dto.setCreatedAt(log.getCreatedAt());
                    return dto;
                })
                .toList();
    }

    public int getTotalCount() {
        return (int) repository.findAll().size();
    }

    public List<MovieLogDto> getLogsByTmdbId(Integer tmdbId) {
        List<MovieLog> logs = repository.findByTmdbId(tmdbId);

        List<MovieLogDto> dtos = new ArrayList<>();
        for (MovieLog log : logs) {
            MovieLogDto dto = new MovieLogDto();
            dto.setId(log.getId());
            dto.setTmdbId(log.getTmdbId());
            dto.setTitle(log.getTitle());
            dto.setYear(log.getYear());
            dto.setPosterPath(log.getPosterPath());
            dto.setDirector(log.getDirector());
            dto.setSynopsis(log.getSynopsis());
            dto.setRating(log.getRating());
            dto.setWatchedAt(log.getWatchedAt());
            dto.setComment(log.getComment());
            dto.setCreatedAt(log.getCreatedAt());
            dtos.add(dto);
        }
        return dtos;
    }

    public MovieLogDto createLog(CreateLogRequest request) {
        MovieLog log = new MovieLog();
        log.setTmdbId(request.getTmdbId());
        log.setTitle(request.getTitle());
        log.setYear(request.getYear());
        log.setPosterPath(request.getPosterPath());
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

    private MovieLogDto toDto(MovieLog log) {
        MovieLogDto dto = new MovieLogDto();
        dto.setId(log.getId());
        dto.setTmdbId(log.getTmdbId());
        dto.setTitle(log.getTitle());
        dto.setYear(log.getYear());
        dto.setPosterPath(log.getPosterPath());
        dto.setDirector(log.getDirector());
        dto.setSynopsis(log.getSynopsis());
        dto.setRating(log.getRating());
        dto.setWatchedAt(log.getWatchedAt());
        dto.setComment(log.getComment());
        dto.setCreatedAt(log.getCreatedAt());
        return dto;
    }
}
