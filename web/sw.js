const CACHE='wingstar-v3';
const SHELL=['/','/index.html','/manifest.json','/wingstar-bridge.js','/flutter_bootstrap.js','/main.dart.js','/icons/Icon-192.png','/icons/Icon-512.png'];
self.addEventListener('install',event=>event.waitUntil(caches.open(CACHE).then(cache=>cache.addAll(SHELL))));
self.addEventListener('activate',event=>event.waitUntil(caches.keys().then(keys=>Promise.all(keys.filter(k=>k.startsWith('wingstar-')&&k!==CACHE).map(k=>caches.delete(k)))).then(()=>self.clients.claim())));
self.addEventListener('fetch',event=>{
  const url=new URL(event.request.url);
  if(event.request.method!=='GET'||url.origin!==self.location.origin||url.search||url.pathname.startsWith('/__'))return;
  // Only cache known Flutter assets. Never cache checkout, auth, receipts or APIs.
  const asset=SHELL.includes(url.pathname)||/^\/(assets|canvaskit|icons)\//.test(url.pathname);
  if(!asset)return;
  event.respondWith(fetch(event.request).then(response=>{
    if(response.ok && response.type==='basic') {const copy=response.clone();event.waitUntil(caches.open(CACHE).then(cache=>cache.put(event.request,copy)));}
    return response;
  }).catch(()=>caches.match(event.request).then(cached=>cached||(event.request.mode==='navigate'?caches.match('/index.html'):Response.error()))));
});
