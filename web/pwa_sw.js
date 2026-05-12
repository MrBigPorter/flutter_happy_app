// JoyMini PWA Service Worker
// Handles: offline fallback, asset caching, SW update lifecycle
// Note: Flutter's flutter_service_worker.js handles Flutter asset caching.
//       This SW handles the offline fallback page & app shell caching.
//       Firebase messaging uses its own scope: /firebase-cloud-messaging-push-scope

// 构建时自动注入 — 不要手动修改
// 默认值 'dev' 在未注入时也能工作
const SW_VERSION = '{{SW_VERSION}}';
const CACHE_NAME = 'joymini-shell-' + SW_VERSION;
const OFFLINE_URL = '/offline.html';
const API_HOSTS = ['api.joyminis.com'];
const IMAGE_CACHE_NAME = 'joymini-image-cache-v1';
const IMAGE_HOSTS = [self.location.hostname, 'cdn.joyminis.com'];
const IMAGE_CACHE_MAX_ENTRIES = 200;
const API_CACHE_NAME = 'joymini-api-cache-v1';
const API_CACHE_MAX_ENTRIES = 50;

// API paths safe for stale-while-revalidate caching (read-only home page data).
// Business/order/user-state APIs must remain network-only.
const SAFE_API_PREFIXES = [
    '/api/v1/home',
    '/api/v1/banners',
];

// App shell resources to pre-cache on SW install
const PRECACHE_URLS = [
    '/',
    '/offline.html',
    '/manifest.json',
    '/favicon.png',
    '/icons/Icon-192.png',
    '/icons/Icon-512.png',
    '/icons/Icon-maskable-192.png',
    '/icons/Icon-maskable-512.png',
    '/app_icon.png',
    // Flutter engine assets — pre-cache on SW install for faster second-visit cold start
    '/flutter.js',
    '/flutter_bootstrap.js',
    '/main.dart.js',
    // DEFERRED_PART_FILES_INJECT_HERE — injected by tool/inject_part_files.sh after build
];

// ── Install: pre-cache app shell + pre-fetch home page API data ───────────────
self.addEventListener('install', (event) => {
    console.log('[SW] Installing version:', SW_VERSION);
    event.waitUntil(
        caches.open(CACHE_NAME).then((cache) => {
            console.log('[SW] Pre-caching app shell');
            return cache.addAll(PRECACHE_URLS);
        }).then(() => {
            // Fire-and-forget home page API pre-fetch (don't block skipWaiting).
            // Even if prefetchHomePageAPIs() fails, SW activation proceeds.
            prefetchHomePageAPIs();
            return self.skipWaiting();
        })
    );
});

// ── Activate: clean up old caches ─────────────────────────────────────────────
self.addEventListener('activate', (event) => {
    event.waitUntil(
        caches.keys().then((cacheNames) => {
            return Promise.all(
                cacheNames
                    .filter((name) => name !== CACHE_NAME && name.startsWith('joymini-'))
                    .map((name) => {
                        console.log('[SW] Deleting old cache:', name);
                        return caches.delete(name);
                    })
            );
        }).then(() => self.clients.claim())
    );
});

// Allow index.html to tell the waiting SW to activate immediately.
self.addEventListener('message', (event) => {
    const msg = event.data;
    if (msg === 'skipWaiting' || (msg && msg.type === 'SKIP_WAITING')) {
        self.skipWaiting();
    }
});

function isImageRequest(request, url) {
    if (request.method !== 'GET') return false;
    if (!IMAGE_HOSTS.includes(url.hostname)) return false;
    const accept = request.headers.get('accept') || '';
    const looksLikeImagePath = /\.(png|jpe?g|webp|gif|avif|svg)$/i.test(url.pathname);
    return accept.includes('image/') || looksLikeImagePath;
}

async function prefetchHomePageAPIs() {
    // Phase D: Pre-fetch home page API data during SW install.
    // Flutter engine boot takes ~2-3s, so by the time the app makes API calls,
    // the responses are already in cache — even on the very first visit.
    const urls = [
        '/api/v1/banners?bannerCate=1&limit=10',
        '/api/v1/home/sections?limit=10',
    ];
    const cache = await caches.open(API_CACHE_NAME);
    await Promise.allSettled(urls.map((url) => {
        return fetch(url).then((response) => {
            if (response && response.ok) {
                cache.put(new Request(url), response);
                console.log('[SW] Pre-fetched:', url);
            }
        }).catch(() => {
            // Fail silently — app falls back to normal network request.
        });
    }));
}

