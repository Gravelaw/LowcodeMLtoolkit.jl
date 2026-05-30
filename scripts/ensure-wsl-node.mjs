#!/usr/bin/env node
if (process.platform !== "linux") {
  console.error("JuliaFlow JS tooling must run with native WSL/Linux Node.js, not Windows Node.js.");
  console.error("Open WSL, ensure `which node` and `which npm` resolve outside /mnt/c, then rerun the command.");
  process.exit(1);
}

const nodePath = process.execPath.replaceAll("\\", "/").toLowerCase();
if (nodePath.startsWith("/mnt/c/") || nodePath.includes("/program files/nodejs/")) {
  console.error("JuliaFlow JS tooling detected Windows Node.js through WSL interop: " + process.execPath);
  console.error("Use native WSL Node.js, for example ~/.nvm/versions/node/<version>/bin/node.");
  process.exit(1);
}
