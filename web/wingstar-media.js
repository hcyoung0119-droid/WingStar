// WingStar original ambient composition. No third-party recordings or samples.
// Source and credits: /music-credits.html
(() => {
  const BUILTIN = 'wingstar-calm';
  const tracks = new Map([[BUILTIN, {id:BUILTIN, name:'고요한 발걸음', source:'WingStar 오리지널 · 외부 곡·샘플 미사용'}]]);
  let selected = BUILTIN, enabled = true, volume = .45, status = 'stopped', notice = '';
  const storageSuffix = window.wingstarSocial?.storageSuffix || '';
  const preferencesKey = 'wingstar.music.preferences.v1' + storageSuffix;
  let savedPreferences = {}, selectionChanged = false;
  try {
    const saved = JSON.parse(localStorage.getItem(preferencesKey) || '{}');
    if (saved && typeof saved === 'object') savedPreferences = saved;
    if (typeof savedPreferences.enabled === 'boolean') enabled = savedPreferences.enabled;
    if (typeof savedPreferences.volume === 'number' && Number.isFinite(savedPreferences.volume))
      volume = Math.max(0, Math.min(1, savedPreferences.volume));
  } catch (_) {}
  function savePreferences() {
    try { localStorage.setItem(preferencesKey, JSON.stringify({selected, enabled, volume})); }
    catch (_) { notice = '설정을 저장할 수 없어 이번 실행에만 적용해요.'; }
  }
  let context, gain, audio, audioNode, audioUrl, scheduleTimer, scheduleAt = 0, chord = 0, generation = 0;
  let activeNodes = [], busy = false, keepAwake, lifecycle;
  const chords = [[48,55,59,62],[45,52,55,60],[41,48,52,57],[43,50,55,60]];
  let database;
  function openDB() {
    if (!database) database = new Promise((resolve,reject) => {
      if (!window.indexedDB) return reject(new Error('storage'));
      const request = indexedDB.open('wingstar-music-v1' + storageSuffix,1);
      request.onupgradeneeded = () => request.result.createObjectStore('tracks',{keyPath:'id'});
      request.onsuccess = () => resolve(request.result);
      request.onerror = () => reject(request.error);
    });
    return database;
  }
  async function dbAction(mode, operation) {
    const db = await openDB();
    return new Promise((resolve,reject) => {
      const tx = db.transaction('tracks', mode);
      const request = operation(tx.objectStore('tracks'));
      tx.oncomplete = () => resolve(request?.result);
      tx.onerror = tx.onabort = () => reject(tx.error || new Error('storage'));
    });
  }
  function stopNodes() {
    clearInterval(scheduleTimer); scheduleTimer = null;
    for (const node of activeNodes) { try { node.stop(); } catch (_) {} }
    activeNodes = [];
  }
  function synthesize() {
    while (scheduleAt < context.currentTime + 16) {
      for (const midi of chords[chord % chords.length]) {
        const osc = context.createOscillator(), envelope = context.createGain();
        osc.type = 'sine'; osc.frequency.value = 440 * 2 ** ((midi - 69) / 12);
        envelope.gain.setValueAtTime(0, scheduleAt);
        envelope.gain.linearRampToValueAtTime(.045, scheduleAt + 3);
        envelope.gain.linearRampToValueAtTime(.025, scheduleAt + 8);
        envelope.gain.linearRampToValueAtTime(0, scheduleAt + 12);
        osc.connect(envelope); envelope.connect(gain);
        osc.start(scheduleAt); osc.stop(scheduleAt + 12);
        activeNodes.push(osc);
        osc.onended = () => { activeNodes = activeNodes.filter(n => n !== osc); osc.disconnect(); envelope.disconnect(); };
      }
      scheduleAt += 8; chord++;
    }
  }
  function releaseAudio() {
    audioNode?.disconnect(); audioNode = null;
    if (audio) { audio.pause(); audio.removeAttribute('src'); audio.load(); audio = null; }
    if (audioUrl) { URL.revokeObjectURL(audioUrl); audioUrl = null; }
  }
  function prepareAudio() {
    releaseAudio();
    const track = tracks.get(selected);
    if (track?.blob) {
      audioUrl = URL.createObjectURL(track.blob);
      audio = new Audio(audioUrl); audio.loop = true; audio.preload = 'auto';
      // Route through Web Audio gain: iOS ignores the HTMLMediaElement volume setter.
      audioNode = context.createMediaElementSource(audio); audioNode.connect(gain);
      audio.onerror = () => { status = 'error'; notice = '이 파일은 재생할 수 없어요. MP3 또는 M4A 파일을 선택해 주세요.'; };
    }
  }
  function ensureContext() {
    if (!context) {
      const AudioContext = window.AudioContext || window.webkitAudioContext;
      if (!AudioContext) throw new Error('unsupported');
      context = new AudioContext(); gain = context.createGain(); gain.gain.value = volume; gain.connect(context.destination);
    }
  }
  const api = {
    state() { return JSON.stringify({selected,enabled,volume,status,notice,busy,
      tracks:[...tracks.values()].map(({id,name,source}) => ({id,name,source}))}); },
    async play() {
      if (!enabled) { status = 'muted'; return 'muted'; }
      const current = ++generation;
      let timeout;
      try {
        ensureContext();
        const resumed = context.resume(); // Invoked synchronously during the user's gesture.
        stopNodes();
        let playing;
        if (selected === BUILTIN) {
          if (audio) audio.pause();
          scheduleAt = context.currentTime + .05; chord = 0; synthesize();
          scheduleTimer = setInterval(synthesize, 1000);
        } else {
          if (!audio) prepareAudio();
          playing = audio.play();
        }
        await Promise.race([Promise.all([resumed,playing]),new Promise((_,reject)=>{timeout=setTimeout(()=>reject(new Error('playback timeout')),8000);})]);
        if (current !== generation) return 'paused';
        status = 'playing'; notice = ''; return 'playing';
      } catch (_) {
        if (current !== generation) return 'paused';
        stopNodes(); audio?.pause(); status = 'error'; notice = '음악 재생을 시작하지 못했어요. 음악 재생 버튼을 다시 눌러 주세요.'; return 'error';
      } finally { clearTimeout(timeout); }
    },
    pause() { generation++; stopNodes(); audio?.pause(); if (status !== 'stopped') status = 'paused'; },
    stop() { this.pause(); if (audio) audio.currentTime = 0; status = 'stopped'; },
    setEnabled(value) { enabled = !!value; if (!enabled) this.pause(); savePreferences(); },
    setVolume(value) { volume = Math.max(0,Math.min(1,Number(value)||0)); if (gain) gain.gain.setTargetAtTime(volume,context.currentTime,.1); savePreferences(); },
    select(id) {
      if (!tracks.has(id)) return;
      this.stop(); selected = id; selectionChanged = true; notice = ''; savePreferences();
      try { ensureContext(); prepareAudio(); } catch (_) { status='error'; }
    },
    pickMusic() {
      if (busy) return;
      const input = document.createElement('input'); input.type='file';
      input.accept='audio/*,.mp3,.m4a,.aac,.wav,.ogg,.flac';
      input.onchange = async () => {
        const file = input.files?.[0]; if (!file) return;
        if (file.size > 50*1024*1024 || file.size === 0) { notice='50MB 이하의 음악 파일을 선택해 주세요.'; return; }
        if (!(file.type.startsWith('audio/') || /\.(mp3|m4a|aac|wav|ogg|flac)$/i.test(file.name))) { notice='음악 파일을 선택해 주세요.'; return; }
        busy=true;
        const item={id:crypto.randomUUID(),name:file.name,source:'내 기기에서 추가 · 서버로 업로드하지 않음',blob:file,persisted:true};
        try {
          await dbAction('readwrite', s=>s.put(item));
          tracks.set(item.id,item); this.select(item.id);
          notice='이 브라우저에 음악을 추가했어요.';
        } catch (_) {
          item.persisted=false;
          tracks.set(item.id,item); this.select(item.id);
          notice='저장 공간을 사용할 수 없어 이번 실행 동안만 음악을 재생합니다.';
        } finally { busy=false; }
      };
      input.click(); // Only this explicitly selected file is read.
    },
    async remove(id) {
      if (id===BUILTIN) return;
      try { if(tracks.get(id)?.persisted!==false) await dbAction('readwrite',s=>s.delete(id)); }
      catch (_) { notice='저장한 음악을 삭제하지 못했어요. 다시 시도해 주세요.'; return; }
      if (selected===id) this.select(BUILTIN);
      tracks.delete(id); notice='추가한 음악을 삭제했어요.';
    },
    setLifecycle(callback) { lifecycle=callback; },
    async wake() { try { keepAwake = await navigator.wakeLock?.request('screen'); } catch (_) {} },
    releaseWake() { keepAwake?.release().catch(()=>{}); keepAwake=null; },
    speak(text) {
      if (!window.speechSynthesis || document.hidden) return;
      speechSynthesis.cancel(); const utterance=new SpeechSynthesisUtterance(text);
      utterance.lang='ko-KR'; utterance.rate=.78; utterance.volume=.85; speechSynthesis.speak(utterance);
    },
    stopVoice() { window.speechSynthesis?.cancel(); },
  };
  window.wingstarMedia=api;
  dbAction('readonly',s=>s.getAll()).then(items=>{
    for(const item of items||[]) tracks.set(item.id,item);
    if (!selectionChanged && generation === 0 && tracks.has(savedPreferences.selected))
      selected = savedPreferences.selected;
  }).catch(()=>{});
  document.addEventListener('visibilitychange',()=>{
    if(document.hidden) { api.pause(); api.stopVoice(); api.releaseWake(); }
    lifecycle?.(!document.hidden);
  });
  window.addEventListener('pagehide',()=>{api.stop();api.stopVoice();api.releaseWake();lifecycle?.(false);});
})();
