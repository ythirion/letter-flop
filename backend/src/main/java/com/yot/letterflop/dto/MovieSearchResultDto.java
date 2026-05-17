package com.yot.letterflop.dto;

import lombok.Data;

@Data
public class MovieSearchResultDto {
    private Integer id;
    private String title;
    private Integer year;
    private String posterPath;
    private String director;
}
