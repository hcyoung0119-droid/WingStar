import {build} from 'esbuild';
import {mkdir,copyFile} from 'node:fs/promises';
await mkdir('dist/server',{recursive:true});
await build({entryPoints:['server/worker.mjs'],outfile:'dist/server/index.js',bundle:true,format:'esm',platform:'browser',target:'es2022',minify:true});
await mkdir('dist/.openai',{recursive:true});
await copyFile('.openai/hosting.json','dist/.openai/hosting.json');
console.log('WingStar Worker built; Flutter assets must be built in dist/client.');
