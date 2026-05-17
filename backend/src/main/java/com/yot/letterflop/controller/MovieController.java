package com.yot.letterflop.controller;

import com.yot.letterflop.dto.MovieDetailDto;
import com.yot.letterflop.dto.MovieSearchResultDto;
import com.yot.letterflop.service.TmdbService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/movies")
@CrossOrigin(origins = "*")
@Tag(name = "Films", description = "Recherche et fiche détail via l'API TMDB")
public class MovieController {

    private final TmdbService tmdbService;

    public MovieController(TmdbService tmdbService) {
        this.tmdbService = tmdbService;
    }

    @GetMapping("/search")
    @Operation(
        summary = "Rechercher des films",
        description = "Interroge l'API TMDB. Déclenche N+1 appels HTTP (1 search + 1 /credits par résultat)."
    )
    public ResponseEntity<List<MovieSearchResultDto>> search(
            @Parameter(description = "Titre ou mot-clé à rechercher", required = true, example = "Inception")
            @RequestParam String query) {
        return ResponseEntity.ok(tmdbService.searchMovies(query));
    }

    @GetMapping("/{tmdbId}")
    @Operation(
        summary = "Détail d'un film",
        description = "Retourne les informations complètes d'un film TMDB. Aucun cache — chaque appel recontacte TMDB."
    )
    public ResponseEntity<MovieDetailDto> getDetail(
            @Parameter(description = "Identifiant TMDB du film", required = true, example = "27205")
            @PathVariable Integer tmdbId) {
        return ResponseEntity.ok(tmdbService.getMovieDetail(tmdbId));
    }
}
