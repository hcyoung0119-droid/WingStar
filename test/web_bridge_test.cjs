const {test}=require('node:test');
const assert=require('node:assert/strict');
const {readFileSync}=require('node:fs');
const vm=require('node:vm');
const source=readFileSync('web/wingstar-bridge.js','utf8');
function setup(overrides={}) {
  const listeners=new Map();
  const storage=new Map();
  const navigator={userAgent:'iPhone',maxTouchPoints:1,...overrides};
  const document={hidden:false,getElementById:()=>null};
  const context={navigator,document,localStorage:{getItem:k=>storage.get(k),setItem:(k,v)=>storage.set(k,v)},Promise,Number,AbortController};
  context.window=context; context.isSecureContext=true; context.DeviceMotionEvent={};
  context.addEventListener=(name,callback)=>listeners.set(name,callback);
  context.removeEventListener=(name,callback)=>{if(listeners.get(name)===callback)listeners.delete(name);};
  vm.runInNewContext(source,context);
  return {bridge:context.wingstar,context,listeners};
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
