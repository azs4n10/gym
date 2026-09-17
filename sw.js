// Keeps a copy of everything the app fetches from its own origin, so launches
// after the first read the engine, the code, sqlite and the fonts from the
// device instead of the network.
//
// The cache is named after the version in this script's URL, which the deploy
// script stamps per build. The two entry files (index.html and the bootstrap
// that carries the version) are always fetched from the network first, so a
// new deploy is noticed on the next launch: its worker installs with its own
// cache and takes over as soon as it is ready. The bootstrap reloads the page
// when that happens before the first frame, so the launch continues on the
// new files; later than that, the next launch uses them.
'use strict';

const VERSION = new URL(self.location.href).searchParams.get('v') || 'dev';
const CACHE = 'gym-' + VERSION;

const ENTRY = ['index.html', 'flutter_bootstrap.js'];

// Fetched at install time so the second launch is already served from the
// device. Files the page asks for beyond these are cached as they go by.
const SHELL = [
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
  'assets/assets/companion/run_side_a.png',
  'assets/assets/companion/run_side_b.png',
  'assets/assets/companion/run_side_c.png',
  'assets/assets/companion/run_side_d.png',
  'assets/assets/companion/sit_side.png',
  'assets/assets/companion/run_side_tired.png',
  'assets/assets/companion/run_side_closed.png',
  'assets/assets/companion/run_back_a.png',
  'assets/assets/companion/run_back_b.png',
  'assets/assets/companion/stand_back.png',
  'assets/assets/companion/stand_front.png',
  'assets/assets/companion/hat_cap.png',
  'assets/assets/companion/hat_beanie.png',
  'assets/assets/companion/hat_flower.png',
  'assets/assets/companion/hat_headphones.png',
  'assets/assets/companion/hat_ribbon.png',
  'assets/assets/companion/hat_glasses.png',
  'assets/assets/companion/face_normal.png',
  'assets/assets/companion/face_smile.png',
  'assets/assets/companion/face_wink.png',
  'assets/assets/companion/face_surprised.png',
  'assets/assets/companion/face_angry.png',
  'assets/assets/companion/face_sad.png',
  'assets/assets/companion/face_shy.png',
  'assets/assets/companion/face_tired.png',
  'assets/assets/companion/rig/side.json',
  'assets/assets/companion/rig/side_swim.json',
  'assets/assets/companion/rig/side_gym.json',
  'assets/assets/companion/rig/side_head_quarter.png',
  'assets/assets/companion/rig/side_swim_body.png',
  'assets/assets/companion/rig/side_swim_arm.png',
  'assets/assets/companion/rig/side_swim_elbow.png',
  'assets/assets/companion/rig/side_swim_leg.png',
  'assets/assets/companion/rig/side_swim_knee.png',
  'assets/assets/companion/rig/side_gym_body.png',
  'assets/assets/companion/rig/side_gym_arm.png',
  'assets/assets/companion/rig/side_gym_elbow.png',
  'assets/assets/companion/rig/side_gym_shorts.png',
  'assets/assets/companion/rig/side_gym_shoe.png',
  'assets/assets/companion/rig/side_hair.png',
  'assets/assets/companion/rig/side_arm.png',
  'assets/assets/companion/rig/side_elbow.png',
  'assets/assets/companion/rig/side_leg.png',
  'assets/assets/companion/rig/side_knee.png',
  'assets/assets/companion/rig/side_shoe.png',
  'assets/assets/companion/rig/side_skirt.png',
  'assets/assets/companion/rig/side_head.png',
  'assets/assets/companion/rig/side_head_front.png',
  'assets/assets/companion/rig/side_body.png',
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
    await Promise.all(ENTRY.concat(SHELL, ENGINE).map(async (path) => {
      try {
        const res = await fetch(shellUrl(path), { cache: 'no-cache' });
        if (res.ok) await cache.put(shellUrl(path), res);
      } catch (_) {
        // Left for the runtime path below.
      }
    }));
    await self.skipWaiting();
  })());
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    for (const key of await caches.keys()) {
      if (key.startsWith('gym-') && key !== CACHE) await caches.delete(key);
    }
    await self.clients.claim();
  })());
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  if (url.origin !== self.location.origin) return;
  if (url.pathname.endsWith('/sw.js')) return;

  // The app is a single page at the scope root; any other navigation in
  // scope is left to the network.
  const root = url.origin + url.pathname === self.registration.scope ||
    url.origin + url.pathname === shellUrl('index.html');
  if (req.mode === 'navigate' && !root) return;
  const key = req.mode === 'navigate' ? shellUrl('index.html') : url.href;
  const entry = ENTRY.some((path) => key === shellUrl(path));

  event.respondWith((async () => {
    const cache = await caches.open(CACHE);
    if (entry) {
      try {
        // Revalidated with the server on every launch, so a new deploy is
        // noticed as soon as the server has it rather than when the HTTP
        // cache expires.
        const res = await fetch(key, { cache: 'no-cache' });
        if (res.ok) await cache.put(key, res.clone());
        return res;
      } catch (_) {
        const hit = await cache.match(key);
        if (hit) return hit;
        throw _;
      }
    }
    const hit = await cache.match(key);
    if (hit) return hit;
    const res = await fetch(req);
    if (res.ok && res.type === 'basic') await cache.put(key, res.clone());
    return res;
  })());
});
