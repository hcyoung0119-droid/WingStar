import {createSocialApi} from './social/api.mjs';
const social = createSocialApi();
export default {
  async fetch(request,env,ctx) {
    const result = await social(request,env);
    if(result)return result;
    if(env.ASSETS)return env.ASSETS.fetch(request);
    return new Response('WingStar assets unavailable',{status:503});
  },
};
