import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, readFileSync, writeFileSync, mkdirSync, cpSync, existsSync, symlinkSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { parseArgs } from '../../scripts/ci/local.mjs';
import { verifyParity } from '../../scripts/ci/parity.mjs';
import { runProcess } from '../../scripts/ci/process.mjs';
import { inventory, retainTree, writeJson } from '../../scripts/ci/evidence.mjs';
const temp = () => mkdtempSync(join(tmpdir(), 'juliaflow-ci-test-'));

test('profiles require explicit candidate/base and reject unknown jobs/options', () => {
 assert.throws(() => parseArgs([]));
 assert.throws(() => parseArgs(['--ref','HEAD','--base','main','--cache','invalid']));
 assert.throws(() => parseArgs(['--ref','HEAD','--base','main','--force','true']));
 assert.equal(parseArgs(['--ref','HEAD','--base','main']).cache, 'cold');
});
test('both workflows and full command/timeout mappings agree', () => {
 const m = verifyParity(); assert.equal(m.jobs['release-candidate'].timeoutMinutes,90);
 assert.equal(m.jobs['debian-release-gate'].timeoutMinutes,180);
 assert.deepEqual(m.profiles.push,['web','julia']);
});
test('workflow edits and mapping-only timeout edits fail closed', () => {
 const dir=temp(); mkdirSync(join(dir,'scripts/ci'),{recursive:true}); mkdirSync(join(dir,'.github/workflows'),{recursive:true});
 for(const f of ['scripts/ci/workflows.json','.github/workflows/ci.yml','.github/workflows/release-candidate.yml']) cpSync(f,join(dir,f));
 const path=join(dir,'scripts/ci/workflows.json'), m=JSON.parse(readFileSync(path)); m.jobs.web.timeoutMinutes=999; writeJson(path,m);
 assert.throws(()=>verifyParity(dir),/Timeout mapping/);
 cpSync('scripts/ci/workflows.json',path);
 writeFileSync(join(dir,'.github/workflows/ci.yml'),readFileSync('.github/workflows/ci.yml','utf8')+'\n# drift\n');
 assert.throws(()=>verifyParity(dir),/parity drift/);
});
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
test('artifact retention is checksummed and text credentials redacted',()=>{
 const source=temp(),dest=temp(); writeFileSync(join(source,'output.log'),'Bearer private-test-value\n');retainTree(source,dest);assert.ok(!readFileSync(join(dest,'output.log'),'utf8').includes('private-test-value'));
 const hashes=inventory(dest);assert.match(hashes['output.log'],/^[a-f0-9]{64}$/);writeJson(join(dest,'summary.json'),{status:'cancelled'});assert.equal(JSON.parse(readFileSync(join(dest,'summary.json'))).status,'cancelled');
});
test('Docker configuration publishes no ports and mounts no Docker socket',()=>{
 const source=readFileSync('scripts/ci/local.mjs','utf8');assert.ok(!source.includes('/var/run/docker.sock'));assert.ok(!source.includes("'-p'"));assert.match(source,/randomBytes\(4\)/);
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

test('service readiness rejects unavailable PostgreSQL and honors cancellation',async()=>{
 const {waitForService}=await import('../../scripts/ci/resources.mjs');
 let calls=0;await waitForService(()=>++calls===2,{timeoutMs:100,intervalMs:1});assert.equal(calls,2);
 await assert.rejects(waitForService(()=>false,{timeoutMs:15,intervalMs:1}),/timed out/);
 const c=new AbortController();c.abort();await assert.rejects(waitForService(()=>true,{signal:c.signal}),/cancelled/);
});
test('cleanup cannot delete another concurrent run or an unowned volume',async()=>{
 const {removeOwnedResource}=await import('../../scripts/ci/resources.mjs');
 const calls=[];const other=args=>{calls.push(args);return 'another-run'};
 assert.throws(()=>removeOwnedResource(other,{kind:'container',name:'shared-cache-lock'},'this-run'),/Ownership/);assert.equal(calls.length,1);
 const own=args=>{calls.push(args);return 'this-run'};removeOwnedResource(own,{kind:'volume',name:'owned-cache'},'this-run');assert.deepEqual(calls.at(-1),['volume','rm','owned-cache']);
 assert.throws(()=>removeOwnedResource(own,{kind:'system',name:'anything'},'this-run'),/Unknown/);
});

test('Windows descendants are removed after their parent exits', {skip:process.platform!=='win32'}, async()=>{
 const pidFile=join(temp(),'child.pid');
 const code=`const c=require('child_process').spawn(process.execPath,['-e','setInterval(()=>{},1000)'],{stdio:'inherit'});require('fs').writeFileSync(${JSON.stringify(pidFile)},String(c.pid));setTimeout(()=>process.exit(0),200)`;
 try {
  const r=await runProcess(process.execPath,['-e',code],{graceMs:50,echo:false});assert.equal(r.status,'passed');assert.equal(r.cleanupIncomplete,false); assert.throws(()=>process.kill(Number(readFileSync(pidFile,'utf8')),0));
 } finally {if(existsSync(pidFile)) {try{process.kill(Number(readFileSync(pidFile,'utf8')))}catch{}}}
});
