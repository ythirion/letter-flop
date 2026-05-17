package com.yot.letterflop.dto;

import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDate;

@Data
public class CreateLogRequest {
    private Integer tmdbId;
    private String title;
    private Integer year;
    private String posterPath;
    private String director;
    private String synopsis;
    private BigDecimal rating;
    private LocalDate watchedAt;
    private String comment;
}
