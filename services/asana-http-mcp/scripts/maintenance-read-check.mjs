import {Client} from '@modelcontextprotocol/sdk/client/index.js';
import {StreamableHTTPClientTransport} from '@modelcontextprotocol/sdk/client/streamableHttp.js';
const c=new Client({name:'cody-maintenance-test',version:'1.0.0'});
try {await c.connect(new StreamableHTTPClientTransport(new URL(process.env.SMOKE_URL),{requestInit:{headers:{Authorization:'Bearer '+process.env.MCP_AUTH_TOKEN}}}));
const tools=await c.listTools(); if(tools.tools.length!==76)throw Error('Tool count mismatch');
const user=await c.callTool({name:'asana_get_user',arguments:{user_gid:'me'}});if(user.isError)throw Error('Account read failed');
console.log(JSON.stringify({ok:true,toolCount:tools.tools.length,accountRead:!user.isError}));}finally{await c.close();}