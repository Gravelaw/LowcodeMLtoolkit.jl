# GitHub CI Webhook Monitor

Use this local monitor when working on long-running PRs so CI status arrives by webhook instead of repeated manual `gh api` polling.

## Run Locally

```powershell
$env:GITHUB_WEBHOOK_SECRET = "<shared-secret>"
npm run monitor:github-ci -- --repo Gravelaw/LowcodeMLtoolkit.jl
```

Default listener:

- Health: `http://127.0.0.1:8787/health`
- Webhook: `http://127.0.0.1:8787/webhook`
- Event log: `artifacts/github-ci-webhook-monitor/events.jsonl`
- Latest event: `artifacts/github-ci-webhook-monitor/latest.json`

For local testing only, unsigned payloads can be accepted:

```powershell
npm run monitor:github-ci -- --allow-unsigned
```

Do not use `--allow-unsigned` for a real GitHub webhook.

## GitHub Webhook Setup

GitHub must reach the listener over a public HTTPS URL. For a workstation, expose the local listener through a trusted tunnel or deploy this script on a small internal server.

Configure the repository webhook:

- Payload URL: `https://<public-url>/webhook`
- Content type: `application/json`
- Secret: same value as `GITHUB_WEBHOOK_SECRET`
- Events: `Workflow runs`, `Check runs`, `Check suites`, `Pull requests`, and `Statuses`

The monitor validates `X-Hub-Signature-256` before accepting payloads and writes compact summaries for PR/CI events.

## Expected Output

Example console line:

```text
github-ci workflow_run action=completed repo=Gravelaw/LowcodeMLtoolkit.jl workflow=ci prs=40 status=completed conclusion=success sha=cfdbf27 url=https://github.com/...
```

Use `latest.json` when another local automation needs to check the most recent CI event without calling GitHub.
