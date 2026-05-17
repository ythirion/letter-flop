package com.yot.letterflop.service;

import com.yot.letterflop.dto.MovieDetailDto;
import com.yot.letterflop.dto.MovieSearchResultDto;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Service
public class TmdbService {

    private final RestTemplate restTemplate;

    @Value("${tmdb.api.key}")
    private String apiKey;

    @Value("${tmdb.api.base-url}")
    private String baseUrl;

    public TmdbService(RestTemplate restTemplate) {
        this.restTemplate = restTemplate;
    }

    @SuppressWarnings("unchecked")
    public List<MovieSearchResultDto> searchMovies(String query) {
        String url = baseUrl + "/search/movie?api_key=" + apiKey + "&query=" + query + "&language=fr-FR";

        Map<String, Object> response = restTemplate.getForObject(url, Map.class);
        List<Map<String, Object>> results = (List<Map<String, Object>>) response.get("results");
        List<MovieSearchResultDto> movies = new ArrayList<>();

        if (results == null) {
            return movies;
        }

        for (Map<String, Object> result : results) {
            MovieSearchResultDto dto = new MovieSearchResultDto();
            dto.setId((Integer) result.get("id"));
            dto.setTitle((String) result.get("title"));

            String releaseDate = (String) result.get("release_date");
            if (releaseDate != null && !releaseDate.isEmpty()) {
                dto.setYear(Integer.parseInt(releaseDate.substring(0, 4)));
            }

            String posterPath = (String) result.get("poster_path");
            if (posterPath != null) {
                dto.setPosterPath("https://image.tmdb.org/t/p/original" + posterPath);
            }

            dto.setDirector(fetchDirector(dto.getId()));
            movies.add(dto);
        }

        return movies;
    }

    @SuppressWarnings("unchecked")
    public MovieDetailDto getMovieDetail(Integer tmdbId) {
        String url = baseUrl + "/movie/" + tmdbId + "?api_key=" + apiKey + "&language=fr-FR&append_to_response=credits";

        Map<String, Object> response = restTemplate.getForObject(url, Map.class);

        MovieDetailDto dto = new MovieDetailDto();
        dto.setId((Integer) response.get("id"));
        dto.setTitle((String) response.get("title"));

        String releaseDate = (String) response.get("release_date");
        if (releaseDate != null && !releaseDate.isEmpty()) {
            dto.setYear(Integer.parseInt(releaseDate.substring(0, 4)));
        }

        String posterPath = (String) response.get("poster_path");
        if (posterPath != null) {
            dto.setPosterPath("https://image.tmdb.org/t/p/original" + posterPath);
        }

        dto.setSynopsis((String) response.get("overview"));
        dto.setRuntime((Integer) response.get("runtime"));

        List<Map<String, Object>> genres = (List<Map<String, Object>>) response.get("genres");
        if (genres != null) {
            List<String> genreNames = new ArrayList<>();
            genres.forEach(genre -> {
                String name = (String) genre.get("name");
                genreNames.add(name);
            });
            dto.setGenres(genreNames);
        }

        Map<String, Object> credits = (Map<String, Object>) response.get("credits");
        if (credits != null) {
            List<Map<String, Object>> crew = (List<Map<String, Object>>) credits.get("crew");
            if (crew != null) {
                List<String> directors = new ArrayList<>();
                crew.forEach(member -> {
                    if ("Director".equals(member.get("job"))) {
                        directors.add((String) member.get("name"));
                    }
                });
                if (!directors.isEmpty()) {
                    dto.setDirector(directors.get(0));
                }
            }
        }

        return dto;
    }

    @SuppressWarnings("unchecked")
    private String fetchDirector(Integer tmdbId) {
        try {
            String url = baseUrl + "/movie/" + tmdbId + "/credits?api_key=" + apiKey;
            Map<String, Object> response = restTemplate.getForObject(url, Map.class);
            List<Map<String, Object>> crew = (List<Map<String, Object>>) response.get("crew");

            if (crew == null) return null;

            for (Map<String, Object> member : crew) {
                if ("Director".equals(member.get("job"))) {
                    return (String) member.get("name");
                }
            }
        } catch (Exception e) {
            // ignored
        }
        return null;
    }
}
