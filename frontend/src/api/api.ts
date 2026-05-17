import {
  CreateLogPayload,
  LogsPage,
  MovieDetail,
  MovieLog,
  MovieSearchResult,
  UpdateLogPayload,
} from '../types';

const API_URL = 'http://localhost:8080';

export async function searchMovies(query: string): Promise<MovieSearchResult[]> {
  const res = await fetch(`${API_URL}/api/movies/search?query=${encodeURIComponent(query)}`);
  if (!res.ok) throw new Error('Erreur de recherche');
  return res.json();
}

export async function getMovieDetail(tmdbId: number): Promise<MovieDetail> {
  const res = await fetch(`${API_URL}/api/movies/${tmdbId}`);
  if (!res.ok) throw new Error('Film introuvable');
  return res.json();
}

export async function getMovieLogs(tmdbId: number): Promise<MovieLog[]> {
  const res = await fetch(`${API_URL}/api/logs/movie/${tmdbId}`);
  if (!res.ok) throw new Error('Erreur');
  return res.json();
}

export async function getLogs(page = 0, size = 20): Promise<LogsPage> {
  const res = await fetch(`${API_URL}/api/logs?page=${page}&size=${size}`);
  if (!res.ok) throw new Error('Erreur');
  return res.json();
}

export async function createLog(data: CreateLogPayload): Promise<MovieLog> {
  const res = await fetch(`${API_URL}/api/logs`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  });
  if (!res.ok) throw new Error('Erreur lors de la création');
  return res.json();
}

export async function updateLog(id: number, data: UpdateLogPayload): Promise<MovieLog> {
  const res = await fetch(`${API_URL}/api/logs/${id}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  });
  if (!res.ok) throw new Error('Erreur lors de la modification');
  return res.json();
}

export async function deleteLog(id: number): Promise<void> {
  const res = await fetch(`${API_URL}/api/logs/${id}`, { method: 'DELETE' });
  if (!res.ok) throw new Error('Erreur lors de la suppression');
}
