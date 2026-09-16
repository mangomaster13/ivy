import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

/**
 * Vite configuration for the Ivy gift site.
 */
export default defineConfig({
  plugins: [react()],
  server: {
    port: 5200,
  },
});
