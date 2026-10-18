"""Collect non-secret final native-service evidence after accepted maintenance."""
import json, os, subprocess, urllib.request, datetime
from pathlib import Path
B=Path('/var/backups/rocky-20261018')
env=json.loads((B/'runtime-env.json').read_text())
env.update(HOME='/home/openclaw',XDG_RUNTIME_DIR='/run/user/1000',DBUS_SESSION_BUS_ADDRESS='unix:path=/run/user/1000/bus')
def demote():
    os.setgroups([1000]);os.setgid(1000);os.setuid(1000)
def user(args):
    return subprocess.run(args,env=env,preexec_fn=demote,cwd='/home/openclaw',capture_output=True,text=True,check=True).stdout.strip()
props=['MainPID','ActiveState','SubState','NRestarts','Result','MemoryCurrent','MemoryPeak','MemoryMax','ControlGroup']
raw=user(['systemctl','--user','show','openclaw-gateway.service',*[x for p in props for x in ['-p',p]]])
service=dict(line.split('=',1) for line in raw.splitlines())
assert service['ActiveState']=='active' and service['SubState']=='running' and service['Result']=='success'
assert service['NRestarts']=='0'
pid=service['MainPID'];cg=Path('/sys/fs/cgroup'+service['ControlGroup'])
pss={k:int(v.split()[0]) for k,v in (line.split(':',1) for line in Path('/proc/'+pid+'/smaps_rollup').read_text().splitlines()[1:])}
memory=dict(line.split() for line in (cg/'memory.stat').read_text().splitlines())
events=dict(line.split() for line in (cg/'memory.events').read_text().splitlines())
assert events['oom_kill']=='0'
meminfo={k:int(v.split()[0]) for k,v in (line.split(':',1) for line in Path('/proc/meminfo').read_text().splitlines())}
http={url:urllib.request.urlopen(url,timeout=20).status for url in ['http://127.0.0.1:18789/healthz','https://rocky.zbiz.ca/healthz','http://127.0.0.1:9077/health']}
assert all(v==200 for v in http.values())
listeners=subprocess.run(['ss','-ltn'],capture_output=True,text=True,check=True).stdout
gateway=[line for line in listeners.splitlines() if ':18789 ' in line]
assert gateway and all('127.0.0.1:18789' in line or '[::1]:18789' in line for line in gateway)
dependencies={u:subprocess.run(['systemctl','is-active',u],capture_output=True,text=True,check=True).stdout.strip() for u in ['rocky-vps1-tunnel.service','zedbiz-rocky-restart-api.service']}
dependencies['rocky-asana-mcp.service']=user(['systemctl','--user','is-active','rocky-asana-mcp.service'])
version=json.loads(Path('/home/openclaw/.npm-global/lib/node_modules/openclaw/package.json').read_text())['version']
assert version=='2026.10.4'
result={'time':datetime.datetime.now(datetime.timezone.utc).isoformat(),'version':version,'service':service,'enabled':user(['systemctl','--user','is-enabled','openclaw-gateway.service']),'gatewayPssMiB':round(pss['Pss']/1024,1),'gatewayRssMiB':round(pss['Rss']/1024,1),'cgroupAnonymousMiB':round(int(memory['anon'])/1048576,1),'cgroupFileMiB':round(int(memory['file'])/1048576,1),'memoryEvents':events,'hostAvailableMiB':round(meminfo['MemAvailable']/1024,1),'hostSwapUsedMiB':round((meminfo['SwapTotal']-meminfo['SwapFree'])/1024,1),'http':http,'dependencies':dependencies,'rebootRequired':Path('/var/run/reboot-required').exists(),'rootFreeGiB':round(os.statvfs('/').f_bavail*os.statvfs('/').f_frsize/1073741824,1)}
(B/'final.json').write_text(json.dumps(result,indent=2));print(json.dumps(result,indent=2))

