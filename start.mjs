// One-command launcher for NORTE BOUND (Node.js stdlib fallback when Python is not installed).
import fs from 'node:fs';
import http from 'node:http';
import net from 'node:net';
import os from 'node:os';
import path from 'node:path';
import readline from 'node:readline/promises';
import { execFile, spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { promisify } from 'node:util';

const execFileAsync = promisify(execFile);

const ROOT = path.dirname(fileURLToPath(import.meta.url));
const BACKEND_DIR = path.join(ROOT, 'backend');
const ADMIN_WEB_DIR = path.join(ROOT, 'admin-web');
const MOBILE_DIR = path.join(ROOT, 'mobile');

const API_PORT = 5000;
const WEB_PORT = 5173;
const HEALTH_URL = `http://127.0.0.1:${API_PORT}/api/v1/health`;
const ADMIN_WEB_URL = `http://127.0.0.1:${WEB_PORT}`;

const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.svg': 'image/svg+xml',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
};

const spawned = [];
let webServer = null;

function parseArgs(argv) {
  const opts = { mode: null, noBrowser: false, checkOnly: false };
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === '--no-browser') {
      opts.noBrowser = true;
    } else if (arg === '--check' || arg === '--exit-after-check') {
      opts.checkOnly = true;
    } else if (arg === '--mode' && argv[i + 1]) {
      opts.mode = argv[i + 1].trim().toLowerCase();
      i += 1;
    } else if (arg.startsWith('--mode=')) {
      opts.mode = arg.slice('--mode='.length).trim().toLowerCase();
    }
  }
  return opts;
}

function isPortOpen(host, port, timeoutMs = 600) {
  return new Promise((resolve) => {
    const socket = net.createConnection({ host, port });
    const done = (ok) => {
      socket.removeAllListeners();
      socket.destroy();
      resolve(ok);
    };
    socket.setTimeout(timeoutMs);
    socket.once('connect', () => done(true));
    socket.once('timeout', () => done(false));
    socket.once('error', () => done(false));
  });
}

async function isHealthOk() {
  try {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 1500);
    const res = await fetch(HEALTH_URL, { signal: controller.signal });
    clearTimeout(timer);
    return res.ok;
  } catch {
    return false;
  }
}

function detectLanIp() {
  const nets = os.networkInterfaces();
  const candidates = [];
  for (const [iface, entries] of Object.entries(nets)) {
    if (!entries) continue;
    const lowName = iface.toLowerCase();
    const isVirtual = /vethernet|virtualbox|vmware|wsl|hyper-v|loopback|docker/.test(lowName);
    for (const addr of entries) {
      if (addr.family !== 'IPv4' || addr.internal) continue;
      if (addr.address.startsWith('169.254.')) continue;
      const score = (isVirtual ? 0 : 10) + (addr.address.startsWith('192.168.') ? 5 : 0);
      candidates.push({ address: addr.address, score });
    }
  }
  candidates.sort((a, b) => b.score - a.score);
  return candidates[0]?.address || '127.0.0.1';
}

async function findAdb() {
  const cmd = process.platform === 'win32' ? 'where.exe' : 'which';
  try {
    const { stdout } = await execFileAsync(cmd, ['adb']);
    const first = stdout.split(/\r?\n/).find(Boolean);
    if (first) return first.trim();
  } catch {
    // not on PATH
  }
  if (process.platform === 'win32') {
    const candidate = path.join(
      process.env.LOCALAPPDATA || '',
      'Android',
      'Sdk',
      'platform-tools',
      'adb.exe',
    );
    if (fs.existsSync(candidate)) return candidate;
  }
  return null;
}

function openBrowser(url) {
  if (process.platform === 'win32') {
    spawn('cmd.exe', ['/d', '/s', '/c', 'start', '', url], { detached: true, stdio: 'ignore' }).unref();
  } else if (process.platform === 'darwin') {
    spawn('open', [url], { detached: true, stdio: 'ignore' }).unref();
  } else {
    spawn('xdg-open', [url], { detached: true, stdio: 'ignore' }).unref();
  }
}

