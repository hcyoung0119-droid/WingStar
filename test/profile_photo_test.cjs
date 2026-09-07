const {test}=require('node:test');
const assert=require('node:assert/strict');
const {readFileSync}=require('node:fs');
const vm=require('node:vm');
const source=readFileSync('web/wingstar-profile.js','utf8');
function setup({decode=true}={}) {
  let input, drawn, revoked=0, removed=0, encoded=0, image;
  const canvas={getContext:()=>({fillRect(){},drawImage(...args){drawn=args;}}),toDataURL(type,quality){encoded++;assert.equal(type,'image/jpeg');assert.equal(quality,.86);return 'data:image/jpeg;base64,/9j/';}};
  const context={Promise,JSON,URL:{createObjectURL:()=>'blob:chosen-photo',revokeObjectURL(){revoked++;}},
    document:{body:{appendChild(){}},createElement(type){if(type==='canvas')return canvas;input={style:{},click(){this.clicked=true;},remove(){removed++;}};return input;}},
    Image:class {naturalWidth=1200;naturalHeight=800;constructor(){image=this;}set src(value){this.url=value;queueMicrotask(()=>decode?this.onload():this.onerror());}},
  };
  context.window=context;vm.runInNewContext(source,context);
  return {api:context.wingstarProfile,canvas,get input(){return input;},get drawn(){return drawn;},get revoked(){return revoked;},get removed(){return removed;},get encoded(){return encoded;},get image(){return image;}};
}
test('photo picker opens only on action and imports a small cropped JPEG without metadata',async()=>{
  const s=setup();assert.equal(s.input,undefined);
  const result=s.api.pickPhoto();assert.equal(s.input.clicked,true);
  assert.equal(s.api.pickPhoto(),result);
  s.input.files=[{type:'image/jpeg',size:10000}];s.input.onchange();
  assert.equal(JSON.parse(await result).photo,'data:image/jpeg;base64,/9j/');
  assert.deepEqual(s.drawn.slice(1),[200,0,800,800,0,0,512,512]);
  assert.equal(s.canvas.width,512);assert.equal(s.canvas.height,512);
  assert.equal(s.revoked,1);assert.equal(s.removed,1);assert.equal(s.encoded,1);
});
test('cancel releases the picker so another photo can be selected',async()=>{
  const s=setup();const first=s.api.pickPhoto();s.input.oncancel();
  assert.equal(JSON.parse(await first).cancelled,true);
  const next=s.api.pickPhoto();s.input.files=[];s.input.onchange();
  assert.equal(JSON.parse(await next).cancelled,true);assert.equal(s.removed,2);
});
test('invalid, oversized or undecodable images leave the profile unchanged',async()=>{
  for(const file of [{type:'image/svg+xml',size:100},{type:'image/jpeg',size:11*1024*1024},{type:'image/png',size:0}]){
    const s=setup();const pending=s.api.pickPhoto();s.input.files=[file];s.input.onchange();
    assert.ok(JSON.parse(await pending).error);assert.equal(s.encoded,0);
  }
  const s=setup({decode:false});const pending=s.api.pickPhoto();s.input.files=[{type:'image/heic',size:100}];s.input.onchange();
  assert.ok(JSON.parse(await pending).error);assert.equal(s.revoked,1);assert.equal(s.removed,1);
});
