import { getLogs, deleteLog } from '../api/api';
import { MovieLog } from '../types';

const loadingEl  = document.getElementById('loading') as HTMLParagraphElement;
const contentEl  = document.getElementById('history-content') as HTMLDivElement;
const emptyEl    = document.getElementById('empty-state') as HTMLDivElement;
const totalEl    = document.getElementById('total-count') as HTMLParagraphElement;
const listEl     = document.getElementById('logs-list') as HTMLDivElement;
const pagination = document.getElementById('pagination') as HTMLDivElement;
const prevBtn    = document.getElementById('prev-btn') as HTMLButtonElement;
const nextBtn    = document.getElementById('next-btn') as HTMLButtonElement;
const pageInfo   = document.getElementById('page-info') as HTMLSpanElement;

const PAGE_SIZE = 6;
let currentPage = 0;
let totalLogs = 0;

async function loadPage(page: number): Promise<void> {
  // Mauvaise pratique : appel API à chaque changement de page,
  // on charge 1000 logs depuis le serveur pour n'en afficher que 6.
  const data = await getLogs(0, 1000);
  const allLogs = data.content;

  totalLogs = allLogs.length;

  if (totalLogs === 0) {
    loadingEl.classList.add('hidden');
    emptyEl.classList.remove('hidden');
    return;
  }

  // Mauvaise pratique : filtrage/découpage côté client après avoir tout téléchargé
  const slice = allLogs.slice(page * PAGE_SIZE, (page + 1) * PAGE_SIZE);
  const totalPages = Math.ceil(totalLogs / PAGE_SIZE);

  updateTotal();
  renderSlice(slice);

  if (totalPages > 1) {
    pagination.classList.remove('hidden');
    pageInfo.textContent = `Page ${page + 1} / ${totalPages}`;
    prevBtn.disabled = page === 0;
    nextBtn.disabled = page === totalPages - 1;
  } else {
    pagination.classList.add('hidden');
  }

  loadingEl.classList.add('hidden');
  contentEl.classList.remove('hidden');
}

loadPage(currentPage).catch(() => {
  loadingEl.textContent = 'Erreur lors du chargement.';
});

prevBtn.addEventListener('click', () => { currentPage--; loadPage(currentPage); });
nextBtn.addEventListener('click', () => { currentPage++; loadPage(currentPage); });

function renderSlice(logs: MovieLog[]): void {
  listEl.innerHTML = logs.map(log => {
    const date = new Date(log.watchedAt + 'T00:00:00').toLocaleDateString('fr-FR', {
      day: 'numeric', month: 'long', year: 'numeric',
    });
    const stars = Array.from({ length: 5 }, (_, i) => {
      const filled = log.rating >= i + 1;
      const half   = !filled && log.rating >= i + 0.5;
      return `<span style="color:${filled || half ? '#f5c518' : '#404040'};font-size:18px">${half ? '⭑' : '★'}</span>`;
    }).join('');

    return `
      <div class="flex gap-4 bg-neutral-900 rounded-lg p-4 items-start border border-neutral-800">
        ${log.posterPath
          ? `<img src="${log.posterPath}" alt="" class="rounded object-cover shrink-0" style="width:60px;aspect-ratio:2/3">`
          : ''
        }
        <div class="flex-1 min-w-0">
          <a href="/movie.html?id=${log.tmdbId}" class="text-white font-semibold no-underline hover:text-red-500">
            ${log.title}
          </a>
          ${log.year ? `<span class="text-neutral-500 text-sm ml-1">(${log.year})</span>` : ''}
          <div class="flex items-center gap-3 mt-1 mb-2">
            <div class="flex">${stars}</div>
            <span class="text-sm text-neutral-500">${date}</span>
          </div>
          ${log.comment ? `<p class="text-neutral-400 italic text-sm mb-2">"${log.comment}"</p>` : ''}
          <button data-delete="${log.id}" class="px-3.5 py-1.5 border border-red-900 text-red-400 rounded text-xs cursor-pointer bg-transparent">
            Supprimer
          </button>
        </div>
      </div>
    `;
  }).join('');

  listEl.querySelectorAll<HTMLButtonElement>('[data-delete]').forEach(btn => {
    const id = parseInt(btn.dataset['delete']!);
    btn.addEventListener('click', () => handleDelete(id));
  });
}

function updateTotal(): void {
  const n = totalLogs;
  totalEl.textContent = `${n} film${n > 1 ? 's' : ''} loggé${n > 1 ? 's' : ''}`;
}

async function handleDelete(logId: number): Promise<void> {
  if (!window.confirm('Supprimer ce log ?')) return;
  await deleteLog(logId);
  totalLogs--;
  const totalPages = Math.ceil(totalLogs / PAGE_SIZE);
  if (currentPage >= totalPages) currentPage = Math.max(0, totalPages - 1);
  if (totalLogs === 0) {
    contentEl.classList.add('hidden');
    emptyEl.classList.remove('hidden');
  } else {
    loadPage(currentPage);
  }
}
