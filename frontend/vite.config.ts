import { defineConfig } from "npm:vite@5.0.0";
import react from "npm:@vitejs/plugin-react@4.2.0";

export default defineConfig({
    plugins: [react()],
    server: {
        port: 5173,
        host: "localhost",
    },
    build: {
        outDir: "dist",
        sourcemap: true,
    },
});
