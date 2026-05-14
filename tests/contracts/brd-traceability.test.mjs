import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import { checkedMilestoneItems, validateTraceability } from "../../scripts/validate-brd-traceability.mjs";

const todoPath = new URL("../../docs/TODO.md", import.meta.url);
const traceabilityPath = new URL("../../docs/brd-traceability.md", import.meta.url);

test("BRD traceability links every checked P0/P1/P2 TODO to evidence", async () => {
  const [todoText, traceabilityText] = await Promise.all([
    readFile(todoPath, "utf8"),
    readFile(traceabilityPath, "utf8")
  ]);

  const checkedItems = checkedMilestoneItems(todoText);
  assert.ok(checkedItems.length > 0, "expected checked P0/P1/P2 TODO items to validate");

  const result = validateTraceability(todoText, traceabilityText);
  assert.deepEqual(result.errors, []);
  assert.equal(result.ok, true);
});
