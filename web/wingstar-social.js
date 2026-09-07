(() => {
  let data={configured:false,authenticated:false,loading:true,notice:'',scope:'friends',ranking:[],incoming:[],outgoing:[],friends:[]};
  let queue=[],openBatch,flushing=false,refreshing=false;
  let boundOwner='';
  const read=(key)=>{try{return localStorage.getItem(key);}catch{return null;}};
  const write=(key,value)=>{try{localStorage.setItem(key,value);return true;}catch{return false;}};
  async function request(path,method='GET',payload) {
    const controller=new AbortController(),timer=setTimeout(()=>controller.abort(),10000);
    try {
      const response=await fetch('/api/social/'+path,{method,credentials:'same-origin',cache:'no-store',signal:controller.signal,
        headers:method==='GET'?{}:{'Content-Type':'application/json','X-WingStar-Request':'1','X-WingStar-Account':data.me?.id||''},body:payload===undefined?undefined:JSON.stringify(payload)});
      let result;try{result=await response.json();}catch{throw Object.assign(Error('서버 연결을 확인해 주세요.'),{status:response.status});}
      if(!response.ok){if(result.code==='ACCOUNT_CHANGED')location.reload();throw Object.assign(Error(result.message||'요청을 완료하지 못했어요.'),{status:response.status,code:result.code});}
      return result;
    } finally {clearTimeout(timer);}
  }
  function namespace(id) {
    let primary=read('wingstar.social.firstOwner');
    if(id&&!primary){
      const old=read('wingstar.device.v1');
      if(old&&!read('wingstar.device.v1:'+id))write('wingstar.device.v1:'+id,old);
      write('wingstar.social.firstOwner',id);primary=id;
    }
    api.storageKey=id?'wingstar.device.v1:'+id:primary?'wingstar.device.guest.v2':'wingstar.device.v1';
    api.storageSuffix=id?(id===primary?'':':'+id):primary?':guest':'';
  }
  const queueKey=()=>data.me?'wingstar.social.pending:'+data.me.id:null;
  function persistQueue(){const key=queueKey();if(key&&!write(key,JSON.stringify([...queue,...(openBatch?[openBatch]:[])])))data.notice='동기화 전 기록을 저장할 공간이 부족해요. 앱을 닫기 전에 랭킹을 새로고침해 주세요.';}
  function seal(){if(openBatch){queue.push(openBatch);openBatch=null;}persistQueue();}
  async function flush(){
    if(flushing||!data.authenticated)return;
    flushing=true;seal();
    try{
      while(queue.length){
        const item=queue[0];
        if(item.at<Date.now()-7*86400000){queue.shift();persistQueue();continue;}
        try{await request('activity','POST',item);queue.shift();persistQueue();}
        catch(error){if([400,409].includes(error.status)&&error.code!=='ACCOUNT_CHANGED'){queue.shift();persistQueue();data.notice=error.message;continue;}throw error;}
      }
    }catch(error){data.notice=error.status===401?'로그인이 만료됐어요. 다시 로그인하면 기록을 이어서 동기화합니다.':'연결되면 걸음 기록을 다시 동기화할게요.';}
    finally{flushing=false;}
  }
  async function refresh(){
    if(refreshing)return;refreshing=true;
    try{
      const state=await request('state');
      // A changed account requires reloading the private storage namespace.
      if((state.me?.id||'')!==boundOwner){location.reload();return;}
      if(data.authenticated&&!state.authenticated){data={...data,...state,me:null,friends:[],incoming:[],outgoing:[],ranking:[],myRank:null};return;}
      data={...data,...state};
      if(data.authenticated){await flush();const ranking=await request('rankings?scope='+data.scope);data.ranking=ranking.rows;data.myRank=ranking.me;data.week=ranking.week;data.today=ranking.today;}
    }catch(error){data.notice=error.message||'연결을 확인한 뒤 새로고침해 주세요.';}
    finally{data.loading=false;refreshing=false;}
  }
  const api={
    storageKey:'wingstar.device.v1',storageSuffix:'',
    state:()=>JSON.stringify({...data,pendingSteps:queue.reduce((sum,v)=>sum+v.steps,0)+(openBatch?.steps||0)}),
    async boot(){
      try{
        const state=await request('state');data={...data,...state,loading:false};
        const id=state.me?.id||'';boundOwner=id;namespace(id);write('wingstar.social.lastOwner',id);
      }catch{boundOwner=read('wingstar.social.lastOwner')||'';namespace(boundOwner);data.loading=false;data.notice='오프라인에서는 친구·랭킹을 불러올 수 없어요.';}
      if(boundOwner){try{queue=JSON.parse(read('wingstar.social.pending:'+boundOwner)||'[]').filter(v=>Number.isInteger(v.steps)&&v.steps>0).slice(-500);}catch{queue=[];}}
    },
    login(){location.assign('/account/sign-in');},
    recordSteps(steps){
      if(!data.authenticated||!Number.isInteger(steps)||steps<1||steps>10000)return;
      const now=Date.now(),day=new Date(now+9*3600000).toISOString().slice(0,10);
      if(openBatch&&(new Date(openBatch.at+9*3600000).toISOString().slice(0,10)!==day||openBatch.steps+steps>10000))seal();
      if(!openBatch)openBatch={id:crypto.randomUUID(),steps:0,at:now};
      openBatch.steps+=steps;persistQueue();
    },
    async action(action,payload={}){
      if(data.busy)return JSON.stringify({ok:false});
      data.busy=true;data.notice='';let created=false;
      try{
        if(action==='refresh')await refresh();
        else if(action==='privacy')location.assign('/privacy');
        else if(action==='scope'){data.scope=payload.scope==='all'?'all':'friends';await refresh();}
        else if(action==='search'){data.search=null;data.search=await request('search?id='+encodeURIComponent((payload.id||'').trim().toUpperCase()));}
        else if(action==='copy'){if(!data.me)throw Error('로그인 후 아이디를 복사할 수 있어요.');await navigator.clipboard.writeText(data.me.id);data.notice='내 아이디를 복사했어요.';}
        else if(action==='logout'){await flush();await request('auth/logout','POST',{});write('wingstar.social.lastOwner','');location.replace('/?ranking=1');}
        else {
          const routes={request:['friends/request','POST'],accept:['friends/respond','POST'],decline:['friends/respond','POST'],remove:['friends/remove','POST'],profile:['profile','PATCH'],cheer:['cheer','POST']};
          if(!routes[action])throw Error('지원하지 않는 기능이에요.');
          const [path,method]=routes[action];const response=await request(path,method,{...payload,...(action==='accept'||action==='decline'?{action}:{})});
          created=response.created===true;
          data.search=null;await refresh();
          data.notice=action==='request'?'친구 요청을 보냈어요.':action==='accept'?'친구로 연결됐어요.':action==='cheer'?(response.created?'친구에게 응원을 보냈어요.':'오늘은 이미 응원했어요.'):'변경 내용을 저장했어요.';
        }
        return JSON.stringify({ok:true,created});
      }catch(error){data.notice=error.message||'연결을 확인한 뒤 다시 시도해 주세요.';return JSON.stringify({ok:false});}
      finally{data.busy=false;}
    },
  };
  window.wingstarSocial=api;
  setInterval(flush,20000);
  window.addEventListener('online',()=>{flush();refresh();});
  document.addEventListener('visibilitychange',()=>{if(document.hidden){seal();flush();}});
  window.addEventListener('pagehide',seal);
})();
