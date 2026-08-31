import { strict as assert } from "assert";
import { readFileSync } from "fs";
import { resolve } from "path";

// Conservative source contract for the existing rules grammar. Count call sites,
// not a simulator's cache: duplicate reads also consume this source allowance.
// This is a contract for this call graph, not a general Firebase Rules parser.
function uploadLookupCount(source: string): number {
  const text = source.replace(/\/\/[^\n]*/g, "");
  const definitions = new Map<string, string>();
  for (const match of text.matchAll(/function\s+(\w+)\s*\([^)]*\)\s*\{/g)) {
    let index = match.index! + match[0].length, depth = 1;
    const start = index;
    while (depth && index < text.length) {
      if (text[index] === "{") depth++;
      if (text[index] === "}") depth--;
      index++;
    }
    assert.equal(depth, 0);
    definitions.set(match[1], text.slice(start, index - 1));
  }
  const createRules = [...text.matchAll(/allow\s+create\s*:\s*if\s+([^;]+);/g)];
  assert.equal(createRules.length, 1, "Review any added upload create rule");
  function count(body: string, seen: Set<string>): number {
    let total = [...body.matchAll(/firestore\.(?:get|exists)\s*\(/g)].length;
    for (const call of body.matchAll(/(?<![.\w])([A-Za-z_]\w*)\s*\(/g)) {
      const nested = definitions.get(call[1]);
      if (nested === undefined) continue;
      assert(!seen.has(call[1]), "Recursive rule helper");
      total += count(nested, new Set([...seen, call[1]]));
    }
    return total;
  }
  return count(createRules[0][1], new Set());
}

describe("Storage upload lookup budget independent of the emulator", () => {
  const source = readFileSync(resolve(__dirname, "../storage.rules"), "utf8");
  it("uses exactly two cross-service lookups", () => assert.equal(uploadLookupCount(source), 2));
  it("detects a third lookup hidden in a called helper", () => {
    const bad = source.replace("function ownsUploadTicket", "function extraRead() { return firestore.exists(/databases/(default)/documents/extra/one); }\n    function ownsUploadTicket")
      .replace("&& ownsUploadTicket(uid, draftId)", "&& extraRead() && ownsUploadTicket(uid, draftId)");
    assert.equal(uploadLookupCount(bad), 3);
    assert.throws(() => assert(uploadLookupCount(bad) <= 2));
  });
});