async function trimCache(cacheName, maxEntries) {
    const cache = await caches.open(cacheName);
    const keys = await cache.keys();
    if (keys.length <= maxEntries) return;

    const overflow = keys.length - maxEntries;
    for (let i = 0; i < overflow; i++) {
        await cache.delete(keys[i]);
    }
}

// ── Fetch: Network-first with offline fallback ────────────────────────────────
self.addEventListener('fetch', (event) => {
    const url = new URL(event.request.url);

    // Dev environment (localhost): skip ALL custom SW handling.
    // Check self.location.hostname (the SW's own origin), not the request URL,
    // because dev API requests go to dev-api.joyminis.com (not localhost).
    if (self.location.hostname === 'localhost' || self.location.hostname === '127.0.0.1') {
        return;
    }

    // Only handle GET requests
    if (event.request.method !== 'GET') return;

    // Safe home page APIs: stale-while-revalidate for instant second-visit data load.
    if (url.hostname === self.location.hostname && !url.pathname.startsWith('/api/v1/auth') &&
        SAFE_API_PREFIXES.some((prefix) => url.pathname.startsWith(prefix))) {
        event.respondWith((async () => {
            const cache = await caches.open(API_CACHE_NAME);
            const cached = await cache.match(event.request);

            // Return cached response immediately if available (stale is fine for home page data).
            if (cached) {
                // Fire-and-forget fetch to update cache for next visit.
                fetch(event.request).then((response) => {
                    if (response && response.ok) {
                        cache.put(event.request, response.clone());
                        trimCache(API_CACHE_NAME, API_CACHE_MAX_ENTRIES);
                    }
                }).catch(() => {});
                return cached;
            }

            // No cache yet (first visit): fetch from network, cache the response.
            return fetch(event.request).then((response) => {
                if (response && response.ok) {
                    const clone = response.clone();
                    cache.put(event.request, clone);
                    trimCache(API_CACHE_NAME, API_CACHE_MAX_ENTRIES);
                }
                return response;
            }).catch(() => {
                return new Response(
                    JSON.stringify({ code: -1, message: 'offline' }),
                    {
                        status: 503,
                        headers: { 'Content-Type': 'application/json' },
                    }
                );
            });
        })());
        return;
    }

    // Business/order/user-state APIs must stay network-only.
    if (url.pathname.startsWith('/api/') || API_HOSTS.includes(url.hostname)) {
        event.respondWith(
            fetch(event.request, { cache: 'no-store' }).catch(() => {
                // Keep API fallback explicit so callers can handle offline state.
                return new Response(
                    JSON.stringify({ code: -1, message: 'offline' }),
                    {
                        status: 503,
                        headers: { 'Content-Type': 'application/json' },
                    }
                );
            })
        );
        return;
    }

    // Product/content images: stale-while-revalidate with bounded cache.
    if (isImageRequest(event.request, url)) {
        event.respondWith((async () => {
            const cache = await caches.open(IMAGE_CACHE_NAME);
            const cached = await cache.match(event.request);

            const networkPromise = fetch(event.request)
                .then((response) => {
                    if (response && response.ok) {
                        cache.put(event.request, response.clone());
                        trimCache(IMAGE_CACHE_NAME, IMAGE_CACHE_MAX_ENTRIES);
                    }
                    return response;
                })
                .catch(() => null);

            return cached || (await networkPromise) || Response.error();
        })());
        return;
    }

    // Skip cross-origin requests
    if (url.origin !== self.location.origin) return;

    // Skip Flutter's own service worker to avoid conflicts
    if (url.pathname.includes('flutter_service_worker')) return;

    // Skip Firebase messaging scope
    if (url.pathname.includes('firebase-cloud-messaging')) return;

    // For navigation requests: network-first, fallback to offline page
    if (event.request.mode === 'navigate') {
        event.respondWith(
            fetch(event.request).catch(() => {
                return caches.match(OFFLINE_URL);
            })
        );
        return;
    }

    // For icons/images in cache: cache-first
    if (
        url.pathname.startsWith('/icons/') ||
        url.pathname === '/favicon.png' ||
        url.pathname === '/app_icon.png'
    ) {
        event.respondWith(
            caches.match(event.request).then((cached) => {
                return cached || fetch(event.request).then((response) => {
                    if (response.ok) {
                        const clone = response.clone();
                        caches.open(CACHE_NAME).then((cache) => cache.put(event.request, clone));
                    }
                    return response;
                });
            })
        );
        return;
    }

    // Everything else: network-first (let Flutter's SW handle Flutter assets)
});

// ── Push Notifications (delegate to Firebase SW) ─────────────────────────────
// Firebase messaging is registered at its own scope, no handling needed here.
