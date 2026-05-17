package com.yot.letterflop.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "movie_logs")
@Data
@NoArgsConstructor
public class MovieLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Integer tmdbId;
    private String title;
    private Integer year;
    private String posterPath;
    private String director;

    @Column(columnDefinition = "TEXT")
    private String synopsis;

    @Column(precision = 3, scale = 1)
    private BigDecimal rating;

    private LocalDate watchedAt;

    @Column(length = 500)
    private String comment;

    private LocalDateTime createdAt;

    @PrePersist
    void onCreate() {
        this.createdAt = LocalDateTime.now();
    }
}
