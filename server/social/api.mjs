import {ORIGIN, SESSION_COOKIE, NONCE_COOKIE, configured, randomToken, hash, cookie, setCookie, verifyGoogleIdentity, loginPage} from './auth.mjs';
import {privacyPage} from './privacy.mjs';
class ApiError extends Error { constructor(status,message){super(message);this.status=status;} }
const fail=(status,message)=>{throw new ApiError(status,message);};
const json=(data,status=200,extra={})=>new Response(JSON.stringify(data),{status,headers:{'Content-Type':'application/json; charset=utf-8','Cache-Control':'no-store','X-Content-Type-Options':'nosniff',...extra}});
const db = env => { if(!env.DB) fail(503,'친구 서비스를 준비하고 있어요.');return env.DB; };
const statement = (env,sql,args=[]) => db(env).prepare(sql).bind(...args);
const first=(env,sql,args=[])=>statement(env,sql,args).first();
const rows=async(env,sql,args=[]) => (await statement(env,sql,args).all()).results;
const run=(env,sql,args=[])=>statement(env,sql,args).run();
export function period(now=Date.now()) {
  const date=new Date(now+9*3600000), today=date.toISOString().slice(0,10);
  date.setUTCDate(date.getUTCDate()-((date.getUTCDay()+6)%7));
  return {today,week:date.toISOString().slice(0,10)};
}
const publicUser=u=>({id:u.public_id,nickname:u.nickname,accent:u.accent,badge:u.badge,publicRanking:!!u.public_ranking});
async function body(request) {
  if(!request.headers.get('content-type')?.startsWith('application/json')) fail(415,'요청 형식을 확인해 주세요.');
  const reader=request.body?.getReader();if(!reader)fail(400,'입력값이 없어요.');
  const chunks=[];let size=0;
  while(true){const {value,done}=await reader.read();if(done)break;size+=value.length;if(size>32768){await reader.cancel();fail(413,'요청이 너무 커요.');}chunks.push(value);}
  try{const bytes=new Uint8Array(size);let offset=0;for(const part of chunks){bytes.set(part,offset);offset+=part.length;}const result=JSON.parse(new TextDecoder().decode(bytes));if(!result||Array.isArray(result)||typeof result!=='object')throw Error();return result;}
  catch{fail(400,'입력값을 확인해 주세요.');}
}
async function currentUser(request,env,now) {
  const token=cookie(request,SESSION_COOKIE);if(!/^[a-f0-9]{64}$/.test(token))return null;
  return first(env,`SELECT u.* FROM social_sessions s JOIN social_users u ON u.id=s.user_id WHERE s.token_hash=? AND s.expires_at>?`,[await hash(token),now]);
}
function publicCode(){const alphabet='ABCDEFGHJKLMNPQRSTUVWXYZ23456789';return 'WS-'+[...crypto.getRandomValues(new Uint8Array(10))].map(v=>alphabet[v%32]).join('');}
async function findOrCreateUser(env,subject,now) {
  let user=await first(env,'SELECT * FROM social_users WHERE subject=?',[subject]);if(user)return user;
  for(let i=0;i<4;i++){
    const code=publicCode();
    await run(env,'INSERT OR IGNORE INTO social_users(id,subject,public_id,nickname,accent,badge,public_ranking,created_at) VALUES(?,?,?,?,?,?,0,?)',[crypto.randomUUID(),subject,code,'윙스타 '+code.slice(-4),'sky','leaf',now]);
    user=await first(env,'SELECT * FROM social_users WHERE subject=?',[subject]);if(user)return user;
  }
  fail(503,'아이디를 만들지 못했어요. 다시 시도해 주세요.');
}
async function otherUser(env,code) {
  if(typeof code!=='string'||!/^WS-[A-HJ-NP-Z2-9]{10}$/.test(code))fail(400,'친구 아이디를 정확히 입력해 주세요.');
  const user=await first(env,'SELECT * FROM social_users WHERE public_id=?',[code]);if(!user)fail(404,'해당 아이디를 찾지 못했어요.');return user;
}
const pair=(a,b)=>a<b?[a,b]:[b,a];
async function relation(env,a,b){return first(env,'SELECT * FROM social_friendships WHERE user_low=? AND user_high=?',pair(a,b));}
async function friendState(env,user,now){
  const connections=await rows(env,`SELECT u.public_id,u.nickname,u.accent,u.badge,f.requested_by,f.status FROM social_friendships f JOIN social_users u ON u.id=CASE WHEN f.user_low=? THEN f.user_high ELSE f.user_low END WHERE f.user_low=? OR f.user_high=? ORDER BY u.nickname,u.public_id`,[user.id,user.id,user.id]);
  const {today,week}=period(now);
  const cheers=await first(env,'SELECT COUNT(*) AS n FROM social_cheers WHERE to_user=? AND day=?',[user.id,today]);
  return {configured:configured(env),testing:env.GOOGLE_AUTH_STAGE!=='production',authenticated:true,me:publicUser(user),today,week,receivedCheers:cheers.n,
    friends:connections.filter(v=>v.status==='accepted').map(publicUser),
    incoming:connections.filter(v=>v.status==='pending'&&v.requested_by!==user.id).map(publicUser),
    outgoing:connections.filter(v=>v.status==='pending'&&v.requested_by===user.id).map(publicUser)};
}
async function rankings(env,user,scope,now){
  const {today,week}=period(now);
  const filter=scope==='all'?'u.public_ranking=1':`(u.id=? OR u.id IN (SELECT CASE WHEN user_low=? THEN user_high ELSE user_low END FROM social_friendships WHERE (user_low=? OR user_high=?) AND status='accepted'))`;
  const args=[week,today,...(scope==='all'?[]:[user.id,user.id,user.id,user.id])];
  const query=`WITH totals AS (SELECT u.public_id,u.nickname,u.accent,u.badge,COALESCE(SUM(a.steps),0) AS steps FROM social_users u LEFT JOIN social_activity_batches a ON a.user_id=u.id AND a.day>=? AND a.day<=? WHERE ${filter} GROUP BY u.id), ranked AS (SELECT *,DENSE_RANK() OVER (ORDER BY steps DESC) AS rank FROM totals)`;
  const list=await rows(env,query+' SELECT * FROM ranked ORDER BY rank,public_id LIMIT 100',args);
  const mine=await first(env,query+' SELECT * FROM ranked WHERE public_id=?',[...args,user.public_id]);
  return {scope,week,today,rows:list,me:mine};
}

