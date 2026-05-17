package com.yot.letterflop.repository;

import com.yot.letterflop.entity.MovieLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MovieLogRepository extends JpaRepository<MovieLog, Long> {

    @Query("SELECT m FROM MovieLog m ORDER BY m.watchedAt DESC, m.createdAt DESC")
    List<MovieLog> findAllOrderByWatchedAtDesc();

    List<MovieLog> findByTmdbId(Integer tmdbId);

    @Query("SELECT m FROM MovieLog m WHERE LOWER(m.title) LIKE LOWER(CONCAT('%', :title, '%'))")
    List<MovieLog> findByTitleContaining(String title);
}
