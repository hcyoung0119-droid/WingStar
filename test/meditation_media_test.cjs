const {test}=require('node:test');
const assert=require('node:assert/strict');
const {readFileSync}=require('node:fs');
const vm=require('node:vm');
const source=readFileSync('web/wingstar-media.js','utf8');

function setup({storage=true,deferredResume=false,records=new Map(),preferences=new Map(),preferencesStorage=true}={}) {
  const events=new Map(), intervals=new Map();
  let input, resumes=0, stopped=0, mediaSources=0, resolveResume;
  const resumePromise=deferredResume?new Promise(resolve=>resolveResume=resolve):Promise.resolve();
  const gain={gain:{value:0,setValueAtTime(){},linearRampToValueAtTime(){},setTargetAtTime(v){this.value=v;}},connect(){},disconnect(){}};
  class FakeContext {
    currentTime=0; destination={};
    createGain(){return gain;}
    resume(){resumes++;return resumePromise;}
    createOscillator(){return {frequency:{value:0},connect(){},disconnect(){},start(){},stop(){stopped++;}};}
    createMediaElementSource(){mediaSources++;return {connect(){},disconnect(){}};}
  }
  class FakeAudio {
    loop=false;currentTime=0;
    constructor(src){this.src=src;}
    play(){this.playing=true;return Promise.resolve();}
    pause(){this.playing=false;}
    removeAttribute(){} load(){}
  }
  const db={transaction(){const tx={};tx.objectStore=()=>({
    getAll(){const req={result:[...records.values()]};queueMicrotask(()=>tx.oncomplete?.());return req;},
    put(item){records.set(item.id,item);queueMicrotask(()=>tx.oncomplete?.());return {};},
    delete(id){records.delete(id);queueMicrotask(()=>tx.oncomplete?.());return {};},
  });return tx;}};
  const indexedDB=storage?{open(){const request={result:db};queueMicrotask(()=>request.onsuccess?.());return request;}}:undefined;
  const document={hidden:false,addEventListener:(event,cb)=>events.set(event,cb),createElement(type){assert.equal(type,'input');input={click(){this.clicked=true;}};return input;}};
  const context={document,indexedDB,Audio:FakeAudio,AudioContext:FakeContext,navigator:{},crypto:{randomUUID:()=>`track-${records.size+1}`},
    localStorage:{getItem:k=>{if(!preferencesStorage)throw Error('blocked');return preferences.get(k);},setItem:(k,v)=>{if(!preferencesStorage)throw Error('blocked');preferences.set(k,v);}},
    URL:{createObjectURL:()=>'blob:private-local-track',revokeObjectURL(){}},
    setInterval:cb=>{const id=intervals.size+1;intervals.set(id,cb);return id;},clearInterval:id=>intervals.delete(id),setTimeout,clearTimeout,
    addEventListener:(event,cb)=>events.set(event,cb),Promise,Map,Number,Math};
  context.window=context;vm.runInNewContext(source,context);
  return {api:context.wingstarMedia,context,events,records,preferences,intervals,gain,get input(){return input;},get resumes(){return resumes;},get stopped(){return stopped;},get mediaSources(){return mediaSources;},resolveResume};
}
test('original sound is silent until user play; pause releases scheduled tones',async()=>{
  const s=setup();assert.equal(s.resumes,0);assert.equal(s.intervals.size,0);
  const playing=s.api.play();assert.equal(s.resumes,1); // synchronous gesture path
  assert.equal(await playing,'playing');assert.ok(s.intervals.size>0);
  s.api.pause();assert.equal(s.intervals.size,0);assert.ok(s.stopped>0);
  assert.equal(JSON.parse(s.api.state()).status,'paused');
});
test('hiding the app pauses music and notifies timer, returning does not auto-play',async()=>{
  const s=setup();let visible;s.api.setLifecycle(v=>visible=v);await s.api.play();
  s.context.document.hidden=true;s.events.get('visibilitychange')();
  assert.equal(visible,false);assert.equal(JSON.parse(s.api.state()).status,'paused');
  s.context.document.hidden=false;s.events.get('visibilitychange')();
  assert.equal(visible,true);assert.equal(JSON.parse(s.api.state()).status,'paused');
});
test('only the picked audio file is saved locally, selectable, volume controlled and removable',async()=>{
  const s=setup();s.api.pickMusic();assert.equal(s.input.clicked,true);
  const file={name:'내 명상.m4a',type:'audio/mp4',size:1200};s.input.files=[file];await s.input.onchange();
  const state=JSON.parse(s.api.state());assert.equal(state.tracks.length,2);assert.equal(s.records.size,1);
  assert.equal([...s.records.values()][0].blob,file);assert.equal(state.selected,'track-1');
  assert.equal(await s.api.play(),'playing');assert.equal(s.mediaSources,1);
  s.api.setVolume(.2);assert.equal(s.gain.gain.value,.2);
  await s.api.remove('track-1');assert.equal(s.records.size,0);assert.equal(JSON.parse(s.api.state()).selected,'wingstar-calm');
});
test('storage denial allows temporary playback and deletion; invalid files are rejected',async()=>{
  const s=setup({storage:false});s.api.pickMusic();s.input.files=[{name:'bad.exe',type:'application/octet-stream',size:2}];await s.input.onchange();
  assert.equal(JSON.parse(s.api.state()).tracks.length,1);
  s.input.files=[{name:'huge.mp3',type:'audio/mpeg',size:51*1024*1024}];await s.input.onchange();assert.equal(JSON.parse(s.api.state()).tracks.length,1);
  s.input.files=[{name:'local.mp3',type:'audio/mpeg',size:500}];await s.input.onchange();
  assert.match(JSON.parse(s.api.state()).notice,/이번 실행/);await s.api.remove('track-1');
  assert.equal(JSON.parse(s.api.state()).tracks.length,1);
});
test('an in-flight play cannot resume after pause',async()=>{
  const s=setup({deferredResume:true});const playing=s.api.play();s.api.pause();s.resolveResume();
  assert.equal(await playing,'paused');assert.equal(s.intervals.size,0);
});

test('reopening restores chosen music, volume and enabled setting without autoplay or a file prompt',async()=>{
  const s=setup();s.api.pickMusic();s.input.files=[{name:'saved.m4a',type:'audio/mp4',size:1200}];await s.input.onchange();
  s.api.setVolume(.25);s.api.setEnabled(false);
  const reopened=setup({records:s.records,preferences:s.preferences});await new Promise(setImmediate);
  const state=JSON.parse(reopened.api.state());
  assert.equal(state.selected,'track-1');assert.equal(state.volume,.25);assert.equal(state.enabled,false);
  assert.equal(reopened.resumes,0);assert.equal(reopened.input,undefined);assert.equal(state.status,'stopped');
});

test('missing files, malformed preferences and blocked storage keep startup usable',async()=>{
  const missing=setup({preferences:new Map([['wingstar.music.preferences.v1','{"selected":"missing","volume":5}']])});
  await new Promise(setImmediate);assert.equal(JSON.parse(missing.api.state()).selected,'wingstar-calm');assert.equal(JSON.parse(missing.api.state()).volume,1);
  const malformed=setup({preferences:new Map([['wingstar.music.preferences.v1','broken']])});assert.equal(JSON.parse(malformed.api.state()).volume,.45);
  const blocked=setup({preferencesStorage:false});blocked.api.setEnabled(false);assert.match(JSON.parse(blocked.api.state()).notice,/이번 실행/);
});
