// Cross-platform smoke test (issue #6): a real headless server, the real
// browser build in Chromium, and the scripted PC client (same NetClient as
// the desktop build) meet in one room, in both directions:
//   A. browser creates the room, PC joins, browser (Host) starts the Match
//   B. PC creates the room, browser joins, PC (Host) starts the Match
//
// Prerequisites: build/web exported, Godot on PATH (or GODOT), Playwright.
//   NODE_PATH=$(npm root -g) node tools/web_smoke.mjs
import { createRequire } from 'node:module';
import { spawn } from 'node:child_process';
import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import { extname, join, resolve } from 'node:path';

// Resolved through NODE_PATH so a globally installed Playwright works too.
const { chromium } = createRequire(import.meta.url)('playwright');
const GODOT = process.env.GODOT || 'godot';
const ROOT = resolve(new URL('..', import.meta.url).pathname);
const WEB_DIR = join(ROOT, 'build', 'web');
const WS_PORT = 18000 + Math.floor(Math.random() * 1000);
const HTTP_PORT = WS_PORT + 1000;
const WS_URL = `ws://127.0.0.1:${WS_PORT}`;
const TYPES = { '.html': 'text/html', '.js': 'text/javascript', '.wasm': 'application/wasm', '.pck': 'application/octet-stream', '.png': 'image/png' };
const children = [];

function run(args, onLine) {
  const child = spawn(GODOT, args, { cwd: ROOT });
  children.push(child);
  let buffer = '';
  const exited = new Promise((done) => child.on('exit', (code) => done(code)));
  child.stdout.on('data', (chunk) => {
    buffer += chunk;
    let index;
    while ((index = buffer.indexOf('\n')) >= 0) {
      const line = buffer.slice(0, index).trim();
      buffer = buffer.slice(index + 1);
      if (line) { console.log(`   [godot] ${line}`); onLine?.(line); }
    }
  });
  return { child, exited };
}

async function waitFor(check, what, ms = 60000) {
  const start = Date.now();
  while (Date.now() - start < ms) {
    const value = await check();
    if (value) return value;
    await new Promise((r) => setTimeout(r, 250));
  }
  throw new Error(`timed out waiting for ${what}`);
}

const http = createServer(async (req, res) => {
  try {
    const path = join(WEB_DIR, decodeURIComponent(new URL(req.url, 'http://x').pathname).replace(/^\/$/, '/index.html'));
    const body = await readFile(path);
    res.writeHead(200, { 'Content-Type': TYPES[extname(path)] || 'application/octet-stream' });
    res.end(body);
  } catch { res.writeHead(404); res.end(); }
});

let failed = false;
try {
  await new Promise((done) => http.listen(HTTP_PORT, '127.0.0.1', done));
  console.log(`web build on http://127.0.0.1:${HTTP_PORT}, server on ${WS_URL}`);
  const server = run(['--headless', '--path', '.', '--', '--server', `--port=${WS_PORT}`]);
  await new Promise((r) => setTimeout(r, 1500));
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
  page.on('pageerror', (e) => console.log(`   [browser error] ${e.message}`));
  const state = () => page.evaluate(() => window.__forest || null);

  console.log('A. browser hosts, PC joins');
  await page.goto(`http://127.0.0.1:${HTTP_PORT}/index.html?server=${encodeURIComponent(WS_URL)}&name=WebHost&auto=1`);
  const hosted = await waitFor(async () => { const s = await state(); return s && s.code ? s : null; }, 'browser room');
  console.log(`   browser created room ${hosted.code}`);
  const pc = run(['--headless', '--path', '.', '-s', 'tools/pc_smoke_client.gd', '--', `--url=${WS_URL}`, `--join=${hosted.code}`, '--name=PcGuest']);
  await waitFor(async () => { const s = await state(); return s && s.controllers[1] === 'human'; }, 'PC player in slot 2');
  await page.screenshot({ path: join(ROOT, 'build', 'web_smoke_lobby.png') });
  await page.keyboard.press('Enter');
  const phaseA = await waitFor(async () => { const s = await state(); return s && s.phase ? s.phase : null; }, 'Match start in browser');
  if ((await pc.exited) !== 0) throw new Error('PC client did not see the Match start');
  await page.screenshot({ path: join(ROOT, 'build', 'web_smoke_match.png') });
  console.log(`   OK: Match started (${phaseA}) for browser Host and PC guest`);

  console.log('B. PC hosts, browser joins');
  let code = '';
  const host = run(['--headless', '--path', '.', '-s', 'tools/pc_smoke_client.gd', '--', `--url=${WS_URL}`, '--create', '--name=PcHost'],
    (line) => { if (line.startsWith('CODE=')) code = line.slice(5); });
  await waitFor(async () => code, 'PC room code');
  const guest = await browser.newPage({ viewport: { width: 1280, height: 720 } });
  await guest.goto(`http://127.0.0.1:${HTTP_PORT}/index.html?server=${encodeURIComponent(WS_URL)}&name=WebGuest&join=${code.toLowerCase()}&auto=1`);
  const joined = await waitFor(async () => { const s = await guest.evaluate(() => window.__forest || null); return s && s.phase ? s : null; }, 'browser sees Match start');
  if ((await host.exited) !== 0) throw new Error('PC host did not start the Match');
  console.log(`   OK: browser joined ${code} as slot ${joined.your_slot + 1} and sees phase ${joined.phase}`);
  await browser.close();
  server.child.kill();
} catch (error) {
  failed = true;
  console.error(`FAILED: ${error.message}`);
} finally {
  for (const child of children) child.kill();
  http.close();
}
console.log(failed ? 'web smoke test FAILED' : 'web smoke test passed');
process.exit(failed ? 1 : 0);
