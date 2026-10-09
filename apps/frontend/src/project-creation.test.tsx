import { cleanup, fireEvent, render, screen, waitFor, within } from "@testing-library/react";
import { afterEach, beforeEach, expect, it, vi } from "vitest";
import App from "./App";
import { emptyProject } from "./project-workspace";
import { localHealth } from "./fixtures/local-fixtures";

const project = (id: string, name = id) => ({ ...emptyProject(), projectId: id, name });
const response = (body: unknown, status = 200) => new Response(JSON.stringify(body), { status, headers: { "content-type": "application/json" } });
function gateway(options: { inventory?: ReturnType<typeof project>[]; post?: () => Promise<Response>; get?: (id: string) => Promise<Response>; list?: () => Promise<Response> } = {}) {
  const inventory = [...(options.inventory ?? [])];
  return vi.spyOn(globalThis, "fetch").mockImplementation(async (input, init) => {
    const path = new URL(String(input)).pathname;
    if (path === "/health") return response(localHealth);
    if (path === "/api/v1/data-science-projects" && init?.method === "POST") {
      if (options.post) return options.post();
      const body = JSON.parse(String(init.body));
      const saved = { ...project(`returned-${inventory.length}`, body.name), description: body.description };
      inventory.push(saved);
      return response(saved, 201);
    }
    if (path === "/api/v1/data-science-projects") return options.list ? options.list() : response({ items: inventory });
    if (path.startsWith("/api/v1/data-science-projects/")) {
      const id = path.split("/").at(-1)!;
      return options.get ? options.get(id) : response(inventory.find((item) => item.projectId === id), inventory.some((item) => item.projectId === id) ? 200 : 404);
    }
    return response({ items: [] });
  });
}
async function fillCreate(name: string) {
  fireEvent.click(screen.getByRole("button", { name: "Create project", exact: true }));
  fireEvent.change(screen.getByLabelText("Project name"), { target: { value: name } });
}
beforeEach(() => {
  localStorage.clear(); window.history.pushState({}, "", "/");
  window.__JULIAFLOW_CONFIG__ = { gatewayBaseUrl: "http://localhost:8088", runtimeMode: "local-appliance" };
});
afterEach(() => { cleanup(); vi.restoreAllMocks(); });

it("loads an honest empty project inventory independently of zero workflows", async () => {
  const fetch = gateway(); render(<App />);
  await screen.findByText("No saved projects. Create a project to begin.");
  await waitFor(() => expect(fetch.mock.calls.some(([url]) => String(url).endsWith("data-science-projects"))).toBe(true));
  expect((screen.getByLabelText("Open saved project") as HTMLSelectElement).value).toBe("");
});
it("uses returned ID/readback, prevents repeated submission, and allows a second distinct creation", async () => {
  const fetch = gateway(); render(<App />); await fillCreate("First");
  const button = within(screen.getByRole("dialog")).getByRole("button", { name: "Create project", exact: true });
  fireEvent.click(button); fireEvent.click(button);
  await screen.findByText("Project saved and opened: returned-0.");
  expect(fetch.mock.calls.filter(([, init]) => init?.method === "POST")).toHaveLength(1);
  await fillCreate("Second"); fireEvent.click(within(screen.getByRole("dialog")).getByRole("button", { name: "Create project", exact: true }));
  await screen.findByText("Project saved and opened: returned-1.");
  expect(fetch.mock.calls.filter(([, init]) => init?.method === "POST")).toHaveLength(2);
});
it("retains inputs and never retries an uncertain POST or reconciles by name", async () => {
  const fetch = gateway({ post: async () => { throw Error("response lost"); } }); render(<App />);
  await fillCreate("Keep these inputs"); fireEvent.click(within(screen.getByRole("dialog")).getByRole("button", { name: "Create project", exact: true }));
  await screen.findByText(/Creation outcome is uncertain/);
  expect((screen.getByLabelText("Project name") as HTMLInputElement).value).toBe("Keep these inputs");
  fireEvent.click(screen.getByRole("button", { name: "Cancel" }));
  fireEvent.click(screen.getByRole("button", { name: "Create project", exact: true }));
  expect(screen.getByText(/Creation outcome is uncertain/)).toBeTruthy();
  expect((screen.getByLabelText("Project name") as HTMLInputElement).value).toBe("Keep these inputs");
  fireEvent.click(screen.getByRole("button", { name: "Inspect saved projects" }));
  expect(fetch.mock.calls.filter(([, init]) => init?.method === "POST")).toHaveLength(1);
});
it("retries only opening after successful creation with failed readback", async () => {
  let reads = 0;
  const fetch = gateway({ get: async (id) => response(project(id), ++reads === 1 ? 503 : 200) }); render(<App />);
  await fillCreate("Readback retry"); fireEvent.click(within(screen.getByRole("dialog")).getByRole("button", { name: "Create project", exact: true }));
  await screen.findByText(/was created, but could not be opened/);
  fireEvent.click(screen.getByRole("button", { name: "Retry opening project" }));
  await screen.findByText("Project saved and opened: returned-0.");
  expect(fetch.mock.calls.filter(([, init]) => init?.method === "POST")).toHaveLength(1);
});
it("preserves a valid remembered selection and supports deliberate clearing", async () => {
  localStorage.setItem("juliaflow.projectId", "b"); gateway({ inventory: [project("a"), project("b")] }); render(<App />);
  await waitFor(() => expect((screen.getByLabelText("Open saved project") as HTMLSelectElement).value).toBe("b"));
  fireEvent.change(screen.getByLabelText("Open saved project"), { target: { value: "" } });
  expect((screen.getByLabelText("Open saved project") as HTMLSelectElement).value).toBe("");
  expect(localStorage.getItem("juliaflow.projectId")).toBeNull();
});
it("retains project creation after optional folder failure", async () => {
  gateway(); render(<App />); await fillCreate("Folder independent");
  fireEvent.click(within(screen.getByRole("dialog")).getByRole("button", { name: "Create project", exact: true }));
  await screen.findByText("Project saved and opened: returned-0.");
  fireEvent.click(screen.getByRole("button", { name: "Write optional folder" }));
  await screen.findByText(/Folder picker unavailable/);
  expect((screen.getByLabelText("Open saved project") as HTMLSelectElement).value).toBe("returned-0");
});

