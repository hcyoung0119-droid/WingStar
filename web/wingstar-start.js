(async () => {
  await window.wingstarSocial.boot();
  const media=document.createElement('script');media.src='wingstar-media.js';
  const launch=()=>{const flutter=document.createElement('script');flutter.src='flutter_bootstrap.js';flutter.async=true;document.body.appendChild(flutter);};
  media.onload=launch;
  media.onerror=()=>{document.querySelector('#loading span').textContent='앱을 불러오지 못했어요. 연결을 확인한 뒤 새로고침해 주세요.';};
  document.body.appendChild(media);
})();
