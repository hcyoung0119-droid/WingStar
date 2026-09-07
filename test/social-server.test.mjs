import {test} from 'node:test';
import assert from 'node:assert/strict';
import {DatabaseSync} from 'node:sqlite';
import {readFileSync} from 'node:fs';
import {generateKeyPair,exportJWK,createLocalJWKSet,SignJWT} from 'jose';
import {createSocialApi,period} from '../server/social/api.mjs';
import {ORIGIN,verifyGoogleIdentity,SESSION_COOKIE,NONCE_COOKIE} from '../server/social/auth.mjs';

class TestD1 {
  constructor(){this.sqlite=new DatabaseSync(':memory:');this.sqlite.exec('PRAGMA foreign_keys=ON;');this.sqlite.exec(readFileSync('drizzle/0000_magical_doctor_faustus.sql','utf8'));}
  prepare(sql){
    const db=this.sqlite,args=[];
    return {bind(...values){args.push(...values);return this;},
      async first(){return db.prepare(sql).get(...args)||null;},
      async all(){return {results:db.prepare(sql).all(...args)};},
      async run(){const result=db.prepare(sql).run(...args);return {meta:{changes:Number(result.changes)}};},
    };
  }
  async batch(statements){this.sqlite.exec('BEGIN');try{const result=[];for(const statement of statements)result.push(await statement.run());this.sqlite.exec('COMMIT');return result;}catch(error){this.sqlite.exec('ROLLBACK');throw error;}}
  close(){this.sqlite.close();}
}
const clientId='wingstar-test.apps.googleusercontent.com';
const {privateKey,publicKey}=await generateKeyPair('RS256');
const jwk=await exportJWK(publicKey);jwk.kid='test-key';
const keySet=createLocalJWKSet({keys:[jwk]});
async function token(subject,nonce,{audience=clientId,issuer='https://accounts.google.com',expires='1h'}={}){
  return new SignJWT({nonce}).setProtectedHeader({alg:'RS256',kid:'test-key'}).setSubject(subject).setIssuer(issuer).setAudience(audience).setIssuedAt().setExpirationTime(expires).sign(privateKey);
}
function fixture(){
  const env={DB:new TestD1(),GOOGLE_CLIENT_ID:clientId};let now=Date.now();
  const accounts=new Map();
  const api=createSocialApi({verifyIdentity:(token,id,nonce)=>verifyGoogleIdentity(token,id,nonce,keySet),clock:()=>now});
  async function call(path,{method='GET',payload,cookie='',origin=ORIGIN,account=accounts.get(cookie)||''}={}){
    const response=await api(new Request(ORIGIN+'/api/social/'+path,{method,headers:{'Content-Type':'application/json','Origin':origin,'X-WingStar-Request':'1','X-WingStar-Account':account,'Cookie':cookie},body:payload===undefined?undefined:JSON.stringify(payload)}),env);
    return {status:response.status,body:await response.json(),headers:response.headers};
  }
  async function login(subject){
    const challenge=await call('auth/challenge',{method:'POST'});assert.equal(challenge.status,200);
    const nonce=challenge.body.nonce,credential=await token(subject,nonce);
    const response=await call('auth/google',{method:'POST',payload:{credential},cookie:NONCE_COOKIE+'='+nonce});assert.equal(response.status,200);
    const session=response.headers.getSetCookie().find(v=>v.startsWith(SESSION_COOKIE+'=')).split(';')[0];
    accounts.set(session,response.body.me.id);
    assert.match(response.headers.getSetCookie().find(v=>v.startsWith(SESSION_COOKIE+'=')),/Secure; HttpOnly; SameSite=Lax/);
    return {cookie:session,me:response.body.me,nonce,credential};
  }
  return {env,call,login,get now(){return now;},set now(value){now=value;},close:()=>env.DB.close()};
}

