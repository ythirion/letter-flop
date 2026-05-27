import { searchMovies } from '../api/api';
import { MovieSearchResult } from '../types';

const form    = document.getElementById('search-form') as HTMLFormElement;
const input   = document.getElementById('search-input') as HTMLInputElement;
const btn     = document.getElementById('search-btn') as HTMLButtonElement;
const grid    = document.getElementById('results-grid') as HTMLDivElement;
const errorEl = document.getElementById('error-msg') as HTMLParagraphElement;
const emptyEl = document.getElementById('empty-msg') as HTMLParagraphElement;

form.addEventListener('submit', async (e: Event) => {
  e.preventDefault();
  const query = input.value.trim();
  if (!query) return;

  btn.textContent = 'Recherche...';
  btn.disabled = true;
  errorEl.classList.add('hidden');
  emptyEl.classList.add('hidden');
  grid.innerHTML = '';

  try {
    const movies = await searchMovies(query);
    renderResults(movies, query);
  } catch {
    errorEl.textContent = 'Une erreur est survenue lors de la recherche.';
    errorEl.classList.remove('hidden');
  } finally {
    btn.textContent = 'Rechercher';
    btn.disabled = false;
  }
});

function renderResults(movies: MovieSearchResult[], query: string): void {
  if (movies.length === 0) {
    emptyEl.textContent = `Aucun résultat pour "${query}"`;
    emptyEl.classList.remove('hidden');
    return;
  }

  // Mauvaise pratique : innerHTML reconstruit tout le DOM à chaque recherche
  // Mauvaise pratique : pas de loading="lazy" sur les images → tout charge en même temps
  // Mauvaise pratique : taille "original" de TMDB pour des vignettes de 200px
  grid.innerHTML = movies.map(movie => `
    <div
      class="bg-neutral-900 rounded-lg overflow-hidden cursor-pointer hover:ring-2 hover:ring-red-600 transition-all"
      data-id="${movie.id}"
    >
      ${movie.posterPath
        ? `<img src="${movie.posterPath}" alt="" loading="lazy" class="w-full object-cover" style="aspect-ratio:2/3">`
        : `<div class="bg-neutral-800 flex items-center justify-center text-neutral-600 text-sm" style="aspect-ratio:2/3">Pas d'affiche</div>`
      }
      <div class="p-3">
        <h3 class="text-sm font-semibold mb-1">${movie.title}</h3>
        ${movie.year     ? `<p class="text-xs text-neutral-500 mb-1">${movie.year}</p>` : ''}
        ${movie.director ? `<p class="text-xs text-neutral-600">Réal. ${movie.director}</p>` : ''}
      </div>
    </div>
  `).join('');

  // Mauvaise pratique : onClick sur div sans tabIndex ni onKeyDown → inaccessible au clavier
  grid.querySelectorAll<HTMLDivElement>('[data-id]').forEach(card => {
    card.addEventListener('click', () => {
      window.location.href = `/movie.html?id=${card.dataset['id']}`;
    });
  });
}
