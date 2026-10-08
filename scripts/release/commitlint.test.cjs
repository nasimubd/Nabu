const test = require("node:test");
const assert = require("node:assert/strict");
const { spawnSync } = require("node:child_process");

function check(message) {
  return spawnSync(process.execPath, ["scripts/release/commitlint.cjs"], {
    input: message,
    encoding: "utf8"
  }).status;
}

test("accepts Conventional Commits", () => {
  assert.equal(check("feat(workflow): record a finding\n"), 0);
  assert.equal(check("fix: correct a case path\n"), 0);
});

test("rejects unstructured subjects", () => {
  assert.notEqual(check("Add release tooling\n"), 0);
});
