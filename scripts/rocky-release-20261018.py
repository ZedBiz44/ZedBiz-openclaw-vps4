"""Protected native Rocky maintenance stages; no secret output."""
import os, sys, json, subprocess, hashlib, sqlite3, time
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
else:raise ValueError(action)

