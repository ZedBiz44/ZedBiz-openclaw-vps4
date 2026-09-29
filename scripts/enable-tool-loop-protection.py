"""Enable only OpenClaw's supported loop flag, with validation and rollback copy.

Run on the target host/container with its actual config and installed runtime.
No model requests, service restarts, or timeout changes are made.
"""
import argparse
import datetime
import json
import os
from pathlib import Path
import shutil
import subprocess


parser = argparse.ArgumentParser()
parser.add_argument("--config", required=True)
parser.add_argument("--runtime", required=True)
parser.add_argument("--agent", required=True)
parser.add_argument("--apply", action="store_true")
args = parser.parse_args()
path = Path(args.config)
runtime = Path(args.runtime)
before = path.read_bytes()
config = json.loads(before)
candidate_config = json.loads(before)
candidate_config.setdefault("tools", {}).setdefault("loopDetection", {})["enabled"] = True
for agent in candidate_config.get("agents", {}).get("list", []):
    if "loopDetection" in agent.get("tools", {}):
        agent["tools"]["loopDetection"]["enabled"] = True

detectors = [p for p in (runtime / "dist").glob("tool-loop-detection-*.mjs") if "config" not in p.name]
assert len(detectors) == 1, "Expected one installed detector"
test = """
import {t as detect,r as record,i as outcome} from DETECTOR;
const cfg={enabled:true},scope={runId:'cody-offline-loop-test'},state={},args={path:'/synthetic/fixture'};
let warned=false,blocked=false;
for(let i=0;i<25;i++) {
 const d=detect(state,'read',args,cfg,scope);
 warned ||= d.level==='warning';
 if(d.level==='critical'){blocked=true;break;}
 record(state,'read',args,String(i),cfg,scope);
 outcome(state,{toolName:'read',toolParams:args,toolCallId:String(i),runId:scope.runId,result:{content:[{type:'text',text:'unchanged'}]}});
}
if(!warned||!blocked)throw Error('Repeated successful reads not detected');
const fresh={};
for(let i=0;i<40;i++){
 const a={path:'/synthetic/'+i};
 if(detect(fresh,'read',a,cfg,scope).stuck)throw Error('Distinct reads falsely blocked');
 record(fresh,'read',a,String(i),cfg,scope);
 outcome(fresh,{toolName:'read',toolParams:a,toolCallId:String(i),runId:scope.runId,result:{content:[{type:'text',text:'result '+i}]}});
}
console.log(JSON.stringify({warning:true,blocking:true,distinctReadsAllowed:40}));
""".replace("DETECTOR", json.dumps(detectors[0].as_uri()))
tested = subprocess.run(["node", "--input-type=module"], input=test, text=True, capture_output=True)
assert tested.returncode == 0, tested.stderr[-1500:]

candidate = path.with_name("openclaw.loop-protection-candidate.json")
assert not candidate.exists(), "Candidate already exists; inspect before overwriting"
candidate.write_text(json.dumps(candidate_config, indent=2) + "\n")
os.chown(candidate, path.stat().st_uid, path.stat().st_gid)
os.chmod(candidate, path.stat().st_mode & 0o777)
env = dict(os.environ, OPENCLAW_CONFIG_PATH=str(candidate), OPENCLAW_STATE_DIR=str(path.parent))
validated = subprocess.run(["node", str(runtime / "openclaw.mjs"), "config", "validate", "--json"], env=env, text=True, capture_output=True)
assert validated.returncode == 0, validated.stdout[-2500:] + validated.stderr[-1000:]
validation = json.loads(validated.stdout)
assert validation.get("valid") is True
assert path.read_bytes() == before, "Live config changed concurrently; stopped"
result = {"agent": args.agent, "version": json.loads((runtime / "package.json").read_text())["version"], "validated": True, "detectorTest": "passed", "validationWarningCount": len(validation.get("warnings", []))}
if args.apply:
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    backup = path.parent / "backups" / ("loop-protection-" + stamp)
    backup.mkdir(parents=True, mode=0o700)
    shutil.copy2(path, backup / "openclaw.json")
    os.chmod(backup / "openclaw.json", 0o600)
    os.replace(candidate, path)
    assert json.loads(path.read_text()) == candidate_config
    result.update(applied=True, backup=str(backup / "openclaw.json"), enabled=True)
else:
    candidate.unlink()
    result["applied"] = False
print(json.dumps(result))

