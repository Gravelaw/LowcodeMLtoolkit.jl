import { spawnSync } from "node:child_process";

const npmCommand = process.platform === "win32" ? "npm.cmd" : "npm";

const result = spawnSync(
  npmCommand,
  ["run", "test:browser:local:runner"],
  {
    env: {
      ...process.env,
      JULIAFLOW_BROWSER_LIVE: "1"
    },
    stdio: "inherit"
  }
);

if (result.error) {
  throw result.error;
}

process.exit(result.status ?? 1);
