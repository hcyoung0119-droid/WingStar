// Photos stay in the user's browser. Only the file they select is read.
(() => {
  let pending;
  window.wingstarProfile = {
    pickPhoto() {
      if (pending) return pending;
      const result = new Promise(resolve => {
        const input = document.createElement('input');
        input.type = 'file'; input.accept = 'image/jpeg,image/png,image/webp,image/heic,image/heif';
        input.style.display = 'none'; document.body.appendChild(input);
        let finished = false;
        function finish(value) {
          if (finished) return;
          finished = true; input.remove(); resolve(JSON.stringify(value));
        }
        input.oncancel = () => finish({cancelled:true});
        input.onchange = () => {
          const file = input.files?.[0];
          if (!file) return finish({cancelled:true});
          if (!file.size || file.size > 10 * 1024 * 1024)
            return finish({error:'10MB 이하의 사진을 선택해 주세요.'});
          if (!/^image\/(jpeg|png|webp|heic|heif)$/i.test(file.type))
            return finish({error:'JPG·PNG·WebP 또는 HEIC 사진을 선택해 주세요.'});
          const url = URL.createObjectURL(file), picture = new Image();
          picture.onerror = () => { URL.revokeObjectURL(url); finish({error:'이 사진을 읽지 못했어요. JPG나 PNG 사진으로 다시 선택해 주세요.'}); };
          picture.onload = () => {
            try {
              if (!picture.naturalWidth || !picture.naturalHeight) throw new Error('empty');
              const canvas = document.createElement('canvas'); canvas.width = canvas.height = 512;
              const context = canvas.getContext('2d');
              const edge = Math.min(picture.naturalWidth, picture.naturalHeight);
              context.fillStyle = '#eef7fb'; context.fillRect(0,0,512,512);
              context.drawImage(picture,(picture.naturalWidth-edge)/2,(picture.naturalHeight-edge)/2,edge,edge,0,0,512,512);
              // Re-encode a small square image; original photo metadata is not copied.
              const photo = canvas.toDataURL('image/jpeg',.86);
              if (!photo.startsWith('data:image/jpeg;base64,') || photo.length > 600000) throw new Error('encode');
              finish({photo});
            } catch (_) { finish({error:'사진을 준비하지 못했어요. 다른 사진을 선택해 주세요.'}); }
            finally { URL.revokeObjectURL(url); }
          };
          picture.src = url;
        };
        input.click(); // Preserve the iPhone file picker user gesture.
      });
      pending = result.finally(() => { pending = null; });
      return pending;
    },
  };
})();
