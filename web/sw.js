// Keeps a copy of everything the app fetches from its own origin, so launches
// after the first read the engine, the code, sqlite and the fonts from the
// device instead of the network.
//
// The cache is named after the version in this script's URL, which the deploy
// script stamps per build. A new deploy therefore installs as a new worker
// with its own cache; it takes over once every page of the old one is closed,
// and the launch after that runs entirely on the new files. Nothing is served
// from a mix of two versions.
'use strict';

const VERSION = new URL(self.location.href).searchParams.get('v') || 'dev';
const CACHE = 'gym-' + VERSION;

// Fetched at install time so the second launch is already served from the
// device. Files the page asks for beyond these are cached as they go by.
const SHELL = [
  'index.html',
  'flutter_bootstrap.js',
  'main.dart.js',
  'sqlite3.wasm',
  'drift_worker.js',
  'manifest.json',
  'favicon.png',
  'assets/AssetManifest.bin',
  'assets/AssetManifest.bin.json',
  'assets/FontManifest.json',
  'assets/fonts/MaterialIcons-Regular.otf',
  'assets/assets/fonts/Phosphor-Duotone.ttf',
  'assets/assets/fonts/MPLUSRounded1c-Regular.ttf',
  'assets/assets/fonts/MPLUSRounded1c-Bold.ttf',
  'assets/assets/data/mext_foods.json',
];

// Same choice flutter.js makes between the two CanvasKit builds.
const chromium = typeof ImageDecoder !== 'undefined' &&
  typeof Intl.v8BreakIterator !== 'undefined' &&
  typeof Intl.Segmenter !== 'undefined';
const ENGINE = chromium
  ? ['canvaskit/chromium/canvaskit.js', 'canvaskit/chromium/canvaskit.wasm']
  : ['canvaskit/canvaskit.js', 'canvaskit/canvaskit.wasm'];

function shellUrl(path) {
  return new URL(path, self.registration.scope).href;
}

self.addEventListener('install', (event) => {
  event.waitUntil((async () => {
    const cache = await caches.open(CACHE);
    // "no-cache" revalidates with the server, so a file the page has just
    // downloaded is not fetched twice, while a file changed by a new deploy
    // is not taken from a stale HTTP cache.
    await Promise.all(SHELL.concat(ENGINE).map(async (path) => {
      try {
        const res = await fetch(shellUrl(path), { cache: 'no-cache' });
        if (res.ok) await cache.put(shellUrl(path), res);
      } catch (_) {
        // Left for the runtime path below.
      }
    }));
  })());
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    for (const key of await caches.keys()) {
      if (key.startsWith('gym-') && key !== CACHE) await caches.delete(key);
    }
  })());
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  if (url.origin !== self.location.origin) return;
  if (url.pathname.endsWith('/sw.js')) return;

  const key = req.mode === 'navigate' ? shellUrl('index.html') : url.href;
  event.respondWith((async () => {
    const cache = await caches.open(CACHE);
    const hit = await cache.match(key);
    if (hit) return hit;
    const res = await fetch(req);
    if (res.ok && res.type === 'basic') await cache.put(key, res.clone());
    return res;
  })());
});
