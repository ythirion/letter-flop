package com.yot.letterflop.dto;

import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
public class MovieLogDto {
    private Long id;
    private Integer tmdbId;
    private String title;
    private Integer year;
    private String posterPath;
    private String director;
    private String synopsis;
    private BigDecimal rating;
    private LocalDate watchedAt;
    private String comment;
    private LocalDateTime createdAt;
}
