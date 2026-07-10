/* TipLog Service Worker v1.1.16
 * Zweck: App-Shell offline verfügbar machen (Kaltstart ohne Netz).
 * Strategie: Network-first mit Cache-Fallback → online immer die
 * neueste Version, offline die zuletzt geladene.
 * WICHTIG: Bei jedem Release die CACHE-Konstante mit hochzählen,
 * damit alte Versionen sauber ersetzt werden.
 */
const CACHE = 'tiplog-v1.1.16';

self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE)
      .then(c => c.addAll(['./', './index.html', './manifest.json']))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', e => {
  if (e.request.method !== 'GET') return;
  const url = new URL(e.request.url);
  if (url.origin !== location.origin) return; // Supabase-Calls NIE cachen
  e.respondWith(
    fetch(e.request)
      .then(res => {
        const copy = res.clone();
        caches.open(CACHE).then(c => c.put(e.request, copy));
        return res;
      })
      .catch(() =>
        caches.match(e.request).then(m => m || caches.match('./index.html'))
      )
  );
});
