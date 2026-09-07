const {test}=require('node:test');
const assert=require('node:assert/strict');
const {readFileSync}=require('node:fs');
const vm=require('node:vm');
const source=readFileSync('web/wingstar-bridge.js','utf8');
function setup(overrides={}, {storage=new Map(),requestPermission}={}) {
  const listeners=new Map();
  const callbacks=new Map(), timers=new Map();
  const navigator={userAgent:'iPhone',maxTouchPoints:1,...overrides};
  const document={hidden:false,getElementById:()=>null};
  const context={navigator,document,localStorage:{getItem:k=>storage.get(k),setItem:(k,v)=>storage.set(k,v),removeItem:k=>storage.delete(k)},Promise,Number,AbortController,
    setTimeout:cb=>{const id=timers.size+1;timers.set(id,cb);return id;},clearTimeout:id=>timers.delete(id)};
  context.window=context; context.isSecureContext=true; context.DeviceMotionEvent={requestPermission};
  context.addEventListener=(name,callback)=>{
    if(!callbacks.has(name))callbacks.set(name,new Set());callbacks.get(name).add(callback);
    listeners.set(name,event=>{for(const cb of [...callbacks.get(name)])cb(event);});
  };
  context.removeEventListener=(name,callback)=>{callbacks.get(name)?.delete(callback);if(!callbacks.get(name)?.size)listeners.delete(name);};
  document.addEventListener=context.addEventListener;
  vm.runInNewContext(source,context);
  return {bridge:context.wingstar,context,listeners,storage,timers};
}
test('sharing only exposes the canonical public link',async()=>{
  let payload;const {bridge}=setup({share:async value=>{payload=value;}});
  assert.equal(await bridge.shareLink(),'shared');
  assert.deepEqual(JSON.parse(JSON.stringify(payload)),{title:'WingStar',text:'몸과 마음을 돌보는 시간, WingStar',url:'https://wingstar-care.use-loing-ai.chatgpt.site/'});
});
test('share cancellation does not copy or send anything',async()=>{
  let copied=false;const {bridge}=setup({share:async()=>{throw {name:'AbortError'};},clipboard:{writeText:async()=>{copied=true;}}});
  assert.equal(await bridge.shareLink(),'cancelled'); assert.equal(copied,false);
});
test('unsupported share falls back to link copy',async()=>{
  let copied;const {bridge}=setup({clipboard:{writeText:async value=>{copied=value;}}});
  assert.equal(await bridge.shareLink(),'copied'); assert.equal(copied,'https://wingstar-care.use-loing-ai.chatgpt.site/');
});
test('blocked clipboard returns a manual-copy state',async()=>{
  const {bridge}=setup({clipboard:{writeText:async()=>{throw Error('denied');}}});
  assert.equal(await bridge.shareLink(),'unavailable');
});
test('iPhone motion permission is requested synchronously on the action',async()=>{
  const {bridge,context}=setup();let invoked=false;
  context.DeviceMotionEvent.requestPermission=()=>{invoked=true;return Promise.resolve('granted');};
  assert.equal(invoked,false);const pending=bridge.requestMotionAccess();assert.equal(invoked,true);assert.equal(await pending,'granted');
});
test('motion ignores absent samples and hidden pages; stop releases the listener',()=>{
  const {bridge,context,listeners}=setup();let samples=0;
  bridge.startMotion(()=>samples++);
  listeners.get('devicemotion')({accelerationIncludingGravity:{x:0,y:0,z:9.8}});
  listeners.get('devicemotion')({accelerationIncludingGravity:null});
  context.document.hidden=true;
  listeners.get('devicemotion')({accelerationIncludingGravity:{x:0,y:0,z:9.8}});
  assert.equal(samples,1);bridge.stopMotion();assert.equal(listeners.has('devicemotion'),false);
});
test('device state handles storage failure without breaking app startup',()=>{
  const {bridge,context}=setup();assert.equal(bridge.saveState('{"name":"local"}'),true);assert.equal(bridge.loadState(),'{"name":"local"}');
  context.localStorage={getItem(){throw Error();},setItem(){throw Error();}};
  assert.equal(bridge.loadState(),'');assert.equal(bridge.saveState('{}'),false);
});

test('motion shares a pending request and reuses the actual grant on reopening a course',async()=>{
  let calls=0, resolve;
  const s=setup({}, {requestPermission:()=>{calls++;return new Promise(r=>resolve=r);}});
  const first=s.bridge.requestMotionAccess(),second=s.bridge.requestMotionAccess();
  assert.equal(first,second);assert.equal(calls,1);resolve('granted');await first;
  s.bridge.startMotion(()=>{});s.bridge.stopMotion();
  assert.equal(await s.bridge.requestMotionAccess(),'granted');assert.equal(calls,1);
});

test('reload recovers an existing grant only from trusted browser sensor samples',async()=>{
  const storage=new Map([['wingstar.motion.consent.v1','granted']]);let calls=0;
  const s=setup({}, {storage,requestPermission:()=>{calls++;return Promise.resolve('granted');}});
  assert.equal(calls,0); // startup does not prompt
  s.listeners.get('devicemotion')({isTrusted:true,accelerationIncludingGravity:{x:0,y:0,z:9.8}});
  assert.equal(s.listeners.has('devicemotion'),false);
  assert.equal(await s.bridge.requestMotionAccess(),'granted');assert.equal(calls,0);
});

test('a stale saved grant or synthetic event cannot bypass Safari permission',async()=>{
  const storage=new Map([['wingstar.motion.consent.v1','granted']]);let calls=0;
  const s=setup({}, {storage,requestPermission:()=>{calls++;return Promise.resolve('denied');}});
  s.listeners.get('devicemotion')({isTrusted:false,accelerationIncludingGravity:{x:0,y:0,z:9.8}});
  assert.equal(await s.bridge.requestMotionAccess(),'denied');assert.equal(calls,1);
  assert.equal(storage.has('wingstar.motion.consent.v1'),false);
  s.context.DeviceMotionEvent.requestPermission=()=>{calls++;return Promise.resolve('granted');};
  assert.equal(await s.bridge.requestMotionAccess(),'granted');assert.equal(calls,2);
  s.bridge.resetMotionAccess();await s.bridge.requestMotionAccess();assert.equal(calls,3);
});
