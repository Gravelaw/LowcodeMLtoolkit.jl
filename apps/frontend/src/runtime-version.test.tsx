import { cleanup, render, screen, within } from "@testing-library/react";
import { afterEach, expect, it, vi } from "vitest";
import { Shell } from "./components/Shell";
import { SettingsView } from "./views/SettingsView";
import { localHealth } from "./fixtures/local-fixtures";
import type { AppData } from "./types";

afterEach(cleanup);

function shell(version?: string, stale = false) {
  return render(<Shell activeView="explorer" juliaVersion={version} runtimeStale={stale}
    onNavigate={vi.fn()} onPrimaryAction={vi.fn()} onGridAction={vi.fn()} onShareAction={vi.fn()}
    onHelpAction={vi.fn()} onProfileAction={vi.fn()}>content</Shell>);
}

function settings(version?: string, stale = false, mode: AppData["mode"] = "live") {
  const data = { mode, health: { ...localHealth, juliaVersion: version }, healthStale: stale,
    runtimeMode: "local-appliance", runtime: localHealth.runtime, checkpoints: [] } as unknown as AppData;
  render(<SettingsView data={data} onSaveComputeSettings={vi.fn()} />);
  return within(screen.getByText("Julia", { exact: true }).closest("tr")!);
}

it("shell reports the supplied measured version instead of a fixed version", () => {
  shell("1.12.6");
  expect(screen.getByText("Julia 1.12.6 Local")).toBeInTheDocument();
  expect(screen.queryByText(/1\.10\.2/)).toBeNull();
});

it("shell labels absent and stale runtime evidence explicitly", () => {
  shell(); expect(screen.getByText("Julia version unavailable")).toBeInTheDocument();
  cleanup(); shell("1.12.6", true);
  expect(screen.getByText("Julia 1.12.6 (last reported)")).toBeInTheDocument();
});

it("settings shows gateway evidence without claiming a latest release", () => {
  const row = settings("1.12.6");
  expect(row.getByText("1.12.6")).toBeInTheDocument();
  expect(row.getByText("reported by gateway")).toBeInTheDocument();
  expect(row.queryByText("up to date")).toBeNull();
});

it("older gateways and fixture data cannot invent a runtime version", () => {
  expect(settings().getAllByText("unavailable")).toHaveLength(2);
  cleanup(); expect(settings("1.12.6", false, "demo").getAllByText("unavailable")).toHaveLength(2);
});

it("settings keeps stale evidence visibly marked", () => {
  expect(settings("1.12.6", true).getByText("last reported")).toBeInTheDocument();
});
