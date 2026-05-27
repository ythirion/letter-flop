package com.yot.letterflop.controller;

import com.yot.letterflop.dto.CreateLogRequest;
import com.yot.letterflop.dto.MovieLogDto;
import com.yot.letterflop.dto.UpdateLogRequest;
import com.yot.letterflop.service.MovieLogService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/logs")
@CrossOrigin(origins = "*")
@Tag(name = "Logs de visionnage", description = "CRUD des visionnages enregistrés par l'utilisateur")
public class LogController {

    private final MovieLogService logService;

    public LogController(MovieLogService logService) {
        this.logService = logService;
    }

    @GetMapping
    @Operation(
        summary = "Lister les logs paginés",
        description = "Charge TOUS les logs en mémoire puis découpe la page en Java — double full table scan (violation CODE-1 + DB-3)."
    )
    public ResponseEntity<Map<String, Object>> getLogs(
            @Parameter(description = "Numéro de page (0-indexé)", example = "0") @RequestParam(defaultValue = "0") int page,
            @Parameter(description = "Taille de page", example = "20") @RequestParam(defaultValue = "20") int size) {

        Page<MovieLogDto> result = logService.getAllLogs(page, size);

        Map<String, Object> response = new HashMap<>();
        response.put("content", result.getContent());
        response.put("totalElements", result.getTotalElements());
        response.put("totalPages", result.getTotalPages());
        response.put("currentPage", result.getNumber());

        return ResponseEntity.ok(response);
    }

    @GetMapping("/movie/{tmdbId}")
    @Operation(summary = "Logs pour un film", description = "Retourne tous les visionnages d'un film identifié par son ID TMDB.")
    public ResponseEntity<List<MovieLogDto>> getLogsByMovie(
            @Parameter(description = "Identifiant TMDB du film", required = true, example = "27205")
            @PathVariable Integer tmdbId) {
        return ResponseEntity.ok(logService.getLogsByTmdbId(tmdbId));
    }

    @PostMapping
    @Operation(summary = "Créer un log", description = "Enregistre un nouveau visionnage.")
    public ResponseEntity<MovieLogDto> createLog(@RequestBody CreateLogRequest request) {
        return ResponseEntity.ok(logService.createLog(request));
    }

    @PutMapping("/{id}")
    @Operation(summary = "Modifier un log", description = "Met à jour la note, la date et le commentaire d'un visionnage.")
    public ResponseEntity<MovieLogDto> updateLog(
            @Parameter(description = "ID interne du log", required = true) @PathVariable Long id,
            @RequestBody UpdateLogRequest request) {
        return ResponseEntity.ok(logService.updateLog(id, request));
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Supprimer un log", description = "Supprime définitivement un visionnage.")
    public ResponseEntity<Void> deleteLog(
            @Parameter(description = "ID interne du log", required = true) @PathVariable Long id) {
        logService.deleteLog(id);
        return ResponseEntity.noContent().build();
    }
}
