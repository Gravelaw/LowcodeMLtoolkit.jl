import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, readFileSync, writeFileSync, mkdirSync, cpSync, existsSync, symlinkSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { spawn } from 'node:child_process';
import { pathToFileURL } from 'node:url';
import { runProcess } from '../../scripts/ci/process.mjs';
const temp = () => mkdtempSync(join(tmpdir(), 'juliaflow-ci-test-'));

test('streaming retains output on command failure and split secrets are redacted', async () => {
 const log=join(temp(),'command.log'); const secret='private-ci-token-123';
 const r=await runProcess(process.execPath,['-e',`process.stdout.write('private-ci-'); setTimeout(()=>{console.log('token-123'); process.exit(7)},20)`],{logPath:log,env:{...process.env,TEST_SECRET:secret},echo:false});
 assert.equal(r.status,'failed'); assert.equal(r.exitCode,7); assert.match(readFileSync(log,'utf8'),/REDACTED/); assert.ok(!readFileSync(log,'utf8').includes(secret));
});
test('spawn failure is reported without hanging', async () => {
 const r=await runProcess('juliaflow-command-that-does-not-exist',[],{echo:false}); assert.equal(r.status,'failed'); assert.match(r.error,/ENOENT/);
});
test('deadline and cancellation remain distinct and preserve prior output', async () => {
 const log=join(temp(),'timeout.log');
 const r=await runProcess(process.execPath,['-e',`console.log('started'); setInterval(()=>{},1000)`],{timeoutMs:350,graceMs:50,logPath:log,echo:false});
 assert.equal(r.status,'timed_out'); assert.match(readFileSync(log,'utf8'),/started/);
 const c=new AbortController();setTimeout(()=>c.abort(),150);
 const s=await runProcess(process.execPath,['-e','setInterval(()=>{},1000)'],{signal:c.signal,graceMs:50,echo:false}); assert.equal(s.status,'cancelled');
});
test('already cancelled commands never spawn', async () => {
 const c=new AbortController();c.abort();let events=0;
 const r=await runProcess(process.execPath,['-e','throw Error()'],{signal:c.signal,onEvent:()=>events++});assert.equal(r.status,'cancelled');assert.equal(events,0);
});
test('POSIX descendants retaining pipes are bounded', {skip:process.platform==='win32'}, async()=>{
 const code=`require('child_process').spawn(process.execPath,['-e',"process.on('SIGTERM',()=>{});setInterval(()=>{},1000)"],{stdio:'inherit'});setTimeout(()=>process.exit(0),200)`;
 const started=Date.now();const r=await runProcess(process.execPath,['-e',code],{timeoutMs:2000,graceMs:50,echo:false});assert.equal(r.status,'passed');assert.ok(Date.now()-started<1800);
});
test('external PostgreSQL requires a valid explicit endpoint; default remains Compose', async()=>{
 const {postgresReadiness}=await import('../../scripts/ci/postgres.mjs');
 assert.equal(postgresReadiness({}).command,'docker');
 assert.throws(()=>postgresReadiness({JULIAFLOW_CI_EXTERNAL_POSTGRES:'1'}),/requires/);
 assert.throws(()=>postgresReadiness({JULIAFLOW_CI_EXTERNAL_POSTGRES:'yes'}),/Invalid/);
 assert.throws(()=>postgresReadiness({JULIAFLOW_CI_EXTERNAL_POSTGRES:'1',JULIAFLOW_DATABASE_URL:'file:///tmp/db'}),/Invalid/);
 const p=postgresReadiness({JULIAFLOW_CI_EXTERNAL_POSTGRES:'1',JULIAFLOW_DATABASE_URL:'postgresql://tester:secret@postgres/db'});
 assert.equal(p.command,'pg_isready');assert.equal(p.external,true);
});

test('Windows descendants are removed after their parent exits', {skip:process.platform!=='win32'}, async()=>{
 const pidFile=join(temp(),'child.pid');
 const code=`const c=require('child_process').spawn(process.execPath,['-e','setInterval(()=>{},1000)'],{stdio:'inherit'});require('fs').writeFileSync(${JSON.stringify(pidFile)},String(c.pid));setTimeout(()=>process.exit(0),200)`;
 try {
  const r=await runProcess(process.execPath,['-e',code],{graceMs:50,echo:false});assert.equal(r.status,'passed');assert.equal(r.cleanupIncomplete,false); assert.throws(()=>process.kill(Number(readFileSync(pidFile,'utf8')),0));
 } finally {if(existsSync(pidFile)) {try{process.kill(Number(readFileSync(pidFile,'utf8')))}catch{}}}
});
