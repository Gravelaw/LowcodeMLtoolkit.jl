import { createHmac, timingSafeEqual } from "node:crypto";
import { createServer } from "node:http";
import { mkdirSync, writeFileSync } from "node:fs";
import { join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const DEFAULT_PORT = 8787;
const DEFAULT_ARTIFACT_ROOT = join(process.cwd(), "artifacts", "github-ci-webhook-monitor");
const MAX_BODY_BYTES = 2 * 1024 * 1024;

function parseArgs(argv) {
  const options = {
    port: Number(process.env.GITHUB_WEBHOOK_MONITOR_PORT ?? DEFAULT_PORT),
    host: process.env.GITHUB_WEBHOOK_MONITOR_HOST ?? "127.0.0.1",
    artifactRoot: process.env.GITHUB_WEBHOOK_MONITOR_ARTIFACT_ROOT ?? DEFAULT_ARTIFACT_ROOT,
    secret: process.env.GITHUB_WEBHOOK_SECRET ?? "",
    allowUnsigned: process.env.GITHUB_WEBHOOK_ALLOW_UNSIGNED === "1",
    repo: process.env.GITHUB_WEBHOOK_MONITOR_REPO ?? ""
  };

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === "--port") options.port = Number(argv[++index]);
    else if (arg === "--host") options.host = argv[++index];
    else if (arg === "--artifact-root") options.artifactRoot = argv[++index];
    else if (arg === "--secret") options.secret = argv[++index];
    else if (arg === "--repo") options.repo = argv[++index];
    else if (arg === "--allow-unsigned") options.allowUnsigned = true;
    else if (arg === "--help") options.help = true;
    else throw new Error(`Unknown argument: ${arg}`);
  }
  return options;
}

function usage() {
  return [
    "Usage: node scripts/github-ci-webhook-monitor.mjs [options]",
    "",
    "Options:",
    "  --port <port>              Local listen port. Default: 8787",
    "  --host <host>              Local listen host. Default: 127.0.0.1",
    "  --artifact-root <path>     Event log directory. Default: artifacts/github-ci-webhook-monitor",
    "  --secret <secret>          GitHub webhook secret. Prefer GITHUB_WEBHOOK_SECRET.",
    "  --repo <owner/name>        Optional repo filter for received events.",
    "  --allow-unsigned           Accept unsigned payloads for local testing only.",
    "",
    "GitHub webhook settings:",
    "  Payload URL: https://<public-tunnel-or-server>/webhook",
    "  Content type: application/json",
    "  Secret: same value as GITHUB_WEBHOOK_SECRET",
    "  Events: Workflow runs, Check runs, Check suites, Pull requests, Statuses",
    "",
    "Local health endpoint: GET /health"
  ].join("\n");
}

function jsonResponse(response, statusCode, payload) {
  response.writeHead(statusCode, { "content-type": "application/json; charset=utf-8" });
  response.end(JSON.stringify(payload));
}

function computeSignature(secret, bodyBuffer) {
  return `sha256=${createHmac("sha256", secret).update(bodyBuffer).digest("hex")}`;
}

function verifySignature({ secret, signature, bodyBuffer, allowUnsigned = false }) {
  if (!secret) return Boolean(allowUnsigned);
  if (!signature || !signature.startsWith("sha256=")) return false;
  const expected = Buffer.from(computeSignature(secret, bodyBuffer), "utf8");
  const actual = Buffer.from(signature, "utf8");
  if (expected.length !== actual.length) return false;
  return timingSafeEqual(expected, actual);
}

function compactSha(value) {
  return typeof value === "string" && value.length > 7 ? value.slice(0, 7) : String(value ?? "");
}

function repoFullName(payload) {
  return payload?.repository?.full_name ?? "";
}

function pullNumbers(items) {
  if (!Array.isArray(items)) return [];
  return items.map((item) => item?.number).filter((value) => Number.isInteger(value));
}

function summarizePayload(eventName, payload) {
  if (eventName === "workflow_run") {
    const run = payload.workflow_run ?? {};
    const prs = pullNumbers(run.pull_requests);
    return {
      kind: "workflow_run",
      action: payload.action ?? "",
      repo: repoFullName(payload),
      workflow: run.name ?? "",
      runNumber: run.run_number ?? null,
      status: run.status ?? "",
      conclusion: run.conclusion ?? "",
      headSha: run.head_sha ?? "",
      displaySha: compactSha(run.head_sha),
      pullRequests: prs,
      url: run.html_url ?? ""
    };
  }

  if (eventName === "check_run") {
    const check = payload.check_run ?? {};
    const prs = pullNumbers(check.pull_requests);
    return {
      kind: "check_run",
      action: payload.action ?? "",
      repo: repoFullName(payload),
      name: check.name ?? "",
      status: check.status ?? "",
      conclusion: check.conclusion ?? "",
      headSha: check.head_sha ?? "",
      displaySha: compactSha(check.head_sha),
      pullRequests: prs,
      url: check.html_url ?? ""
    };
  }

  if (eventName === "check_suite") {
    const suite = payload.check_suite ?? {};
    const prs = pullNumbers(suite.pull_requests);
    return {
      kind: "check_suite",
      action: payload.action ?? "",
      repo: repoFullName(payload),
      status: suite.status ?? "",
      conclusion: suite.conclusion ?? "",
      headSha: suite.head_sha ?? "",
      displaySha: compactSha(suite.head_sha),
      pullRequests: prs,
      url: suite.url ?? ""
    };
  }

  if (eventName === "pull_request") {
    const pr = payload.pull_request ?? {};
    return {
      kind: "pull_request",
      action: payload.action ?? "",
      repo: repoFullName(payload),
      number: pr.number ?? null,
      state: pr.state ?? "",
      draft: Boolean(pr.draft),
      headSha: pr.head?.sha ?? "",
      displaySha: compactSha(pr.head?.sha),
      url: pr.html_url ?? ""
    };
  }

  if (eventName === "status") {
    return {
      kind: "status",
      action: payload.state ?? "",
      repo: repoFullName(payload),
      context: payload.context ?? "",
      status: payload.state ?? "",
      conclusion: payload.state ?? "",
      headSha: payload.sha ?? "",
      displaySha: compactSha(payload.sha),
      url: payload.target_url ?? ""
    };
  }

  return {
    kind: eventName,
    action: payload.action ?? "",
    repo: repoFullName(payload),
    status: "",
    conclusion: "",
    headSha: "",
    displaySha: "",
    url: ""
  };
}

