import assert from 'node:assert/strict';
import {Client} from '@modelcontextprotocol/sdk/client/index.js';
import {StdioClientTransport} from '@modelcontextprotocol/sdk/client/stdio.js';
const c=new Client({name:'maintenance-validation',version:'1.0.0'});
try {await c.connect(new StdioClientTransport({command:process.execPath,args:['server.mjs'],env:{...process.env,GEMINI_API_KEY:'validation-only-not-a-real-key'}}));
const t=await c.listTools();assert.equal(t.tools.length,2);
for(const request of [
{name:'analyze_youtube_video',arguments:{youtube_url:'http://localhost/private'}},
{name:'analyze_media_file',arguments:{file_path:'relative.mp4'}},
{name:'analyze_media_file',arguments:{file_path:'/nonexistent-maintenance-file.mp4',fps:25}},
{name:'analyze_youtube_video',arguments:{youtube_url:'https://youtube.com/watch?v=unused',question:'x'.repeat(4001)}}]){
const r=await c.callTool(request);assert.equal(r.isError,true);}
console.log(JSON.stringify({ok:true,tools:2,rejectedInvalidRequests:4,paidRequests:0}));}finally{await c.close();}