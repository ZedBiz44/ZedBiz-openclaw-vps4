// Historical recovery artifact for OpenClaw 2026.9.8 (fc23bc8), Rocky VPS4.
// Run was performed offline with a verified SQLite backup and service restoration wrapper.
// Uses the installed repair function, including its ownership, integrity and completion gates.
// This is not a generic updater and should not be reused against another release.
import { loadConfig } from "/home/openclaw/.npm-global/lib/node_modules/openclaw/dist/io.runtime-BEyE1t8U.mjs";
import { noteSessionTranscriptHealth } from "/home/openclaw/.npm-global/lib/node_modules/openclaw/dist/doctor-session-transcripts-B-0dm7zB.mjs";
const warnings=[];
try {
 const cfg=loadConfig();
 console.log("Starting installed session and post-session plugin repair");
 const receipt=await noteSessionTranscriptHealth({cfg,env:process.env,shouldRepair:true,onWarnings:w=>warnings.push(...w),onStepReceipt:r=>console.log(JSON.stringify({receipt:r}))});
 console.log(JSON.stringify({complete:true,warnings,receipt}));
 process.exitCode=warnings.length?1:0;
}catch(error){console.error(error?.stack??String(error));process.exitCode=1;}
