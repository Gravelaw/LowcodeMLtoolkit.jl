#!/usr/bin/env node
import { readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";

const TODO_PATH = new URL("../docs/TODO.md", import.meta.url);
const TRACE_PATH = new URL("../docs/brd-traceability.md", import.meta.url);

const SECTION_RE = /^##\s+(P[0-2])\b/;
const NEXT_SECTION_RE = /^##\s+P[0-9]\b/;
const CHECKED_RE = /^\s*\d+\.\s+\[x\]\s+(.+?)(?::|$)/i;

function normalize(text) {
  return text
    .toLowerCase()
    .replace(/[`*_]/g, "")
    .replace(/\s+/g, " ")
    .trim();
}

export function checkedMilestoneItems(todoText) {
  const lines = todoText.split(/\r?\n/);
  const items = [];
  let activeSection = null;

  for (const line of lines) {
    const section = line.match(SECTION_RE);
    if (section) {
      activeSection = section[1];
      continue;
    }
    if (activeSection && NEXT_SECTION_RE.test(line) && !SECTION_RE.test(line)) {
      activeSection = null;
      continue;
    }
    if (!activeSection) {
      continue;
    }

    const checked = line.match(CHECKED_RE);
    if (checked) {
      items.push({ section: activeSection, title: checked[1].trim(), line });
    }
  }

  return items;
}

export function checkedP0P1Items(todoText) {
  return checkedMilestoneItems(todoText);
}

export function validateTraceability(todoText, traceabilityText) {
  const items = checkedMilestoneItems(todoText);
  const traceLines = traceabilityText.split(/\r?\n/);
  const errors = [];

  for (const item of items) {
    const title = normalize(item.title);
    const matchingRows = traceLines.filter((line) => line.includes("|") && normalize(line).includes(title));

    if (matchingRows.length === 0) {
      errors.push(`${item.section} checked item missing from docs/brd-traceability.md: ${item.title}`);
      continue;
    }

    const hasCodeEvidence = matchingRows.some((row) =>
      /`(?:apps|packages|services|extensions|src|infra|scripts|docs)\//.test(row)
    );
    const hasTestEvidence = matchingRows.some((row) =>
      /`(?:tests\/|extensions\/[^`]+\/test\/|node tests\/|npm run test|npm run build|julia --project=\.)/.test(row)
    );

    if (!hasCodeEvidence) {
      errors.push(`${item.section} checked item lacks code/doc evidence path: ${item.title}`);
    }
    if (!hasTestEvidence) {
      errors.push(`${item.section} checked item lacks test/verification evidence: ${item.title}`);
    }
  }

  return { ok: errors.length === 0, checkedCount: items.length, errors };
}

export async function main() {
  const [todoText, traceabilityText] = await Promise.all([
    readFile(TODO_PATH, "utf8"),
    readFile(TRACE_PATH, "utf8")
  ]);
  const result = validateTraceability(todoText, traceabilityText);

  if (!result.ok) {
    console.error(`BRD traceability validation failed for ${result.checkedCount} checked P0/P1/P2 TODO items:`);
    for (const error of result.errors) {
      console.error(`- ${error}`);
    }
    process.exitCode = 1;
    return;
  }

  console.log(`BRD traceability validation passed for ${result.checkedCount} checked P0/P1/P2 TODO items.`);
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  await main();
}
