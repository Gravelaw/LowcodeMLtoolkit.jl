#!/usr/bin/env node
import { readFile } from "node:fs/promises";

const gates = [
  {
    path: "apps/frontend/src/App.test.tsx",
    minTests: 8,
    minAssertions: 90,
    testPattern: /\b(?:test|it)\s*\(/g,
    assertionPattern: /\bexpect\s*\(/g,
    requiredPatterns: [/control-flow/, /Published dashboard/]
  },
  {
    path: "tests/contracts/workflow-schema.test.mjs",
    minTests: 5,
    minAssertions: 120,
    testPattern: /\btest\s*\(/g,
    assertionPattern: /\bassert\.[a-zA-Z]+\s*\(/g,
    requiredPatterns: [/ObservabilityTraceRecord/, /observabilityTrace/]
  },
  {
    path: "tests/julia/runtests.jl",
    minTestsets: 12,
    minAssertions: 520,
    testsetPattern: /@testset\b/g,
    assertionPattern: /@test(?:_|\b)/g,
    requiredPatterns: [/observability_trace/, /juliaflow_observability_spans_total/]
  },
  {
    path: "extensions/base/test/runtests.jl",
    minTestsets: 18,
    minAssertions: 300,
    testsetPattern: /@testset\b/g,
    assertionPattern: /@test(?:_|\b)/g,
    requiredPatterns: [/available_nodes/, /base\./]
  }
];

function countMatches(text, pattern) {
  return [...text.matchAll(pattern)].length;
}

function fail(message) {
  console.error(message);
  process.exitCode = 1;
}

for (const gate of gates) {
  const text = await readFile(gate.path, "utf8");
  const testCount = gate.testPattern ? countMatches(text, gate.testPattern) : undefined;
  const testsetCount = gate.testsetPattern ? countMatches(text, gate.testsetPattern) : undefined;
  const assertionCount = countMatches(text, gate.assertionPattern);

  if (gate.minTests !== undefined && testCount < gate.minTests) {
    fail(`${gate.path}: expected >= ${gate.minTests} JS test cases, found ${testCount}`);
  }
  if (gate.minTestsets !== undefined && testsetCount < gate.minTestsets) {
    fail(`${gate.path}: expected >= ${gate.minTestsets} Julia testsets, found ${testsetCount}`);
  }
  if (assertionCount < gate.minAssertions) {
    fail(`${gate.path}: expected >= ${gate.minAssertions} assertions, found ${assertionCount}`);
  }
  for (const pattern of gate.requiredPatterns) {
    if (!pattern.test(text)) {
      fail(`${gate.path}: missing required coverage marker ${pattern}`);
    }
  }

  console.log(
    JSON.stringify({
      path: gate.path,
      tests: testCount,
      testsets: testsetCount,
      assertions: assertionCount,
      passed: true
    })
  );
}
