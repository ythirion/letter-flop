export interface MovieSearchResult {
  id: number;
  title: string;
  year: number | null;
  posterPath: string | null;
  director: string | null;
}

export interface MovieDetail {
  id: number;
  title: string;
  year: number | null;
  posterPath: string | null;
  director: string | null;
  synopsis: string | null;
  runtime: number | null;
  genres: string[];
}

export interface MovieLog {
  id: number;
  tmdbId: number;
  title: string;
  year: number | null;
  posterPath: string | null;
  director: string | null;
  synopsis: string | null;
  rating: number;
  watchedAt: string;
  comment: string | null;
  createdAt: string;
}

export interface LogsPage {
  content: MovieLog[];
  totalElements: number;
  totalPages: number;
  currentPage: number;
}

export interface CreateLogPayload {
  tmdbId: number;
  title: string;
  year: number | null;
  posterPath: string | null;
  director: string | null;
  synopsis: string | null;
  rating: number;
  watchedAt: string;
  comment: string;
}

export interface UpdateLogPayload {
  rating: number;
  watchedAt: string;
  comment: string;
}
