package com.yot.letterflop.dto;

import lombok.Data;
import java.util.List;

@Data
public class MovieSearchResultDto {
    private Integer id;
    private String title;
    private Integer year;
    private String posterPath;
    private String director;
    private String synopsis;
    private Integer runtime;
    private List<String> genres;
    private Double voteAverage;
    private String originalTitle;
    private String originalLanguage;
    private Double popularity;
}
