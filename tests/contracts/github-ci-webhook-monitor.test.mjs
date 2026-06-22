import test from "node:test";
import assert from "node:assert/strict";
import {
  computeSignature,
  statusLine,
  summarizePayload,
  verifySignature
} from "../../scripts/github-ci-webhook-monitor.mjs";

test("GitHub webhook signature verification accepts only matching HMAC", () => {
  const body = Buffer.from(JSON.stringify({ ok: true }));
  const signature = computeSignature("test-secret", body);

  assert.equal(
    verifySignature({
      secret: "test-secret",
      signature,
      bodyBuffer: body
    }),
    true
  );
  assert.equal(
    verifySignature({
      secret: "test-secret",
      signature,
      bodyBuffer: Buffer.from("{}")
    }),
    false
  );
  assert.equal(
    verifySignature({
      secret: "",
      signature: "",
      bodyBuffer: body,
      allowUnsigned: false
    }),
    false
  );
});

test("GitHub workflow_run payload summary is compact and PR-aware", () => {
  const summary = summarizePayload("workflow_run", {
    action: "completed",
    repository: { full_name: "Gravelaw/LowcodeMLtoolkit.jl" },
    workflow_run: {
      name: "ci",
      run_number: 158,
      status: "completed",
      conclusion: "success",
      head_sha: "cfdbf27eef3fe42561e4da4751b02f7756f9ed47",
      html_url: "https://github.com/Gravelaw/LowcodeMLtoolkit.jl/actions/runs/1",
      pull_requests: [{ number: 40 }]
    }
  });

  assert.equal(summary.kind, "workflow_run");
  assert.equal(summary.workflow, "ci");
  assert.equal(summary.displaySha, "cfdbf27");
  assert.deepEqual(summary.pullRequests, [40]);
  assert.match(statusLine(summary), /conclusion=success/);
  assert.match(statusLine(summary), /prs=40/);
});

test("GitHub check_run payload summary captures check name and conclusion", () => {
  const summary = summarizePayload("check_run", {
    action: "completed",
    repository: { full_name: "Gravelaw/LowcodeMLtoolkit.jl" },
    check_run: {
      name: "julia",
      status: "completed",
      conclusion: "failure",
      head_sha: "1234567890abcdef",
      html_url: "https://github.com/Gravelaw/LowcodeMLtoolkit.jl/actions/runs/1/job/2",
      pull_requests: [{ number: 40 }]
    }
  });

  assert.equal(summary.kind, "check_run");
  assert.equal(summary.name, "julia");
  assert.equal(summary.conclusion, "failure");
  assert.equal(summary.displaySha, "1234567");
  assert.match(statusLine(summary), /name=julia/);
});
