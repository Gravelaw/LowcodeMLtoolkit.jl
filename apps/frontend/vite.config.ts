import react from "@vitejs/plugin-react";
import { defineConfig } from "vitest/config";

export default defineConfig({
  plugins: [react()],
  test: {
    environment: "jsdom",
    globals: true,
    setupFiles: "./src/test-setup.ts",
    coverage: {
      provider: "v8",
      reporter: ["text", "json-summary"],
      reportsDirectory: "../../coverage/frontend",
      include: ["src/App.tsx", "src/sample-workflow.ts"],
      thresholds: {
        statements: 78,
        branches: 70,
        functions: 60,
        lines: 78
      }
    }
  }
});
