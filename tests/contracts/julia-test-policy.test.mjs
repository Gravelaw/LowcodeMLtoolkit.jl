import assert from "node:assert/strict";
import test from "node:test";
import { executeJuliaTestPhases, juliaTestPhases } from "../../scripts/lib/julia-test-policy.mjs";

test("GPU opt-in retains source tests and requires actual hardware assertions in normal runtime mode", () => {
  const ran = [];
  const phases = juliaTestPhases({ cudaRequested: true, workerSelected: true });
  assert.equal(executeJuliaTestPhases(phases, (phase) => { ran.push(phase); return { status: 0 }; }), 0);
  assert.deepEqual(ran, [
    { name: "source-loading", compiledModules: "no", cudaSmoke: "0" },
    { name: "physical-cuda", compiledModules: "yes", cudaSmoke: "1" }
  ]);
});

test("hardware failure remains a failing aggregate result", () => {
  const ran = [];
  const phases = juliaTestPhases({ cudaRequested: true, workerSelected: true });
  assert.equal(executeJuliaTestPhases(phases, (phase) => {
    ran.push(phase.name); return { status: phase.name === "physical-cuda" ? 2 : 0 };
  }), 2);
  assert.deepEqual(ran, ["source-loading", "physical-cuda"]);
});

test("source failure stops the command rather than being replaced by a hardware pass", () => {
  const ran = [];
  assert.equal(executeJuliaTestPhases(juliaTestPhases({ cudaRequested: true, workerSelected: true }), (phase) => {
    ran.push(phase.name); return { status: 7 };
  }), 7);
  assert.deepEqual(ran, ["source-loading"]);
});

test("spawn failures and cancellation signals cannot report a successful test", () => {
  const phases = juliaTestPhases({ cudaRequested: true, workerSelected: true });
  assert.throws(() => executeJuliaTestPhases(phases, () => ({ error: new Error("spawn failed") })), /spawn failed/);
  assert.equal(executeJuliaTestPhases(phases, () => ({ status: null })), 1);
});

test("CPU-only slices preserve no-compiled-modules coverage without claiming GPU verification", () => {
  for (const facts of [{ cudaRequested: false, workerSelected: true }, { cudaRequested: true, workerSelected: false }]) {
    assert.deepEqual(juliaTestPhases(facts), [{ name: "source-loading", compiledModules: "no", cudaSmoke: "0" }]);
  }
});
