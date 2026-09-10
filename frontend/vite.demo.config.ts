import { resolve } from "node:path";
import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";

// The demo consumes dist, not src, so it proves the published artifact works.
export default defineConfig({
  root: "demo",
  plugins: [react()],
  resolve: {
    alias: {
      "@anoshanj/echo-core-ui": resolve(import.meta.dirname, "dist/index.js"),
    },
  },
  build: { outDir: "../demo-dist", emptyOutDir: true },
});
