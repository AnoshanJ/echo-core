import { execSync } from "node:child_process";
import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";
import dts from "vite-plugin-dts";

// Baked in at lib build time so a consumer reports the core it actually got,
// rather than a version string it could have written itself.
const commit =
  process.env.CORE_COMMIT ??
  (() => {
    try {
      return execSync("git rev-parse HEAD").toString().trim();
    } catch {
      return "unknown";
    }
  })();

export default defineConfig({
  plugins: [react(), dts({ include: ["src"], rollupTypes: true })],
  define: {
    __CORE_VERSION__: JSON.stringify(process.env.npm_package_version ?? "0.0.0"),
    __CORE_COMMIT__: JSON.stringify(commit),
  },
  build: {
    lib: { entry: "src/index.ts", formats: ["es"], fileName: "index" },
    rollupOptions: {
      external: [
        "react",
        "react/jsx-runtime",
        "react-dom",
        "react-router-dom",
      ],
    },
  },
});
