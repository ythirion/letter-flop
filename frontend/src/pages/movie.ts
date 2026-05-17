import { getMovieDetail, getMovieLogs, createLog, updateLog, deleteLog } from '../api/api';
import { MovieDetail, MovieLog } from '../types';

const params   = new URLSearchParams(window.location.search);
const tmdbId   = parseInt(params.get('id') ?? '0');
const loadingEl  = document.getElementById('loading') as HTMLParagraphElement;
const errorEl    = document.getElementById('error') as HTMLParagraphElement;
const contentEl  = document.getElementById('movie-content') as HTMLDivElement;
const posterCol  = document.getElementById('poster-col') as HTMLDivElement;
const infoCol    = document.getElementById('info-col') as HTMLDivElement;
const formContainer = document.getElementById('log-form-container') as HTMLDivElement;
const logsTitle  = document.getElementById('logs-title') as HTMLHeadingElement;
const logsList   = document.getElementById('logs-list') as HTMLDivElement;

let currentMovie: MovieDetail;
let currentLogs: MovieLog[] = [];

Promise.all([getMovieDetail(tmdbId), getMovieLogs(tmdbId)])
  .then(([movie, logs]) => {
    currentMovie = movie;
    currentLogs  = logs;
    loadingEl.classList.add('hidden');
    renderMovie(movie);
    renderLogs();
    contentEl.classList.remove('hidden');
  })
  .catch(() => {
    loadingEl.classList.add('hidden');
    errorEl.classList.remove('hidden');
  });

function renderMovie(movie: MovieDetail): void {
  posterCol.innerHTML = movie.posterPath
    ? `<img src="${movie.posterPath}" alt="" class="rounded-lg object-cover" style="width:220px;min-width:220px">`
    : `<div class="bg-neutral-800 rounded-lg flex items-center justify-center text-neutral-600 text-sm" style="width:220px;min-width:220px;aspect-ratio:2/3">Pas d'affiche</div>`;

  const genres = movie.genres.map(g =>
    `<span class="bg-neutral-800 text-neutral-300 text-xs px-2.5 py-1 rounded">${g}</span>`
  ).join('');

  infoCol.innerHTML = `
    <h1 class="text-3xl font-bold mb-3">${movie.title}</h1>
    <div class="flex gap-4 text-neutral-400 text-sm mb-3">
      ${movie.year     ? `<span>${movie.year}</span>` : ''}
      ${movie.runtime  ? `<span>${movie.runtime} min</span>` : ''}
      ${movie.director ? `<span>Réal. ${movie.director}</span>` : ''}
    </div>
    ${genres ? `<div class="flex gap-2 flex-wrap mb-4">${genres}</div>` : ''}
    ${movie.synopsis   ? `<p class="text-neutral-300 leading-relaxed mb-6">${movie.synopsis}</p>` : ''}
    <button id="log-btn" class="bg-red-600 text-white px-6 py-3 rounded-lg border-none cursor-pointer font-medium text-base">
      + Logger ce film
    </button>
  `;

  document.getElementById('log-btn')!.addEventListener('click', () => showLogForm(null));
}

function renderLogs(): void {
  const count = currentLogs.length;
  logsTitle.textContent = count === 0
    ? 'Pas encore loggé'
    : `${count} visionnage${count > 1 ? 's' : ''}`;

  logsList.innerHTML = currentLogs.map(log => buildLogCard(log)).join('');

  logsList.querySelectorAll<HTMLButtonElement>('[data-edit]').forEach(btn => {
    const log = currentLogs.find(l => l.id === parseInt(btn.dataset['edit']!))!;
    btn.addEventListener('click', () => showLogForm(log));
  });

  logsList.querySelectorAll<HTMLButtonElement>('[data-delete]').forEach(btn => {
    const id = parseInt(btn.dataset['delete']!);
    btn.addEventListener('click', () => handleDelete(id));
  });
}