function statusLine(summary) {
  const parts = [
    "github-ci",
    summary.kind,
    summary.action ? `action=${summary.action}` : "",
    summary.repo ? `repo=${summary.repo}` : "",
    summary.workflow ? `workflow=${summary.workflow}` : "",
    summary.name ? `name=${summary.name}` : "",
    Number.isInteger(summary.number) ? `pr=${summary.number}` : "",
    Array.isArray(summary.pullRequests) && summary.pullRequests.length > 0 ? `prs=${summary.pullRequests.join(",")}` : "",
    summary.status ? `status=${summary.status}` : "",
    summary.conclusion ? `conclusion=${summary.conclusion}` : "",
    summary.displaySha ? `sha=${summary.displaySha}` : "",
    summary.url ? `url=${summary.url}` : ""
  ].filter(Boolean);
  return parts.join(" ");
}

function appendEvent(artifactRoot, record) {
  mkdirSync(artifactRoot, { recursive: true });
  const line = `${JSON.stringify(record)}\n`;
  writeFileSync(join(artifactRoot, "events.jsonl"), line, { flag: "a" });
  writeFileSync(join(artifactRoot, "latest.json"), JSON.stringify(record, null, 2));
}

async function readBody(request) {
  const chunks = [];
  let total = 0;
  for await (const chunk of request) {
    total += chunk.length;
    if (total > MAX_BODY_BYTES) {
      throw new Error(`payload too large; max ${MAX_BODY_BYTES} bytes`);
    }
    chunks.push(chunk);
  }
  return Buffer.concat(chunks);
}

function createWebhookMonitor(options) {
  const artifactRoot = resolve(options.artifactRoot ?? DEFAULT_ARTIFACT_ROOT);
  const server = createServer(async (request, response) => {
    try {
      const url = new URL(request.url ?? "/", `http://${request.headers.host ?? "localhost"}`);
      if (request.method === "GET" && url.pathname === "/health") {
        jsonResponse(response, 200, {
          ok: true,
          artifactRoot,
          repoFilter: options.repo || null,
          unsignedPayloadsAllowed: Boolean(options.allowUnsigned)
        });
        return;
      }

      if (request.method !== "POST" || url.pathname !== "/webhook") {
        jsonResponse(response, 404, { error: "not found" });
        return;
      }

      const bodyBuffer = await readBody(request);
      const signature = request.headers["x-hub-signature-256"];
      const signatureValue = Array.isArray(signature) ? signature[0] : signature;
      if (!verifySignature({
        secret: options.secret,
        signature: signatureValue,
        bodyBuffer,
        allowUnsigned: options.allowUnsigned
      })) {
        jsonResponse(response, 401, { error: "invalid webhook signature" });
        return;
      }

      const eventName = String(request.headers["x-github-event"] ?? "unknown");
      const delivery = String(request.headers["x-github-delivery"] ?? "");
      const payload = JSON.parse(bodyBuffer.toString("utf8"));
      const summary = summarizePayload(eventName, payload);
      if (options.repo && summary.repo && summary.repo !== options.repo) {
        jsonResponse(response, 202, { ignored: true, reason: "repo filter mismatch", summary });
        return;
      }

      const record = {
        receivedAt: new Date().toISOString(),
        delivery,
        event: eventName,
        summary
      };
      appendEvent(artifactRoot, record);
      console.log(statusLine(summary));
      jsonResponse(response, 202, { ok: true, summary });
    } catch (error) {
      jsonResponse(response, 400, { error: error instanceof Error ? error.message : String(error) });
    }
  });
  return server;
}

function startServer(options) {
  if (!options.secret && !options.allowUnsigned) {
    throw new Error("GITHUB_WEBHOOK_SECRET is required unless --allow-unsigned is set for local testing");
  }
  const server = createWebhookMonitor(options);
  server.listen(options.port, options.host, () => {
    console.log(`GitHub CI webhook monitor listening on http://${options.host}:${options.port}/webhook`);
    console.log(`Writing events to ${resolve(options.artifactRoot)}`);
  });
  return server;
}

const invokedPath = process.argv[1] ? resolve(process.argv[1]) : "";
const currentPath = fileURLToPath(import.meta.url);
if (invokedPath === currentPath) {
  try {
    const options = parseArgs(process.argv.slice(2));
    if (options.help) {
      console.log(usage());
      process.exit(0);
    }
    startServer(options);
  } catch (error) {
    console.error(error instanceof Error ? error.message : String(error));
    console.error("");
    console.error(usage());
    process.exit(1);
  }
}

export {
  computeSignature,
  createWebhookMonitor,
  parseArgs,
  statusLine,
  summarizePayload,
  verifySignature
};
