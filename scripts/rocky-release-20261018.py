"""Protected native Rocky maintenance stages; no secret output."""
import os, sys, json, subprocess, hashlib, sqlite3, time, urllib.request
from pathlib import Path
B=Path('/var/backups/rocky-20261018')
S=Path('/home/openclaw/.openclaw')
P=Path('/home/openclaw/.npm-global/lib/node_modules/openclaw')
CLI='/home/openclaw/.npm-global/bin/openclaw'
os.umask(0o077)
ENV=json.loads((B/'runtime-env.json').read_text())
ENV.update(HOME='/home/openclaw',XDG_RUNTIME_DIR='/run/user/1000',DBUS_SESSION_BUS_ADDRESS='unix:path=/run/user/1000/bus')
def demote():
    os.setgroups([1000]);os.setgid(1000);os.setuid(1000)
def emit(o):print(json.dumps(o),flush=True)
def sha(p):
    with Path(p).open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
def user(args,**kw):return subprocess.run(args,env=ENV,preexec_fn=demote,cwd='/home/openclaw',**kw)
def service(action,*args):return user(['systemctl','--user',action,'openclaw-gateway.service',*args],check=True,capture_output=True,text=True,timeout=360).stdout
def cli(label,args,timeout=300):
    with (B/(label+'.log')).open('w') as f:r=user([CLI,*args],stdout=f,stderr=subprocess.STDOUT,timeout=timeout)
    emit({'step':label,'exit':r.returncode});assert r.returncode==0,'Inspect protected '+label+'.log'
    return (B/(label+'.log')).read_text()
def obj(t):return json.JSONDecoder().raw_decode(t[t.index('{'):])[0]
action=sys.argv[1]
if action=='backup':
    status=obj(cli('status-backup',['gateway','call','status','--json']))
    active=status.get('shutdownBudget',{}).get('activeWork');assert active and all(v==0 for v in active.values())
    assert not (B/'before.tar.gz').exists()
    service('stop');assert service('show','--value','-p','MainPID').strip()=='0'
    emit({'stopped':True})
    subprocess.run(['tar','-C','/','-czf',str(B/'before.tar.gz'),'home/openclaw/.openclaw','home/openclaw/.npm-global','home/openclaw/.config/systemd','home/openclaw/bin'],check=True,timeout=1800)
    subprocess.run(['tar','-tzf',str(B/'before.tar.gz')],stdout=subprocess.DEVNULL,check=True)
    dest=B/'extracted';dest.mkdir()
    subprocess.run(['tar','-xzf',str(B/'before.tar.gz'),'-C',str(dest)],check=True,timeout=1800)
    root=dest/'home/openclaw/.openclaw';checked=[]
    for p in [root/'state/openclaw.sqlite',*root.glob('agents/*/agent/openclaw-agent.sqlite')]:
        with sqlite3.connect('file:'+str(p)+'?mode=ro',uri=True) as db:
            db.create_function('octet_length',1,lambda x:len(x.encode() if isinstance(x,str) else x),deterministic=True)
            assert db.execute('pragma quick_check').fetchall()==[('ok',)]
        checked.append(str(p.relative_to(root)))
    assert sha(root/'openclaw.json')==sha(S/'openclaw.json')
    recipient=Path('/etc/rocky-hindsight/backup-age-recipient.txt').read_text().strip()
    subprocess.run(['age','-r',recipient,'-o',str(B/'before.tar.gz.age'),str(B/'before.tar.gz')],check=True,timeout=900)
    h=hashlib.sha256();proc=subprocess.Popen(['age','-d','-i','/etc/rocky-hindsight/backup-age.key',str(B/'before.tar.gz.age')],stdout=subprocess.PIPE)
    while chunk:=proc.stdout.read(1024*1024):h.update(chunk)
    assert proc.wait()==0 and h.hexdigest()==sha(B/'before.tar.gz')
    result={'archiveSha256':h.hexdigest(),'encryptedSha256':sha(B/'before.tar.gz.age'),'databasesChecked':checked,'configSha256':sha(S/'openclaw.json')}
    (B/'backup.json').write_text(json.dumps(result,indent=2));emit(result)
    service('start');emit({'originalServiceRestarted':True})
elif action=='update':
    assert (B/'backup.json').exists() and (B/'offhost-verified.json').exists()
    cli('update',['update','--tag','2026.10.4','--yes','--no-restart','--json'],3600)
elif action=='cli':
    cli(sys.argv[2],sys.argv[3:],900)