function buildLogCard(log: MovieLog): string {
  const date = new Date(log.watchedAt + 'T00:00:00').toLocaleDateString('fr-FR', {
    day: 'numeric', month: 'long', year: 'numeric',
  });
  const stars = buildStarsHtml(log.rating);

  return `
    <div class="bg-neutral-900 rounded-lg p-4 mb-3 border border-neutral-800">
      <div class="flex items-center gap-4 mb-2">
        <div class="flex">${stars}</div>
        <span class="text-sm text-neutral-500">vu le ${date}</span>
      </div>
      ${log.comment ? `<p class="text-neutral-400 italic text-sm mb-3">"${log.comment}"</p>` : ''}
      <div class="flex gap-2">
        <button data-edit="${log.id}" class="px-3.5 py-1.5 border border-neutral-600 text-neutral-300 rounded text-xs cursor-pointer bg-transparent">Modifier</button>
        <button data-delete="${log.id}" class="px-3.5 py-1.5 border border-red-900 text-red-400 rounded text-xs cursor-pointer bg-transparent">Supprimer</button>
      </div>
    </div>
  `;
}

function buildStarsHtml(rating: number): string {
  return Array.from({ length: 5 }, (_, i) => {
    const filled = rating >= i + 1;
    const half   = !filled && rating >= i + 0.5;
    return `<span style="color:${filled || half ? '#f5c518' : '#404040'};font-size:20px">${half ? '⭑' : '★'}</span>`;
  }).join('');
}

let ratingValue: number | null = null;

function showLogForm(existingLog: MovieLog | null): void {
  ratingValue = existingLog?.rating ?? null;

  formContainer.innerHTML = `
    <div class="bg-neutral-900 rounded-lg p-6 mb-6 border border-neutral-800">
      <h3 class="text-lg font-semibold mb-5">${existingLog ? 'Modifier le log' : 'Logger ce film'}</h3>
      <p id="form-success" class="text-green-500 font-semibold hidden">✓ Enregistré !</p>
      <form id="log-form" class="flex flex-col gap-4">

        <div class="flex flex-col gap-2">
          <label class="text-sm text-neutral-300 font-medium">Note *</label>
          <!-- Mauvaise pratique : notation uniquement à la souris, pas de clavier -->
          <div id="star-input" class="flex items-center gap-0.5"></div>
        </div>

        <div class="flex flex-col gap-2">
          <label class="text-sm text-neutral-300 font-medium">Date de visionnage</label>
          <input
            id="watched-at"
            type="date"
            value="${existingLog?.watchedAt ?? new Date().toISOString().split('T')[0]}"
            max="${new Date().toISOString().split('T')[0]}"
            class="w-48 bg-neutral-950 border border-neutral-700 text-white rounded-md px-3 py-2 text-sm focus:outline-none"
          />
        </div>

        <div class="flex flex-col gap-2">
          <label class="text-sm text-neutral-300 font-medium">Commentaire (optionnel)</label>
          <textarea
            id="comment"
            rows="3"
            maxlength="500"
            placeholder="Tes impressions..."
            class="bg-neutral-950 border border-neutral-700 text-white rounded-md px-3 py-2 text-sm focus:outline-none resize-y"
            style="font-family:inherit"
          >${existingLog?.comment ?? ''}</textarea>
          <span id="char-count" class="text-xs text-neutral-600 self-end">0/500</span>
        </div>

        <p id="form-error" class="text-red-500 text-sm hidden"></p>

        <div class="flex gap-3 justify-end">
          <button type="button" id="cancel-btn" class="px-5 py-2.5 border border-neutral-600 text-neutral-300 rounded-lg cursor-pointer text-sm bg-transparent">Annuler</button>
          <button type="submit" id="submit-btn" class="px-5 py-2.5 bg-red-600 text-white rounded-lg border-none cursor-pointer text-sm font-semibold">
            ${existingLog ? 'Modifier' : 'Enregistrer'}
          </button>
        </div>
      </form>
    </div>
  `;

  attachStarInput(
    document.getElementById('star-input') as HTMLDivElement,
    existingLog?.rating ?? null,
    (r) => { ratingValue = r; },
  );

  const commentEl   = document.getElementById('comment') as HTMLTextAreaElement;
  const charCountEl = document.getElementById('char-count') as HTMLSpanElement;
  charCountEl.textContent = `${commentEl.value.length}/500`;
  commentEl.addEventListener('input', () => {
    charCountEl.textContent = `${commentEl.value.length}/500`;
  });

  document.getElementById('cancel-btn')!.addEventListener('click', () => {
    formContainer.innerHTML = '';
  });

  const logForm = document.getElementById('log-form') as HTMLFormElement;
  logForm.addEventListener('submit', async (e: Event) => {
    e.preventDefault();
    const formError  = document.getElementById('form-error') as HTMLParagraphElement;
    const submitBtn  = document.getElementById('submit-btn') as HTMLButtonElement;
    const successMsg = document.getElementById('form-success') as HTMLParagraphElement;

    if (ratingValue === null) {
      formError.textContent = 'La note est obligatoire';
      formError.classList.remove('hidden');
      return;
    }

    const watchedAt = (document.getElementById('watched-at') as HTMLInputElement).value;
    const comment   = commentEl.value;

    submitBtn.disabled = true;
    formError.classList.add('hidden');

    try {
      let saved: MovieLog;
      if (existingLog) {
        saved = await updateLog(existingLog.id, { rating: ratingValue, watchedAt, comment });
        currentLogs = currentLogs.map(l => l.id === saved.id ? saved : l);
      } else {
        saved = await createLog({
          tmdbId:     currentMovie.id,
          title:      currentMovie.title,
          year:       currentMovie.year,
          posterPath: currentMovie.posterPath,
          director:   currentMovie.director,
          synopsis:   currentMovie.synopsis,
          rating:     ratingValue,
          watchedAt,
          comment,
        });
        currentLogs = [saved, ...currentLogs];
      }

      successMsg.classList.remove('hidden');
      setTimeout(() => {
        formContainer.innerHTML = '';
        renderLogs();
      }, 800);
    } catch {
      formError.textContent = 'Une erreur est survenue.';
      formError.classList.remove('hidden');
      submitBtn.disabled = false;
    }
  });
}