test('Google signatures, audience, issuer, expiry and nonce are verified',async()=>{
  const valid=await token('google-user','expected');assert.equal(await verifyGoogleIdentity(valid,clientId,'expected',keySet),'google:google-user');
  for(const candidate of [await token('user','wrong'),await token('user','expected',{audience:'another-client'}),await token('user','expected',{issuer:'https://attacker.example'}),await token('user','expected',{expires:'-1h'}),valid.slice(0,-10)+'AAAAAAAAAA'])
    await assert.rejects(()=>verifyGoogleIdentity(candidate,clientId,'expected',keySet));
});

test('one Google account keeps one unique public ID and sessions are HttpOnly and revocable',async()=>{
  const f=fixture();try{
    const first=await f.login('first'),again=await f.login('first'),second=await f.login('second');
    assert.equal(first.me.id,again.me.id);assert.notEqual(first.me.id,second.me.id);assert.match(first.me.id,/^WS-[A-HJ-NP-Z2-9]{10}$/);
    const state=await f.call('state',{cookie:first.cookie});assert.equal(state.body.authenticated,true);assert.equal(state.body.me.publicRanking,false);
    assert.equal(JSON.stringify(state.body).includes('google:first'),false);
    const replay=await f.call('auth/google',{method:'POST',cookie:NONCE_COOKIE+'='+first.nonce,payload:{credential:first.credential}});assert.equal(replay.status,401);
    assert.equal((await f.call('rankings')).status,401);
    assert.equal((await f.call('profile',{method:'PATCH',cookie:first.cookie,payload:{},origin:'https://attacker.example'})).status,403);
    assert.equal((await f.call('activity',{method:'POST',cookie:second.cookie,account:first.me.id,payload:{id:crypto.randomUUID(),steps:100,at:f.now}})).body.code,'ACCOUNT_CHANGED');
    assert.equal((await f.call('auth/logout',{method:'POST',cookie:first.cookie,payload:{}})).status,200);
    assert.equal((await f.call('state',{cookie:first.cookie})).body.authenticated,false);
    f.now+=31*86400000;assert.equal((await f.call('state',{cookie:again.cookie})).body.authenticated,false);
    const stored=f.env.DB.sqlite.prepare('SELECT * FROM social_sessions LIMIT 1').get();assert.notEqual(stored.token_hash,again.cookie.split('=')[1]);
  }finally{f.close();}
});

test('friend requests require recipient acceptance, remain isolated and can be cancelled or removed',async()=>{
  const f=fixture();try{
    const a=await f.login('a'),b=await f.login('b'),c=await f.login('c');
    assert.equal((await f.call('friends/request',{method:'POST',cookie:a.cookie,payload:{id:a.me.id}})).status,400);
    assert.equal((await f.call('search?id='+b.me.id,{cookie:a.cookie})).body.relationship,'none');
    for(let i=0;i<2;i++)assert.equal((await f.call('friends/request',{method:'POST',cookie:a.cookie,payload:{id:b.me.id}})).status,200);
    assert.equal((await f.call('state',{cookie:b.cookie})).body.incoming.length,1);
    assert.equal((await f.call('state',{cookie:b.cookie})).body.friends.length,0);
    assert.equal((await f.call('state',{cookie:c.cookie})).body.incoming.length,0);
    assert.equal((await f.call('friends/respond',{method:'POST',cookie:a.cookie,payload:{id:b.me.id,action:'accept'}})).status,409);
    assert.equal((await f.call('friends/respond',{method:'POST',cookie:c.cookie,payload:{id:a.me.id,action:'accept'}})).status,409);
    assert.equal((await f.call('friends/respond',{method:'POST',cookie:b.cookie,payload:{id:a.me.id,action:'accept'}})).status,200);
    assert.equal((await f.call('state',{cookie:a.cookie})).body.friends[0].id,b.me.id);
    assert.equal((await f.call('state',{cookie:b.cookie})).body.friends[0].id,a.me.id);
    assert.equal((await f.call('cheer',{method:'POST',cookie:a.cookie,payload:{id:b.me.id}})).body.created,true);
    assert.equal((await f.call('cheer',{method:'POST',cookie:a.cookie,payload:{id:b.me.id}})).body.created,false);
    assert.equal((await f.call('state',{cookie:b.cookie})).body.receivedCheers,1);
    assert.equal((await f.call('friends/remove',{method:'POST',cookie:c.cookie,payload:{id:a.me.id}})).status,200);
    assert.equal((await f.call('state',{cookie:a.cookie})).body.friends.length,1);
    await f.call('friends/remove',{method:'POST',cookie:b.cookie,payload:{id:a.me.id}});
    assert.equal((await f.call('state',{cookie:a.cookie})).body.friends.length,0);
    await f.call('friends/request',{method:'POST',cookie:a.cookie,payload:{id:b.me.id}});
    await f.call('friends/remove',{method:'POST',cookie:a.cookie,payload:{id:b.me.id}});
    assert.equal((await f.call('state',{cookie:b.cookie})).body.incoming.length,0);
  }finally{f.close();}
});

