import { createServer } from "vite";
import { fileURLToPath } from "node:url";
import { join } from "node:path";

const root = fileURLToPath(new URL("../apps/frontend", import.meta.url));
const runtimeMode = process.env.JULIAFLOW_RUNTIME_MODE ?? "local-appliance";
if (!["demo", "development", "release", "local-appliance"].includes(runtimeMode)) throw new Error("Unsupported runtime mode");
const host = process.env.JULIAFLOW_GATEWAY_HOST ?? "127.0.0.1";
const port = Number(process.env.JULIAFLOW_FRONTEND_PORT ?? 5173);
const server = await createServer({
  root,
  configFile: join(root, "vite.config.ts"),
  configLoader: "runner",
  server: { host, port, strictPort: true, cors: { origin: process.env.JULIAFLOW_LOCAL_FRONTEND_URL ?? `http://${host}:${port}` } },
  plugins: [{
    name: "juliaflow-local-runtime",
    configureServer(vite) {
      vite.middlewares.use((request, response, next) => {
        if (request.url?.split("?")[0] !== "/juliaflow-config.js") return next();
        response.setHeader("Content-Type", "application/javascript");
        response.setHeader("Cache-Control", "no-store");
        // Public bootstrap metadata only. Credentials are not served by this classic script.
        response.end(`window.__JULIAFLOW_CONFIG__ = { runtimeMode: ${JSON.stringify(runtimeMode)} };\n`);
      });
    }
  }]
});
await server.listen();
server.printUrls();
