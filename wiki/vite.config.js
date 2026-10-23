import { resolve } from 'node:path'
import { defineConfig } from 'vite'

export default defineConfig({
  root: resolve(__dirname),
  publicDir: 'public',
  server: {
    fs: { allow: [resolve(__dirname, '..')] },
  },
  build: {
    outDir: 'dist',
    emptyOutDir: true,
    rollupOptions: {
      input: {
        main: resolve(__dirname, 'index.html'),
        story: resolve(__dirname, 'story/index.html'),
        assets: resolve(__dirname, 'assets/index.html'),
        sharedSubject: resolve(__dirname, 'assets/shared-subject.html'),
        materialDispenser: resolve(__dirname, 'assets/material-dispenser.html'),
      },
    },
  },
})
