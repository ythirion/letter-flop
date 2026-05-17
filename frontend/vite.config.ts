import { defineConfig } from 'vite';

export default defineConfig({
  server: { port: 3000, host: true },
  build: {
    rollupOptions: {
      input: {
        main:    './index.html',
        movie:   './movie.html',
        history: './history.html',
      },
    },
  },
});
