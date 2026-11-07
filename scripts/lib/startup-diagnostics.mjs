import { spawn } from "node:child_process";
import { StringDecoder } from "node:string_decoder";
import { performance } from "node:perf_hooks";

const OUTPUT_LIMIT = 16384;
const LINE_LIMIT = 4096;
const delay = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

export function redactStartup(value, env = {}) {
  let text = String(value);
  const secrets = Object.entries(env)
    .filter(([key, val]) => /TOKEN|SECRET|PASSWORD|API_KEY|PRIVATE_KEY|DATABASE_URL|CONNECTION_STRING|COOKIE|CREDENTIAL/i.test(key) && val)
    .flatMap(([, val]) => [String(val), String(val).trim(), encodeURIComponent(String(val)), ...String(val).split(/\r?\n/).map((line) => line.trim())])
    .filter(Boolean).sort((a, b) => b.length - a.length);
  for (const secret of secrets) text = text.split(secret).join("[REDACTED]");
  return text
    .replace(/([a-z][a-z0-9+.-]*:\/\/)[^\s/@]+@/gi, "$1[REDACTED]@")
    .replace(/(Bearer\s+)[^\s,;"']+/gi, "$1[REDACTED]")
    .replace(/((?:token|password|secret|api[_-]?key|cookie)\s*[=:]\s*)[^\s,;]+/gi, "$1[REDACTED]");
}

function errorDetail(error, depth = 0) {
  if (!error || depth > 3) return "";
  const detail = [error.name, error.code, error.message].filter(Boolean).join(": ");
  return error.cause ? `${detail}; cause=${errorDetail(error.cause, depth + 1)}` : detail;
}

function endpointName(url) {
  const parsed = new URL(url);
  return `${parsed.protocol}//${parsed.host}${parsed.pathname}`;
}

// Buffer complete lines before redacting, including secrets split across pipe chunks.
// Oversized lines are omitted as a whole rather than emitting an unredacted suffix.
export function captureStartupOutput(stream, append, redact) {
  const decoder = new StringDecoder("utf8");
  let pending = "";
  let dropping = false;
  function consume(text) {
    for (const part of text.match(/[^\n]*\n|[^\n]+$/g) ?? []) {
      const complete = part.endsWith("\n");
      if (!dropping) {
        if (pending.length + part.length > LINE_LIMIT) {
          pending = "";
          dropping = true;
          append("[oversized gateway output line omitted]\n");
        } else {
          pending += part;
        }
      }
      if (complete) {
        if (!dropping) append(redact(pending));
        pending = "";
        dropping = false;
      }
    }
  }
  stream.on("data", (chunk) => consume(decoder.write(chunk)));
  stream.on("end", () => {
    consume(decoder.end());
    if (pending && !dropping) append(redact(pending));
    pending = "";
  });
}

export function startDiagnosticProcess(command, args, { cwd, env, log = console.log } = {}) {
  const started = performance.now();
  const redact = (value) => redactStartup(value, env);
  const state = { spawned: false, pid: null, exitCode: null, signal: null, spawnError: null, exited: false, closed: false };
  let output = "";
  const reportedStages = new Set();
  const child = spawn(command, args, { cwd, env, stdio: ["ignore", "pipe", "pipe"], shell: false });
  const append = (line) => {
    output = (output + line).slice(-OUTPUT_LIMIT);
    const stage = line.match(/^\[gateway:startup\] (module-loading|module-loaded|state-initializing|state-ready|listener-starting) elapsedMs=\d+\s*$/)?.[1];
    if (stage && !reportedStages.has(stage)) {
      reportedStages.add(stage);
      log(`[api-gateway] ${line.trim()}`);
    }
  };
  captureStartupOutput(child.stdout, append, redact);
  captureStartupOutput(child.stderr, append, redact);
  child.on("spawn", () => { state.spawned = true; state.pid = child.pid; });
  child.on("error", (error) => { state.spawnError = redact(errorDetail(error)); });
  child.on("exit", (code, signal) => { state.exited = true; state.exitCode = code; state.signal = signal; });
  const closed = new Promise((resolve) => child.once("close", () => { state.closed = true; resolve(); }));
  const snapshot = () => ({ ...state, elapsedMs: Math.round(performance.now() - started) });
  const failure = () => state.spawnError || (state.exited ? `gateway exited code=${state.exitCode} signal=${state.signal}` : null);
  async function waitForClose(timeoutMs) {
    let timer;
    try { await Promise.race([closed, new Promise((resolve) => { timer = setTimeout(resolve, timeoutMs); })]); }
    finally { clearTimeout(timer); }
    return state.closed;
  }
  async function stop(graceMs = 3000) {
    if (state.closed) return;
    if (!state.exited && !state.spawnError) child.kill("SIGTERM");
    if (await waitForClose(graceMs)) return;
    child.kill("SIGKILL");
    if (await waitForClose(graceMs)) return;
    child.stdout.destroy();
    child.stderr.destroy();
    child.unref();
    throw new Error("Gateway cleanup did not close the child and its output pipes");
  }
  return { child, snapshot, failure, stop, redact, output: () => output };
}

export async function waitForStartupJson(url, timeoutMs, { headers = {}, process: gateway, ready = () => true, pollMs = 300 } = {}) {
  const started = performance.now();
  const endpoint = endpointName(url);
  let lastError = "no response";
  const elapsed = () => Math.round(performance.now() - started);
  const failure = (reason) => new Error(`Readiness failed endpoint=${endpoint} elapsedMs=${elapsed()} deadlineMs=${timeoutMs}; ${reason}; lastError=${lastError}`);
  while (performance.now() - started < timeoutMs) {
    if (gateway?.failure()) throw failure(gateway.failure());
    const controller = new AbortController();
    const remaining = Math.max(1, timeoutMs - (performance.now() - started));
    const timer = setTimeout(() => controller.abort(new Error("readiness deadline expired")), remaining);
    const onExit = () => controller.abort(new Error(gateway.failure() ?? "gateway closed"));
    gateway?.child.once("exit", onExit);
    gateway?.child.once("error", onExit);
    try {
      const response = await fetch(url, { headers, signal: controller.signal });
      if (!response.ok) {
        lastError = `HTTP ${response.status}`;
        await response.body?.cancel();
      } else {
        const payload = await response.json();
        if (ready(payload)) {
          if (gateway?.failure()) throw failure(gateway.failure());
          return payload;
        }
        lastError = "JSON response is not ready";
      }
    } catch (error) {
      // A final deadline abort must not erase the connection/HTTP/JSON diagnosis.
      if (!controller.signal.aborted || lastError === "no response") lastError = errorDetail(error);
    } finally {
      clearTimeout(timer);
      gateway?.child.removeListener("exit", onExit);
      gateway?.child.removeListener("error", onExit);
    }
    if (gateway?.failure()) throw failure(gateway.failure());
    const left = timeoutMs - (performance.now() - started);
    if (left > 0) await delay(Math.min(pollMs, left));
  }
  throw failure("readiness deadline expired");
}

export function startupFailure(error, gateway, stateAtFailure, cleanupError) {
  return new Error(gateway.redact(`${error.message}\n${JSON.stringify({ stateAtFailure, stateAfterCleanup: gateway.snapshot(), cleanupError: cleanupError?.message ?? null })}\n--- bounded gateway output ---\n${gateway.output() || "[no gateway output]"}`));
}
