import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: "./tests/browser",
  testMatch: /live-backend\.spec\.ts/,
  timeout: 240_000,
  expect: { timeout: 60_000 },
  fullyParallel: false,
  reporter: [["list"], ["html", { outputFolder: "artifacts/release-verification/live-backend-browser/playwright-report", open: "never" }]],
  use: {
    baseURL: process.env.JULIAFLOW_LIVE_FRONTEND_URL ?? "http://127.0.0.1:14178",
    trace: "retain-on-failure",
    screenshot: "only-on-failure",
    video: "off"
  },
  outputDir: "artifacts/release-verification/live-backend-browser/test-results"
});
