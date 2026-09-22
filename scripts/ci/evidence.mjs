import { createHash } from 'node:crypto';
import { mkdirSync, readFileSync, readdirSync, writeFileSync, renameSync, lstatSync, copyFileSync } from 'node:fs';
import { join, relative, dirname } from 'node:path';
import { redactStartup } from '../lib/startup-diagnostics.mjs';

export function writeJson(path, value) {
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(`${path}.tmp`, JSON.stringify(value, null, 2) + '\n');
  renameSync(`${path}.tmp`, path);
}
export function inventory(root) {
  const files = {};
  function visit(dir) {
    for (const entry of readdirSync(dir, { withFileTypes: true })) {
      const path = join(dir, entry.name);
      if (entry.isSymbolicLink()) continue;
      if (entry.isDirectory()) visit(path);
      else if (entry.isFile() && entry.name !== 'sha256.json') files[relative(root, path).replaceAll('\\', '/')] = createHash('sha256').update(readFileSync(path)).digest('hex');
    }
  }
  visit(root); return files;
}
export function retainTree(source, target, env = {}) {
  if (!lstatSync(source, { throwIfNoEntry: false })) return;
  if (lstatSync(source).isSymbolicLink()) throw new Error('Evidence symlink rejected');
  mkdirSync(target, { recursive: true });
  for (const entry of readdirSync(source, { withFileTypes: true })) {
    const from = join(source, entry.name), to = join(target, entry.name);
    if (entry.isSymbolicLink()) throw new Error('Evidence symlink rejected');
    if (entry.isDirectory()) retainTree(from, to, env);
    else if (/\.(log|json|txt|md|toml|jsonl)$/i.test(entry.name)) writeFileSync(to, redactStartup(readFileSync(from, 'utf8'), env));
    else copyFileSync(from, to);
  }
}