it("does not let a late creation override a deliberate project switch", async () => {
  let finishPost!: (value: Response) => void;
  gateway({ inventory: [project("old"), project("chosen")], post: () => new Promise((resolve) => { finishPost = resolve; }), get: async (id) => response(project(id)) });
  render(<App />); await waitFor(() => expect((screen.getByLabelText("Open saved project") as HTMLSelectElement).value).toBe("old"));
  await fillCreate("Late created"); fireEvent.click(within(screen.getByRole("dialog")).getByRole("button", { name: "Create project", exact: true }));
  fireEvent.click(screen.getByRole("button", { name: "Cancel" }));
  fireEvent.change(screen.getByLabelText("Open saved project"), { target: { value: "chosen" } });
  await waitFor(() => expect((screen.getByLabelText("Open saved project") as HTMLSelectElement).value).toBe("chosen"));
  finishPost(response(project("late-created"), 201));
  await waitFor(() => expect(screen.getByRole("button", { name: "Create project", exact: true })).toBeTruthy());
  fireEvent.click(screen.getByRole("button", { name: "Create project", exact: true }));
  await screen.findByText(/Your current selection was preserved/);
  expect((screen.getByLabelText("Open saved project") as HTMLSelectElement).value).toBe("chosen");
});
it("ignores out-of-order opening results and keeps the latest chosen identity", async () => {
  let finishA!: (value: Response) => void;
  const fetch = gateway({ inventory: [project("a"), project("b")], get: (id) => id === "a" ? new Promise((resolve) => { finishA = resolve; }) : Promise.resolve(response(project(id))) });
  render(<App />);
  await waitFor(() => expect(fetch.mock.calls.some(([url]) => String(url).endsWith("/a"))).toBe(true));
  fireEvent.change(screen.getByLabelText("Open saved project"), { target: { value: "b" } });
  await waitFor(() => expect((screen.getByLabelText("Open saved project") as HTMLSelectElement).value).toBe("b"));
  finishA(response(project("a")));
  await new Promise((resolve) => setTimeout(resolve, 0));
  expect((screen.getByLabelText("Open saved project") as HTMLSelectElement).value).toBe("b");
});
it("keeps rejected creation fields editable and sends no request for an empty name", async () => {
  const fetch = gateway({ post: async () => response({ error: "name rejected" }, 400) }); render(<App />);
  await fillCreate(""); fireEvent.click(within(screen.getByRole("dialog")).getByRole("button", { name: "Create project", exact: true }));
  expect(screen.getByText("Project name is required.")).toBeTruthy();
  expect(fetch.mock.calls.filter(([, init]) => init?.method === "POST")).toHaveLength(0);
  fireEvent.change(screen.getByLabelText("Project name"), { target: { value: "Retained rejected name" } });
  fireEvent.click(within(screen.getByRole("dialog")).getByRole("button", { name: "Create project", exact: true }));
  await screen.findByText("name rejected");
  expect(screen.getByLabelText("Project name")).toHaveValue("Retained rejected name");
  expect(within(screen.getByRole("dialog")).getByRole("button", { name: "Create project", exact: true })).not.toBeDisabled();
});

it("rejects a refresh snapshot started before a new project was saved", async () => {
  let finishPost!: (value: Response) => void;
  let finishRefresh!: (value: Response) => void;
  let lists = 0;
  gateway({ list: () => ++lists === 1 ? Promise.resolve(response({ items: [] })) : new Promise((resolve) => { finishRefresh = resolve; }),
    post: () => new Promise((resolve) => { finishPost = resolve; }), get: async (id) => response(project(id)) });
  render(<App />); await screen.findByText("No saved projects. Create a project to begin.");
  await fillCreate("Created after snapshot");
  fireEvent.click(within(screen.getByRole("dialog")).getByRole("button", { name: "Create project", exact: true }));
  fireEvent.click(screen.getByRole("button", { name: "Cancel" }));
  fireEvent.click(screen.getByRole("button", { name: "Refresh projects" }));
  finishPost(response(project("newly-saved"), 201));
  await screen.findByText("Project saved and opened: newly-saved.");
  finishRefresh(response({ items: [] }));
  await new Promise((resolve) => setTimeout(resolve, 0));
  expect((screen.getByLabelText("Open saved project") as HTMLSelectElement).value).toBe("newly-saved");
});