async function startAdminWeb() {
  if (await isPortOpen('127.0.0.1', WEB_PORT)) {
    console.log(`[admin-web] Already running at ${ADMIN_WEB_URL}`);
    return;
  }

  webServer = http.createServer((req, res) => {
    const urlPath = (req.url || '/').split('?')[0];
    const rel = urlPath === '/' ? 'index.html' : urlPath.replace(/^\/+/, '');
    const fullPath = path.resolve(ADMIN_WEB_DIR, rel);
    if (!fullPath.startsWith(ADMIN_WEB_DIR) || !fs.existsSync(fullPath) || fs.statSync(fullPath).isDirectory()) {
      res.writeHead(404);
      res.end('Not found');
      return;
    }
    const ext = path.extname(fullPath).toLowerCase();
    res.writeHead(200, { 'Content-Type': MIME_TYPES[ext] || 'application/octet-stream' });
    fs.createReadStream(fullPath).pipe(res);
  });

  await new Promise((resolve, reject) => {
    webServer.once('error', reject);
    webServer.listen(WEB_PORT, '127.0.0.1', resolve);
  });
  console.log(`[admin-web] Serving at ${ADMIN_WEB_URL}`);
}

function runShellCommand(command, cwd) {
  if (process.platform === 'win32') {
    return spawn('cmd.exe', ['/d', '/s', '/c', command], { cwd, stdio: 'inherit' });
  }
  return spawn('/bin/sh', ['-c', command], { cwd, stdio: 'inherit' });
}

async function startBackend() {
  if (await isHealthOk()) {
    console.log(`[backend]   Already healthy at http://127.0.0.1:${API_PORT}/api/v1`);
    return;
  }

  if (!fs.existsSync(path.join(BACKEND_DIR, '.env'))) {
    console.log('[backend]   Warning: backend/.env is missing. Copy backend/.env.example to backend/.env first.');
  }

  if (!fs.existsSync(path.join(BACKEND_DIR, 'node_modules'))) {
    console.log('[backend]   Installing Node dependencies (first run)...');
    const installProc = runShellCommand('npm install', BACKEND_DIR);
    const code = await new Promise((resolve) => installProc.once('exit', resolve));
    if (code !== 0) {
      throw new Error(`npm install exited with code ${code}`);
    }
  }

  const proc = spawn(process.execPath, ['src/app.js'], {
    cwd: BACKEND_DIR,
    stdio: ['ignore', 'pipe', 'pipe'],
  });
  spawned.push(proc);

  const deadline = Date.now() + 20_000;
  while (Date.now() < deadline) {
    if (proc.exitCode !== null) {
      throw new Error(`Backend exited early with code ${proc.exitCode}`);
    }
    if (await isHealthOk()) {
      console.log(`[backend]   Ready at http://127.0.0.1:${API_PORT}/api/v1`);
      return;
    }
    await new Promise((r) => setTimeout(r, 500));
  }
  throw new Error(`Backend did not respond at ${HEALTH_URL} within 20s.`);
}

async function chooseMode(cliMode, lanIp) {
  if (cliMode) return cliMode;
  console.log('\nSelect Flutter client connection mode:');
  console.log('  1) emulator  - Android Emulator            (http://10.0.2.2:5000/api/v1)');
  console.log('  2) usb       - Physical Phone via USB      (adb reverse -> http://127.0.0.1:5000/api/v1)');
  console.log(`  3) wifi      - Physical Phone via Wi-Fi    (http://${lanIp}:5000/api/v1)`);
  console.log('  4) web       - Flutter Web in Chrome       (http://localhost:5000/api/v1)');
  console.log('  5) servers   - Backend + Admin Web only    (do not launch Flutter)');

  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  const raw = (await rl.question('\nEnter 1-5 [default 1]: ')).trim().toLowerCase();
  rl.close();

  const map = {
    '': 'emulator',
    1: 'emulator',
    emulator: 'emulator',
    2: 'usb',
    usb: 'usb',
    3: 'wifi',
    wifi: 'wifi',
    4: 'web',
    web: 'web',
    5: 'servers',
    servers: 'servers',
  };
  return map[raw] || 'emulator';
}

