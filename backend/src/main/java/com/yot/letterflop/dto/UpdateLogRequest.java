package com.yot.letterflop.dto;

import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDate;

@Data
public class UpdateLogRequest {
    private BigDecimal rating;
    private LocalDate watchedAt;
    private String comment;
}
