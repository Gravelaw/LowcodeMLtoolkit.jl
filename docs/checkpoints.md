# Checkpoints and Rollback

## Required Tags

- `cp/00-foundation`
- `cp/01-contracts-frozen`
- `cp/02-alpha-core`
- `cp/03-alpha-gpu-bi`
- `cp/04-beta-streaming`
- `cp/05-beta-security-hub`
- `cp/06-ga-platform`
- `cp/07-ga-enterprise`
- `cp/08-scale`

## Evidence Bundle Per Checkpoint

- Green CI
- Updated ADR or design note
- Schema version note for contract changes
- Workflow fixture snapshot
- Release note in `docs/releases/<tag>.md`
- Rollback notes with image digests and DB/object-store snapshot references for risky milestones

## Rollback Rule

- Roll back by tag plus artifact digest, never by partial file reverts
- Use expand/contract migrations only
- Record root cause before re-promoting failed checkpoint

