import { resolve } from 'node:path';
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    environment: 'node',
    globals: true,
    setupFiles: ['./tests/setup.ts'],
  },
  resolve: {
    alias: {
      '@': resolve(import.meta.dirname, './apps/web/src'),
      '@starter/backend': resolve(
        import.meta.dirname,
        './packages/backend/src'
      ),
    },
  },
});
