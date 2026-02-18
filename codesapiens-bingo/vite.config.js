import { defineConfig } from 'vite'
import { resolve } from 'path'

export default defineConfig({
    build: {
        rollupOptions: {
            input: {
                main: resolve(__dirname, 'index.html'),
                onboarding: resolve(__dirname, 'onboarding.html'),
                bingo: resolve(__dirname, 'bingo.html'),
                network: resolve(__dirname, 'network.html'),
            }
        }
    },
    server: {
        port: 5173,
        open: true
    }
})