test('weekly rankings use durable idempotent activity, accepted friends and explicit global participation',async()=>{
  const f=fixture();try{
    const a=await f.login('a'),b=await f.login('b'),c=await f.login('c');
    await f.call('friends/request',{method:'POST',cookie:a.cookie,payload:{id:b.me.id}});
    const batch={id:crypto.randomUUID(),steps:71,at:f.now};
    for(let i=0;i<2;i++)assert.equal((await f.call('activity',{method:'POST',cookie:a.cookie,payload:batch})).status,200);
    assert.equal((await f.call('activity',{method:'POST',cookie:c.cookie,payload:batch})).status,409);
    assert.equal((await f.call('activity',{method:'POST',cookie:a.cookie,payload:{...batch,id:crypto.randomUUID(),steps:-1}})).status,400);
    await f.call('activity',{method:'POST',cookie:b.cookie,payload:{id:crypto.randomUUID(),steps:150,at:f.now}});
    let board=await f.call('rankings?scope=friends',{cookie:a.cookie});assert.equal(board.body.rows.length,1);assert.equal(board.body.rows[0].steps,71);
    await f.call('friends/respond',{method:'POST',cookie:b.cookie,payload:{id:a.me.id,action:'accept'}});
    board=await f.call('rankings?scope=friends',{cookie:a.cookie});assert.equal(board.body.rows.length,2);assert.equal(board.body.rows[0].public_id,b.me.id);assert.equal(board.body.me.rank,2);
    assert.equal((await f.call('rankings?scope=all',{cookie:a.cookie})).body.rows.length,0);
    await f.call('profile',{method:'PATCH',cookie:a.cookie,payload:{nickname:'산책 친구',accent:'mint',badge:'leaf',publicRanking:true}});
    board=await f.call('rankings?scope=all',{cookie:c.cookie});assert.equal(board.body.rows.length,1);assert.equal(board.body.rows[0].nickname,'산책 친구');
    assert.equal(board.body.me,null);
    await f.call('profile',{method:'PATCH',cookie:a.cookie,payload:{nickname:'산책 친구',accent:'mint',badge:'leaf',publicRanking:false}});
    assert.equal((await f.call('rankings?scope=all',{cookie:c.cookie})).body.rows.length,0);
    f.now+=7*86400000;board=await f.call('rankings?scope=friends',{cookie:a.cookie});assert.equal(board.body.me.steps,0);
    assert.equal(f.env.DB.sqlite.prepare('SELECT SUM(steps) n FROM social_activity_batches').get().n,221);
  }finally{f.close();}
});

test('Monday boundaries use Korea time and missing Google configuration is an honest inactive state',async()=>{
  assert.equal(period(Date.parse('2026-09-06T14:59:59Z')).week,'2026-08-31');
  assert.equal(period(Date.parse('2026-09-06T15:00:00Z')).week,'2026-09-07');
  const f=fixture();try{delete f.env.GOOGLE_CLIENT_ID;
    assert.deepEqual((await f.call('state')).body,{configured:false,testing:true,authenticated:false});
    assert.equal((await f.call('auth/challenge',{method:'POST'})).status,503);
  }finally{f.close();}
});