export function createSocialApi({verifyIdentity=verifyGoogleIdentity,clock=()=>Date.now()}={}) {
  return async function handle(request,env) {
    const url=new URL(request.url), path=url.pathname, now=clock();
    if(path==='/privacy')return new Response(privacyPage(env),{headers:{'Content-Type':'text/html; charset=utf-8','Cache-Control':'no-store','X-Content-Type-Options':'nosniff'}});
    if(path==='/account/sign-in') {
      if(!configured(env))return new Response('<!doctype html><html lang="ko"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>WingStar 로그인 준비 중</title><body style="font:16px system-ui;padding:32px;background:#eef8ff"><h1>구글 로그인 연결 준비 중</h1><p>걷기 명상은 계속 이용할 수 있어요.</p><a href="/?ranking=1">앱으로 돌아가기</a></body></html>',{headers:{'Content-Type':'text/html; charset=utf-8','Cache-Control':'no-store'}});
      return new Response(loginPage(env.GOOGLE_CLIENT_ID,env.GOOGLE_AUTH_STAGE!=='production'),{headers:{'Content-Type':'text/html; charset=utf-8','Cache-Control':'no-store','Referrer-Policy':'strict-origin-when-cross-origin','Cross-Origin-Opener-Policy':'same-origin-allow-popups'}});
    }
    if(!path.startsWith('/api/social/'))return null;
    try {
      if(!['GET','POST','PATCH','DELETE'].includes(request.method))fail(405,'지원하지 않는 요청이에요.');
      if(request.method!=='GET' && (request.headers.get('origin')!==ORIGIN || request.headers.get('x-wingstar-request')!=='1'))fail(403,'앱에서 다시 시도해 주세요.');
      if(path==='/api/social/auth/challenge'&&request.method==='POST'){
        if(!configured(env))fail(503,'구글 로그인 연결을 준비하고 있어요.');
        const nonce=randomToken();
        await db(env).batch([
          statement(env,'DELETE FROM social_login_challenges WHERE expires_at<?',[now]),
          statement(env,'INSERT INTO social_login_challenges(nonce_hash,expires_at) VALUES(?,?)',[await hash(nonce),now+600000]),
        ]);
        return json({nonce},200,{'Set-Cookie':setCookie(NONCE_COOKIE,nonce,600)});
      }
      if(path==='/api/social/auth/google'&&request.method==='POST'){
        if(!configured(env))fail(503,'구글 로그인 연결을 준비하고 있어요.');
        const input=await body(request),nonce=cookie(request,NONCE_COOKIE);
        if(typeof input.credential!=='string'||input.credential.length>16000||!/^[a-f0-9]{64}$/.test(nonce))fail(401,'로그인을 다시 시작해 주세요.');
        let subject;try{subject=await verifyIdentity(input.credential,env.GOOGLE_CLIENT_ID,nonce);}catch{fail(401,'구글 계정을 확인하지 못했어요. 다시 로그인해 주세요.');}
        const used=await first(env,'DELETE FROM social_login_challenges WHERE nonce_hash=? AND expires_at>? RETURNING nonce_hash',[await hash(nonce),now]);
        if(!used)fail(401,'로그인 요청이 만료됐어요. 다시 시작해 주세요.');
        const user=await findOrCreateUser(env,subject,now),token=randomToken();
        await db(env).batch([
          statement(env,'DELETE FROM social_sessions WHERE expires_at<?',[now]),
          statement(env,'INSERT INTO social_sessions(token_hash,user_id,expires_at) VALUES(?,?,?)',[await hash(token),user.id,now+30*86400000]),
        ]);
        const response=json({me:publicUser(user)});
        response.headers.append('Set-Cookie',setCookie(SESSION_COOKIE,token,30*86400));
        response.headers.append('Set-Cookie',setCookie(NONCE_COOKIE,'',0));return response;
      }
      const user=await currentUser(request,env,now);
      if(path==='/api/social/state'&&request.method==='GET')return user?json(await friendState(env,user,now)):json({configured:configured(env),testing:env.GOOGLE_AUTH_STAGE!=='production',authenticated:false});
      if(!user)fail(401,'구글 계정으로 로그인해 주세요.');
      if(request.method!=='GET'&&request.headers.get('x-wingstar-account')!==user.public_id)
        return json({code:'ACCOUNT_CHANGED',message:'계정이 바뀌었어요. 새로고침 후 다시 시도해 주세요.'},409);
      if(path==='/api/social/auth/logout'&&request.method==='POST'){
        await run(env,'DELETE FROM social_sessions WHERE token_hash=?',[await hash(cookie(request,SESSION_COOKIE))]);
        return json({ok:true},200,{'Set-Cookie':setCookie(SESSION_COOKIE,'',0)});
      }
      if(path==='/api/social/profile'&&request.method==='PATCH'){
        const input=await body(request);const nickname=typeof input.nickname==='string'?input.nickname.trim():'';
        if(!nickname||[...nickname].length>24||/[\u0000-\u001f\u007f]/.test(nickname)||!['sky','mint','lavender','sunset'].includes(input.accent)||!['leaf','sparkle','walk','heart'].includes(input.badge)||typeof input.publicRanking!=='boolean')fail(400,'닉네임과 공개 설정을 확인해 주세요.');
        await run(env,'UPDATE social_users SET nickname=?,accent=?,badge=?,public_ranking=? WHERE id=?',[nickname,input.accent,input.badge,input.publicRanking?1:0,user.id]);
        return json({ok:true});
      }
      if(path==='/api/social/search'&&request.method==='GET'){
        if(url.searchParams.has('q')) {
          const query=(url.searchParams.get('q')||'').trim();
          if(!query||[...query].length>24||/[\u0000-\u001f\u007f]/.test(query))fail(400,'닉네임을 1~24자로 입력해 주세요. 아이디로도 찾을 수 있어요.');
          const isId=/^WS-[A-HJ-NP-Z2-9]{10}$/i.test(query);
          const pattern='%'+query.replace(/[!%_]/g,char=>'!'+char)+'%';
          const matches=await rows(env,`SELECT u.*,f.status AS relationship_status,f.requested_by FROM social_users u
            LEFT JOIN social_friendships f ON (f.user_low=? AND f.user_high=u.id) OR (f.user_high=? AND f.user_low=u.id)
            WHERE ${isId?'u.public_id=?':"u.nickname LIKE ? ESCAPE '!'"}
            ORDER BY CASE WHEN u.nickname=? COLLATE NOCASE THEN 0 ELSE 1 END,u.nickname COLLATE NOCASE,u.public_id LIMIT 21`,
            [user.id,user.id,isId?query.toUpperCase():pattern,query]);
          return json({query,hasMore:matches.length>20,results:matches.slice(0,20).map(other=>({
            user:publicUser(other),relationship:other.id===user.id?'self':other.relationship_status==='accepted'?'friend':other.relationship_status==='pending'?other.requested_by===user.id?'outgoing':'incoming':'none',
          }))});
        }
        // Older clients can keep using exact ID lookup during an app update.
        const other=await otherUser(env,(url.searchParams.get('id')||'').trim().toUpperCase());
        const linked=await relation(env,user.id,other.id);
        return json({user:publicUser(other),relationship:other.id===user.id?'self':linked?linked.status==='accepted'?'friend':linked.requested_by===user.id?'outgoing':'incoming':'none'});
      }
      if(path==='/api/social/friends/request'&&request.method==='POST'){
        const input=await body(request),other=await otherUser(env,input.id);
        if(other.id===user.id)fail(400,'내 아이디는 친구로 추가할 수 없어요.');
        const result=await run(env,`INSERT OR IGNORE INTO social_friendships(user_low,user_high,requested_by,status,created_at)
          SELECT ?,?,?,'pending',? WHERE
          (SELECT COUNT(*) FROM social_friendships WHERE user_low=? OR user_high=?)<100 AND
          (SELECT COUNT(*) FROM social_friendships WHERE user_low=? OR user_high=?)<100`,
          [...pair(user.id,other.id),user.id,now,user.id,user.id,other.id,other.id]);
        if(!result.meta.changes&&!await relation(env,user.id,other.id))fail(409,'친구와 요청을 합해 각 계정당 100명까지 연결할 수 있어요.');
        return json({ok:true});
      }
      if(path==='/api/social/friends/respond'&&request.method==='POST'){
        const input=await body(request),other=await otherUser(env,input.id);
        if(!['accept','decline'].includes(input.action))fail(400,'응답을 확인해 주세요.');
        const args=[...pair(user.id,other.id),other.id];
        const result=input.action==='accept'
          ?await run(env,"UPDATE social_friendships SET status='accepted' WHERE user_low=? AND user_high=? AND requested_by=? AND status='pending'",args)
          :await run(env,"DELETE FROM social_friendships WHERE user_low=? AND user_high=? AND requested_by=? AND status='pending'",args);
        if(!result.meta.changes)fail(409,'이미 처리되었거나 받은 요청이 아니에요.');return json({ok:true});
      }
      if(path==='/api/social/friends/remove'&&request.method==='POST'){
        const input=await body(request),other=await otherUser(env,input.id);
        await run(env,'DELETE FROM social_friendships WHERE user_low=? AND user_high=?',pair(user.id,other.id));return json({ok:true});
      }
      if(path==='/api/social/cheer'&&request.method==='POST'){
        const input=await body(request),other=await otherUser(env,input.id),linked=await relation(env,user.id,other.id);
        if(linked?.status!=='accepted')fail(403,'연결된 친구에게 응원할 수 있어요.');
        const result=await run(env,'INSERT OR IGNORE INTO social_cheers(from_user,to_user,day) VALUES(?,?,?)',[user.id,other.id,period(now).today]);
        return json({ok:true,created:result.meta.changes>0});
      }
      if(path==='/api/social/activity'&&request.method==='POST'){
        const input=await body(request);
        if(typeof input.id!=='string'||!/^[a-f0-9-]{36}$/.test(input.id)||!Number.isInteger(input.steps)||input.steps<1||input.steps>10000||!Number.isSafeInteger(input.at)||input.at>now+300000||input.at<now-7*86400000)fail(400,'활동 기록을 확인해 주세요.');
        const existing=await first(env,'SELECT * FROM social_activity_batches WHERE id=?',[input.id]);
        if(existing){if(existing.user_id!==user.id||existing.steps!==input.steps||existing.recorded_at!==input.at)fail(409,'중복된 활동 기록이에요.');return json({ok:true});}
        const day=period(input.at).today;
        const result=await run(env,'INSERT OR IGNORE INTO social_activity_batches(id,user_id,day,steps,recorded_at) SELECT ?,?,?,?,? WHERE COALESCE((SELECT SUM(steps) FROM social_activity_batches WHERE user_id=? AND day=?),0)+?<=100000',[input.id,user.id,day,input.steps,input.at,user.id,day,input.steps]);
        if(!result.meta.changes)fail(409,'오늘 반영 가능한 걸음 수를 초과했어요.');return json({ok:true});
      }
      if(path==='/api/social/rankings'&&request.method==='GET'){
        const scope=url.searchParams.get('scope')||'friends';if(!['friends','all'].includes(scope))fail(400,'랭킹 범위를 확인해 주세요.');return json(await rankings(env,user,scope,now));
      }
      fail(404,'요청한 기능을 찾지 못했어요.');
    } catch(error){
      if(error instanceof ApiError)return json({message:error.message},error.status);
      console.error('WingStar social API failed:',error?.name||'Error');
      return json({message:'연결이 원활하지 않아요. 잠시 후 다시 시도해 주세요.'},500);
    }
  };
}