elif action=='compare':
    old=B/'extracted/home/openclaw/.openclaw'
    a=json.loads((old/'openclaw.json').read_text());c=json.loads((S/'openclaw.json').read_text())
    for k in ['model','models','modelPolicy','thinkingDefault','timeoutSeconds']:
        assert a['agents']['defaults'].get(k)==c['agents']['defaults'].get(k),'Model policy drift: '+k
    for k in ['tools','channels','mcp','secrets']:
        assert a.get(k)==c.get(k),'Access/configuration drift: '+k
    assert a.get('gateway',{}).get('auth')==c.get('gateway',{}).get('auth')
    assert c.get('gateway',{}).get('bind')=='loopback'
    assert a['plugins']['slots']==c['plugins']['slots']
    memory=a['plugins']['slots']['memory']
    assert a['plugins']['entries'][memory]==c['plugins']['entries'][memory]
    for f in ['AGENTS.md','SOUL.md','USER.md','IDENTITY.md']:
        assert (old/'workspace'/f).read_bytes()==(S/'workspace'/f).read_bytes(),'Instruction drift: '+f
    before={str(p.relative_to(old/'workspace/skills')):sha(p) for p in (old/'workspace/skills').rglob('*') if p.is_file()}
    after={str(p.relative_to(S/'workspace/skills')):sha(p) for p in (S/'workspace/skills').rglob('*') if p.is_file()}
    assert before==after,'Custom skill drift'
    for tree in ['bin','.config/systemd']:
        for p in (B/'extracted/home/openclaw'/tree).rglob('*'):
            if p.is_file():assert p.read_bytes()==(Path('/home/openclaw')/p.relative_to(B/'extracted/home/openclaw')).read_bytes(),'Launcher/service drift'
    r={'preservationPassed':True,'customSkillFiles':len(before)}
    (B/'preservation.json').write_text(json.dumps(r));emit(r)
elif action=='accept':
    deadline=time.monotonic()+420
    while True:
        try:
            if urllib.request.urlopen('http://127.0.0.1:18789/healthz',timeout=5).status==200:break
        except Exception:pass
        assert time.monotonic()<deadline,'HTTP readiness deadline exceeded'
        time.sleep(5)
    deadline=time.monotonic()+120
    while True:
        health=obj(cli('health-after',['gateway','call','health','--json']))
        old=json.loads((B/'health-before.json').read_text());pending=[]
        for channel,d in old.get('channels',{}).items():
            for account,v in d.get('accounts',{}).items():
                now=health.get('channels',{}).get(channel,{}).get('accounts',{}).get(account,{})
                for field in ['running','connected']:
                    if v.get(field) is True and now.get(field) is not True:pending.append(channel+'/'+field)
        if not pending:break
        assert time.monotonic()<deadline,'Channel readiness deadline exceeded'
        time.sleep(5)
    cron=obj(cli('cron-after',['gateway','call','cron.list','--params','{"includeDisabled":true}','--json']))
    keys=['id','name','enabled','schedule','sessionTarget','wakeMode','payload','delivery']
    norm=lambda o:sorted([{k:j.get(k) for k in keys} for j in o['jobs']],key=lambda j:j['id'])
    assert norm(cron)==norm(json.loads((B/'cron-before.json').read_text()))
    prompt='Read-only upgrade acceptance. Use agent_knowledge_recall explicitly to recall one existing ZedBiz memory from your configured Hindsight backend, not local Markdown. Get your own Asana user identity and fetch Notion page 371a3e33d5818357872d0198ecade27d. Check availability of gog, himalaya, ffmpeg and gh with a harmless shell command. Return memory tool and short fact, Asana name/GID, Notion title, binary availability and any failure. Do not send messages, create tasks, change files, write memories, run paid generation or delegate.'
    result=obj(cli('capability',['agent','--agent','main','--session-key','agent:main:cody-vps4-10-4-acceptance','--message',prompt,'--timeout','240','--json'],300))
    receipt=result.get('result',{}).get('meta',{}).get('agentMeta',{}).get('terminalReceipt',{})
    assert receipt.get('rerouted') is False and receipt['effective']['model']=='gpt-6.1-sol'
    names=receipt.get('successfulToolNames',[])
    assert any('agent_knowledge_recall' in n for n in names) and any('asana' in n and 'user' in n for n in names) and any('notion' in n for n in names)
    r={'accepted':True,'cronCount':len(cron['jobs']),'receipt':receipt,'payloads':result['result'].get('payloads'),'channels':{k:{a:{f:v.get(f) for f in ['running','connected','lastError']} for a,v in d.get('accounts',{}).items()} for k,d in health.get('channels',{}).items()}}
    (B/'acceptance.json').write_text(json.dumps(r,indent=2));emit(r)
elif action=='skills':
    o=obj(cli('skills-after',['skills','check','--agent','main','--json']))
    (B/'skills-after.json').write_text(json.dumps(o,indent=2));emit({'summary':o.get('summary'),'missingRequirements':o.get('missingRequirements')})
else:raise ValueError(action)