function attachStarInput(
  container: HTMLDivElement,
  initial: number | null,
  onRate: (r: number) => void,
): void {
  let value = initial;
  const spans: HTMLSpanElement[] = [];

  const update = (hovered: number | null): void => {
    const display = hovered ?? value ?? 0;
    spans.forEach((s, i) => {
      s.style.color = display >= i + 1 ? '#f5c518' : '#404040';
    });
  };

  for (let i = 1; i <= 5; i++) {
    const span = document.createElement('span');
    span.textContent = '★';
    span.className = 'text-2xl cursor-pointer transition-colors select-none';
    span.style.color = (value ?? 0) >= i ? '#f5c518' : '#404040';

    // Mauvaise pratique : événements souris uniquement, pas de clavier
    span.addEventListener('mouseenter', () => update(i));
    span.addEventListener('mouseleave', () => update(null));
    span.addEventListener('click', () => {
      value = i;
      onRate(i);
      update(null);
      const lbl = container.querySelector<HTMLSpanElement>('.rating-label');
      if (lbl) lbl.textContent = `${value}/5`;
      else {
        const label = document.createElement('span');
        label.className = 'rating-label text-sm text-neutral-500 ml-2';
        label.textContent = `${value}/5`;
        container.appendChild(label);
      }
    });

    spans.push(span);
    container.appendChild(span);
  }

  if (value !== null) {
    const label = document.createElement('span');
    label.className = 'rating-label text-sm text-neutral-500 ml-2';
    label.textContent = `${value}/5`;
    container.appendChild(label);
  }
}

async function handleDelete(logId: number): Promise<void> {
  if (!window.confirm('Supprimer ce log ?')) return;
  await deleteLog(logId);
  currentLogs = currentLogs.filter(l => l.id !== logId);
  renderLogs();
}