async function setupAdbReverse(adbPath) {
  if (!adbPath) {
    console.log('[usb]       Warning: adb.exe not found on PATH or Android SDK; skipped adb reverse.');
    return;
  }
  try {
    await execFileAsync(adbPath, ['reverse', `tcp:${API_PORT}`, `tcp:${API_PORT}`]);
    console.log(`[usb]       adb reverse tcp:${API_PORT} -> tcp:${API_PORT} active`);
  } catch (err) {
    console.log(`[usb]       adb reverse warning: ${err.stderr || err.message}`);
  }
}

function cleanup() {
  if (webServer) {
    webServer.close();
    webServer = null;
  }
  for (const proc of spawned.reverse()) {
    if (proc.exitCode === null) {
      proc.kill();
    }
  }
}

async function main() {
  const opts = parseArgs(process.argv.slice(2));
  process.on('SIGINT', () => {
    cleanup();
    process.exit(0);
  });
  process.on('SIGTERM', () => {
    cleanup();
    process.exit(0);
  });

  try {
    console.log('=== NORTE BOUND Launcher ===');
    await startBackend();
    await startAdminWeb();

    const lanIp = detectLanIp();
    const adbPath = await findAdb();

    console.log('\nStatus Summary:');
    console.log(`  - Backend API:    http://127.0.0.1:${API_PORT}/api/v1`);
    console.log(`  - Backend (LAN):  http://${lanIp}:${API_PORT}/api/v1`);
    console.log(`  - Admin Web:      ${ADMIN_WEB_URL}`);
    console.log(`  - ADB detected:   ${adbPath || 'not found'}`);

    if (opts.checkOnly) {
      cleanup();
      return 0;
    }

    if (!opts.noBrowser) {
      openBrowser(ADMIN_WEB_URL);
    }

    const mode = await chooseMode(opts.mode, lan_ip_safe(lanIp));
    if (mode === 'servers') {
      console.log('\nBackend and Admin Web are active. Press Ctrl+C to stop.');
      await new Promise(() => {});
    }

    let apiUrl = `http://10.0.2.2:${API_PORT}/api/v1`;
    let flutterCmd = `flutter run --dart-define="API_BASE_URL=${apiUrl}"`;

    if (mode === 'usb') {
      await setupAdbReverse(adbPath);
      apiUrl = `http://127.0.0.1:${API_PORT}/api/v1`;
      flutterCmd = `flutter run --dart-define="API_BASE_URL=${apiUrl}"`;
    } else if (mode === 'wifi') {
      apiUrl = `http://${lanIp}:${API_PORT}/api/v1`;
      flutterCmd = `flutter run --dart-define="API_BASE_URL=${apiUrl}"`;
    } else if (mode === 'web') {
      apiUrl = `http://localhost:${API_PORT}/api/v1`;
      flutterCmd = `flutter run -d chrome --dart-define="API_BASE_URL=${apiUrl}"`;
    }

    console.log(`\n[flutter]   Launching (${mode}) with API_BASE_URL=${apiUrl}`);
    const flutterProc = runShellCommand(flutterCmd, MOBILE_DIR);
    spawned.push(flutterProc);
    const code = await new Promise((resolve) => flutterProc.once('exit', (c) => resolve(c ?? 0)));
    cleanup();
    return code;
  } catch (err) {
    console.error(`[error] ${err.message}`);
    cleanup();
    return 1;
  }
}

function lan_ip_safe(ip) {
  return ip || '127.0.0.1';
}

main().then((code) => process.exit(code));
