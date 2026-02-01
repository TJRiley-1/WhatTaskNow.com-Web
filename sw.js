// Service Worker for What Now? PWA
const CACHE_NAME = 'whatnow-com-v2';
const ASSETS = [
    '/',
    '/index.html',
    '/css/style.css',
    '/js/storage.js',
    '/js/supabase.js',
    '/js/app.js',
    '/manifest.json',
    '/icons/icon.svg'
];

// Install - cache assets
self.addEventListener('install', (event) => {
    event.waitUntil(
        caches.open(CACHE_NAME)
            .then((cache) => cache.addAll(ASSETS))
            .then(() => self.skipWaiting())
    );
});

// Activate - clean old caches
self.addEventListener('activate', (event) => {
    event.waitUntil(
        caches.keys()
            .then((keys) => Promise.all(
                keys.filter((key) => key !== CACHE_NAME)
                    .map((key) => caches.delete(key))
            ))
            .then(() => self.clients.claim())
    );
});

// Fetch - serve from cache, fallback to network
self.addEventListener('fetch', (event) => {
    event.respondWith(
        caches.match(event.request)
            .then((response) => response || fetch(event.request))
            .catch(() => {
                // Offline fallback for navigation
                if (event.request.mode === 'navigate') {
                    return caches.match('/index.html');
                }
            })
    );
});
