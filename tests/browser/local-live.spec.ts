import { expect, test } from "@playwright/test";

interface LiveHealth {
  localHome?: string;
  dataEstateRoot?: string;
  status?: string;
}

const gatewayBaseUrl = process.env.JULIAFLOW_GATEWAY_BASE_URL
  ?? process.env.VITE_JULIAFLOW_GATEWAY_BASE_URL
  ?? "http://127.0.0.1:8088";

test("optional live local gateway smoke reflects real health evidence", async ({ page }) => {
  let health: LiveHealth;
  try {
    const response = await fetch(`${gatewayBaseUrl}/health`);
    if (!response.ok) {
      throw new Error(`GET /health returned ${response.status}`);
    }
    health = await response.json() as LiveHealth;
  } catch (error) {
    throw new Error(`Live JuliaFlow gateway is not reachable at ${gatewayBaseUrl}: ${(error as Error).message}`);
  }

  if (!health.localHome && !health.dataEstateRoot) {
    throw new Error("Live gateway health response did not include localHome or dataEstateRoot evidence.");
  }

  await page.addInitScript((baseUrl) => {
    window.__JULIAFLOW_CONFIG__ = { gatewayBaseUrl: baseUrl };
  }, gatewayBaseUrl);

  await page.goto("/");
  await expect(page.getByRole("status", { name: /100% local status/i })).toContainText("100% Local");
  await page.getByRole("button", { name: "Settings" }).click();

  if (health.localHome) {
    await expect(page.getByText(health.localHome, { exact: true }).first()).toBeVisible();
  }
  if (health.dataEstateRoot) {
    await expect(page.getByText(health.dataEstateRoot, { exact: true }).first()).toBeVisible();
  }
});
