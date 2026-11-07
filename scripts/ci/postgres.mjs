export function postgresReadiness(env = process.env) {
  const mode = env.JULIAFLOW_CI_EXTERNAL_POSTGRES;
  if (mode !== undefined && mode !== '0' && mode !== '1') throw new Error('Invalid JULIAFLOW_CI_EXTERNAL_POSTGRES; use 0 or 1');
  if (mode !== '1') return { external: false, command: 'docker', args: ['compose', '-f', 'infra/docker/compose.dev.yml', 'exec', '-T', 'postgres', 'pg_isready', '-U', 'juliaflow', '-d', 'juliaflow'] };
  if (!env.JULIAFLOW_DATABASE_URL) throw new Error('External PostgreSQL requires JULIAFLOW_DATABASE_URL');
  let url;
  try { url = new URL(env.JULIAFLOW_DATABASE_URL); } catch { throw new Error('Invalid external PostgreSQL URL'); }
  if (!['postgres:', 'postgresql:'].includes(url.protocol) || !url.hostname) throw new Error('Invalid external PostgreSQL URL');
  return { external: true, command: 'pg_isready', args: ['-d', env.JULIAFLOW_DATABASE_URL] };
}
