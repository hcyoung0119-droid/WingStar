(() => {
  const publicUrl = 'https://wingstar-care.use-loing-ai.chatgpt.site/';
  let motionListener;
  const motionConsentKey = 'wingstar.motion.consent.v1';
  let motionGranted = false, motionRequest, probeListener, probeTimer;
  function rememberMotionGrant() {
    motionGranted = true;
    try { localStorage.setItem(motionConsentKey, 'granted'); } catch (_) {}
  }
  function stopMotionProbe() {
    if (probeListener) window.removeEventListener('devicemotion', probeListener);
    probeListener = null; clearTimeout(probeTimer);
  }
  function probeExistingMotionAccess() {
    stopMotionProbe();
    if (motionGranted || document.hidden) return;
    try { if (localStorage.getItem(motionConsentKey) !== 'granted') return; } catch (_) { return; }
    // A saved preference is only a hint. Real browser-delivered sensor data
    // proves this document can still use the permission, without a new prompt.
    probeListener = event => {
      const a = event.accelerationIncludingGravity;
      if (event.isTrusted && !document.hidden && a && [a.x,a.y,a.z].every(Number.isFinite)) {
        rememberMotionGrant(); stopMotionProbe();
      }
    };
    window.addEventListener('devicemotion', probeListener);
    probeTimer = setTimeout(stopMotionProbe, 1500);
  }
  window.wingstar = {
    get motionSupported() { return window.isSecureContext && typeof window.DeviceMotionEvent !== 'undefined' && (/iPhone|iPad|Android/i.test(navigator.userAgent) || navigator.maxTouchPoints > 1); },
    requestMotionAccess() {
      if (!this.motionSupported) return Promise.resolve('unavailable');
      if (motionGranted) return Promise.resolve('granted');
      if (motionRequest) return motionRequest;
      try {
        if (typeof DeviceMotionEvent.requestPermission === 'function') {
          // Keep this call synchronous: Safari requires the original start tap.
          const requested = DeviceMotionEvent.requestPermission();
          motionRequest = Promise.resolve(requested).then(result => {
            if (result === 'granted') rememberMotionGrant();
            else { try { localStorage.removeItem(motionConsentKey); } catch (_) {} }
            stopMotionProbe(); return result;
          }).catch(() => 'denied').finally(() => { motionRequest = null; });
          return motionRequest;
        }
        rememberMotionGrant();
        return Promise.resolve('granted');
      } catch (_) { return Promise.resolve('denied'); }
    },
    resetMotionAccess() { motionGranted = false; stopMotionProbe(); },
    startMotion(callback) {
      this.stopMotion();
      motionListener = event => {
        if (document.hidden) return;
        const a = event.accelerationIncludingGravity;
        if (a && [a.x,a.y,a.z].every(Number.isFinite)) callback(a.x,a.y,a.z);
      };
      window.addEventListener('devicemotion', motionListener);
    },
    stopMotion() { if (motionListener) window.removeEventListener('devicemotion', motionListener); motionListener = null; },
    async shareLink() {
      if (navigator.share) {
        try { await navigator.share({title:'WingStar',text:'몸과 마음을 돌보는 시간, WingStar',url:publicUrl}); return 'shared'; }
        catch (e) { if (e.name === 'AbortError') return 'cancelled'; }
      }
      return this.copyLink();
    },
    async copyLink() {
      try { await navigator.clipboard.writeText(publicUrl); return 'copied'; }
      catch (_) { return 'unavailable'; }
    },
    loadState() { try { return localStorage.getItem('wingstar.device.v1') || ''; } catch (_) { return ''; } },
    saveState(value) { try { localStorage.setItem('wingstar.device.v1',value); return true; } catch (_) { return false; } }
  };
  probeExistingMotionAccess();
  document.addEventListener('visibilitychange', () => {
    if (document.hidden) stopMotionProbe(); else probeExistingMotionAccess();
  });
  window.addEventListener('pageshow', probeExistingMotionAccess);
  window.addEventListener('pagehide', stopMotionProbe);
  window.addEventListener('flutter-first-frame',()=>document.getElementById('loading')?.remove(),{once:true});
  window.addEventListener('load',()=>{ if ('serviceWorker' in navigator) navigator.serviceWorker.register('/sw.js').catch(()=>{}); });
})();
// A small read-only entry point for the same link and install guide shown in the app.
if (document.modelContext?.registerTool) {
  const lifecycle = new AbortController();
  window.addEventListener('pagehide', () => lifecycle.abort(), {once:true});
  try {
    Promise.resolve(document.modelContext.registerTool({
      name:'get_wingstar_access',
      title:'WingStar 링크와 아이폰 설치 안내',
      description:'Return the public WingStar link and home screen installation instructions. Never reads or shares personal records.',
      inputSchema:{type:'object',properties:{},additionalProperties:false},
      annotations:{readOnlyHint:true,untrustedContentHint:false},
      execute(input) {
        if (!input || typeof input!=='object' || Array.isArray(input) || Object.keys(input).length) throw new Error('Expected an empty object');
        return {url:'https://wingstar-care.use-loing-ai.chatgpt.site/',install:'아이폰 Safari에서 링크 열기 → 공유 → 홈 화면에 추가 → 웹 앱으로 열기 → 추가',share:'앱의 마이 → 카카오톡으로 공유 → 공유창에서 카카오톡 선택'};
      }
    },{signal:lifecycle.signal})).catch(()=>{});
  } catch (_) {}
}
