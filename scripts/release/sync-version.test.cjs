const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { spawnSync } = require("node:child_process");

function run(directory, version) {
  return spawnSync(process.execPath, [path.resolve("scripts/release/sync-version.cjs"), version], {
    cwd: directory,
    encoding: "utf8"
  });
}

test("writes a valid semantic version", () => {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), "nabu-release-"));
  const result = run(directory, "1.2.3");
  assert.equal(result.status, 0);
  assert.equal(fs.readFileSync(path.join(directory, "VERSION"), "utf8"), "1.2.3\n");
});

test("rejects a leading v", () => {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), "nabu-release-"));
  assert.notEqual(run(directory, "v1.2.3").status, 0);
});
