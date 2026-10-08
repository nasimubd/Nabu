#!/usr/bin/env node
"use strict";
const fs = require("node:fs");
const version = process.argv[2];
if (!version || !/^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?$/.test(version)) {
  process.stderr.write("expected a semantic version without a leading v\n");
  process.exit(1);
}
fs.writeFileSync("VERSION", `${version}\n`);
