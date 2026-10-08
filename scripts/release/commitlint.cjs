#!/usr/bin/env node
"use strict";
const message = require("node:fs").readFileSync(0, "utf8").trim();
const subject = message.split(/\r?\n/, 1)[0] || "";
const allowed = new Set(["feat", "fix", "perf", "revert", "docs", "chore", "style", "refactor", "test", "build", "ci"]);
const match = subject.match(/^(\w+)(\([^)]+\))?(!)?: .+$/);
process.exit(match && allowed.has(match[1]) ? 0 : 1);
