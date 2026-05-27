package com.yot.letterflop.repository;

import com.yot.letterflop.entity.MovieLog;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MovieLogRepository extends JpaRepository<MovieLog, Long> {
    Page<MovieLog> findAllByOrderByWatchedAtDescCreatedAtDesc(Pageable pageable);
    List<MovieLog> findByTmdbId(Integer tmdbId);

    @Query("SELECT m FROM MovieLog m WHERE LOWER(m.title) LIKE LOWER(CONCAT('%', :title, '%'))")
    List<MovieLog> findByTitleContaining(String title);
}
