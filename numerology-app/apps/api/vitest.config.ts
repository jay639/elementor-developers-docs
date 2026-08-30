import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: false,
    environment: 'node',
    // Integration tests share one Postgres database, so they run in sequence.
    fileParallelism: false,
    hookTimeout: 60_000,
    testTimeout: 30_000,
    globalSetup: ['./src/__tests__/globalSetup.ts'],
    setupFiles: ['./src/__tests__/setupEnv.ts'],
    include: ['src/**/*.test.ts'],
  },
});
