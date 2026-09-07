import {createRemoteJWKSet, jwtVerify} from 'jose';
const googleKeys = createRemoteJWKSet(new URL('https://www.googleapis.com/oauth2/v3/certs'));
export const ORIGIN = 'https://wingstar-care.use-loing-ai.chatgpt.site';
export const SESSION_COOKIE = '__Host-wingstar_session';
export const NONCE_COOKIE = '__Host-wingstar_login';
export const configured = env => /^[\w-]+\.apps\.googleusercontent\.com$/.test(env.GOOGLE_CLIENT_ID || '');
export const randomToken = () => [...crypto.getRandomValues(new Uint8Array(32))].map(v=>v.toString(16).padStart(2,'0')).join('');
export async function hash(value) {
  const bytes = await crypto.subtle.digest('SHA-256',new TextEncoder().encode(value));
  return [...new Uint8Array(bytes)].map(v=>v.toString(16).padStart(2,'0')).join('');
}
export function cookie(request,name) {
  return (request.headers.get('cookie') || '').split(';').map(v=>v.trim()).find(v=>v.startsWith(name+'='))?.slice(name.length+1) || '';
}
export const setCookie = (name,value,seconds) => `${name}=${value}; Path=/; Secure; HttpOnly; SameSite=Lax; Max-Age=${seconds}`;
export async function verifyGoogleIdentity(token,clientId,nonce,keys=googleKeys) {
  const {payload} = await jwtVerify(token,keys,{
    audience:clientId, issuer:['accounts.google.com','https://accounts.google.com'],
    algorithms:['RS256'], requiredClaims:['sub','exp','iat','nonce'], clockTolerance:5,
  });
  if (typeof payload.sub !== 'string' || !payload.sub || payload.sub.length>255 || payload.nonce !== nonce)
    throw new Error('Invalid Google identity');
  return `google:${payload.sub}`;
}

export function loginPage(clientId,testing=true) {
  const safeClientId = JSON.stringify(clientId).replaceAll('<','\\u003c');
  return `<!doctype html><html lang="ko"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="referrer" content="strict-origin-when-cross-origin"><title>WingStar · 구글 로그인</title>
  <style>body{margin:0;min-height:100vh;display:grid;place-items:center;font:16px system-ui,sans-serif;background:linear-gradient(145deg,#e2f2fc,#e8f4ed);color:#203846}.card{width:min(340px,85vw);padding:28px;border-radius:28px;background:white;box-shadow:0 14px 45px #24557018}p{line-height:1.7;color:#59717d}a{color:#276d92}.brand{letter-spacing:3px;font-size:12px;color:#4383a0}#google{min-height:44px;margin:24px 0}#status{font-size:13px}</style></head><body><main class="card"><div class="brand">WINGSTAR</div><h1>친구와 함께 걷기</h1><p>구글 계정으로 내 고유 아이디와 친구 목록을 이어가세요.</p><p style="font-size:13px">친구에게는 닉네임·아이디·주간 걸음 기록이 보입니다. 전체 랭킹 공개 여부는 로그인 후 직접 선택할 수 있어요.</p>${testing?'<p style="font-size:13px">현재 등록된 테스트 계정으로 로그인할 수 있어요.</p>':'<p style="font-size:13px">구글 계정으로 계속하세요.</p>'}<div id="google"></div><p id="status" role="status">로그인을 준비하고 있어요.</p><a href="/?ranking=1">앱으로 돌아가기</a><p class="small"><a href="/privacy">개인정보 안내</a></p></main>
  <script>async function initializeGoogle(){const status=document.getElementById('status');try{const response=await fetch('/api/social/auth/challenge',{method:'POST',headers:{'X-WingStar-Request':'1'},credentials:'same-origin'});const data=await response.json();if(!response.ok)throw Error(data.message);google.accounts.id.initialize({client_id:${safeClientId},nonce:data.nonce,auto_select:false,callback:async({credential})=>{status.textContent='계정을 연결하고 있어요.';try{const result=await fetch('/api/social/auth/google',{method:'POST',credentials:'same-origin',headers:{'Content-Type':'application/json','X-WingStar-Request':'1'},body:JSON.stringify({credential})});const account=await result.json();if(!result.ok)throw Error(account.message);location.replace('/?ranking=1');}catch(error){status.textContent=error.message||'로그인을 완료하지 못했어요. 다시 시도해 주세요.';}}});google.accounts.id.renderButton(document.getElementById('google'),{theme:'outline',size:'large',text:'continue_with',shape:'pill',locale:'ko',width:300});status.textContent='';}catch(error){status.textContent=error.message||'로그인을 준비하지 못했어요. 잠시 후 다시 시도해 주세요.';}}</script><script src="https://accounts.google.com/gsi/client" async defer onload="initializeGoogle()" onerror="document.getElementById('status').textContent='구글 로그인 화면을 불러오지 못했어요. Safari에서 다시 열어 주세요.'"></script></body></html>`;
}
