import {test} from 'node:test';
import assert from 'node:assert/strict';
import vm from 'node:vm';
import {readFileSync} from 'node:fs';
import {webcrypto} from 'node:crypto';

const source=readFileSync('web/wingstar-social.js','utf8');
const account=id=>({configured:true,authenticated:true,me:{id,nickname:id},friends:[],incoming:[],outgoing:[]});
function setup({storage=new Map(),state=account('WS-AAAAAAAAAA'),activity=()=>({ok:true})}={}) {
  const calls=[],intervals=[],events={};let reloads=0,replaced='',offline=false;
  const context={Date,AbortController,crypto:webcrypto,setTimeout,clearTimeout,
    setInterval:fn=>{intervals.push(fn);return intervals.length;},
    localStorage:{getItem:k=>storage.get(k)||null,setItem:(k,v)=>storage.set(k,v)},
    navigator:{clipboard:{writeText:async()=>{}}},
    location:{reload:()=>reloads++,assign:()=>{},replace:url=>{replaced=url;}},
    document:{hidden:false,addEventListener:(name,fn)=>{events[name]=fn;}},
    addEventListener:(name,fn)=>{events[name]=fn;},
    async fetch(url,options){
      if(offline)throw Error('offline');
      const path=url.replace('/api/social/','');const payload=options.body?JSON.parse(options.body):undefined;
      calls.push({path,options,payload});let body;
      if(path==='state')body=state;
      else if(path==='activity')body=await activity(payload,options);
      else if(path.startsWith('rankings'))body={rows:[],me:null,week:'2026-09-07',today:'2026-09-07'};
      else body={ok:true};
      return {ok:!body.status,status:body.status||200,json:async()=>body};
    },
  };
  context.window=context;vm.runInNewContext(source,context);
  return {api:context.wingstarSocial,storage,calls,events,flush:()=>intervals[0](),
    set state(value){state=value;},set offline(value){offline=value;},
    get reloads(){return reloads;},get replaced(){return replaced;}};
}

test('first login preserves local records; logout and another account use separate records and music',async()=>{
  const storage=new Map([['wingstar.device.v1','{"name":"private A","journals":["secret"]}']]);
  const a=setup({storage});await a.api.boot();
  assert.equal(storage.get(a.api.storageKey),storage.get('wingstar.device.v1'));
  assert.equal(a.api.storageSuffix,'');
  await a.api.action('logout');assert.equal(a.replaced,'/?ranking=1');
  const guest=setup({storage,state:{configured:true,authenticated:false}});await guest.api.boot();
  assert.equal(storage.get(guest.api.storageKey),undefined);assert.equal(guest.api.storageSuffix,':guest');
  const b=setup({storage,state:account('WS-BBBBBBBBBB')});await b.api.boot();
  assert.notEqual(a.api.storageKey,b.api.storageKey);assert.equal(storage.get(b.api.storageKey),undefined);
  assert.equal(b.api.storageSuffix,':WS-BBBBBBBBBB');
  assert.equal(b.calls.some(v=>v.options.body?.includes('secret')),false);
});

test('offline batches survive restart and lost responses retry the same ID without losing new steps',async()=>{
  const storage=new Map();let fail=true;
  const a=setup({storage,activity:()=>{if(fail)throw Error('response lost');return {ok:true};}});
  await a.api.boot();a.api.recordSteps(12);await a.flush();
  const first=a.calls.find(v=>v.path==='activity').payload;
  a.api.recordSteps(8);
  assert.equal(JSON.parse(a.api.state()).pendingSteps,20);
  const retry=setup({storage});await retry.api.boot();await retry.flush();
  const posts=retry.calls.filter(v=>v.path==='activity');
  assert.deepEqual(posts.map(v=>v.payload.steps),[12,8]);assert.equal(posts[0].payload.id,first.id);
  assert.notEqual(posts[0].payload.id,posts[1].payload.id);
  assert.equal(JSON.parse(retry.api.state()).pendingSteps,0);
  assert.equal(posts[0].options.headers['X-WingStar-Account'],'WS-AAAAAAAAAA');
});

test('a different cookie account cannot consume an old account queue',async()=>{
  const a=setup({activity:()=>({status:409,code:'ACCOUNT_CHANGED',message:'account changed'})});
  await a.api.boot();a.api.recordSteps(45);await a.flush();
  assert.equal(a.reloads,1);assert.equal(JSON.parse(a.api.state()).pendingSteps,45);
  assert.equal(JSON.parse(a.storage.get('wingstar.social.pending:WS-AAAAAAAAAA'))[0].steps,45);
  a.state=account('WS-BBBBBBBBBB');await a.api.action('refresh');
  assert.equal(a.reloads,2);assert.equal(JSON.parse(a.api.state()).me.id,'WS-AAAAAAAAAA');
});

test('anonymous and offline launches never invent an identity or upload private records',async()=>{
  const a=setup({state:{configured:false,authenticated:false}});await a.api.boot();
  a.api.recordSteps(30);await a.flush();assert.equal(a.calls.filter(v=>v.path==='activity').length,0);
  assert.equal(JSON.parse(a.api.state()).authenticated,false);
  const storage=new Map([['wingstar.social.firstOwner','WS-AAAAAAAAAA'],['wingstar.social.lastOwner','WS-AAAAAAAAAA'],
    ['wingstar.social.pending:WS-AAAAAAAAAA',JSON.stringify([{id:webcrypto.randomUUID(),steps:23,at:Date.now()}])]]);
  const offline=setup({storage});offline.offline=true;await offline.api.boot();
  assert.equal(offline.api.storageKey,'wingstar.device.v1:WS-AAAAAAAAAA');
  assert.equal(JSON.parse(offline.api.state()).authenticated,false);
  offline.offline=false;await offline.api.action('refresh');
  assert.equal(offline.reloads,0);assert.equal(JSON.parse(offline.api.state()).authenticated,true);
  assert.equal(offline.calls.find(v=>v.path==='activity').payload.steps,23);
});

test('invalid measurements never enter the upload queue',async()=>{
  const a=setup();await a.api.boot();
  for(const steps of [0,-1,NaN,Infinity,0.5,10001,'3'])a.api.recordSteps(steps);
  await a.flush();assert.equal(a.calls.filter(v=>v.path==='activity').length,0);
});
