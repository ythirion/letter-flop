package com.yot.letterflop.dto;

import lombok.Data;
import java.util.List;

@Data
public class MovieDetailDto {
    private Integer id;
    private String title;
    private Integer year;
    private String posterPath;
    private String director;
    private String synopsis;
    private Integer runtime;
    private List<String> genres;
}
