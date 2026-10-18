"""Restore the existing keyring and draft-only wrapper, preserving GOG 0.43.0."""
import os, hashlib, json, shutil, subprocess
from pathlib import Path
B = Path('/var/backups/rocky-20261018')
wrapper = Path('/home/openclaw/bin/gog')
binary = Path('/home/openclaw/.local/secure-bin/gog-real-0.43.0-20261018')
expected = 'f455948670f8ae9b1f60250e9a6407cb92fb90382ef040cc70c73742cb0afa5f'
def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()
assert (B/'preservation.json').exists()
assert sha(wrapper) == expected
assert Path('/home/openclaw/.config/gogcli/email-mode').read_text().strip() == 'draft_only'
assert not binary.exists()
shutil.copyfile(wrapper, binary)
os.chown(binary, 0, 0)
binary.chmod(0o755)
assert sha(binary) == expected
text = '''#!/usr/bin/env bash
set -euo pipefail
export HOME=/home/openclaw
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
set -a
source /home/openclaw/.config/gogcli/keyring.env
set +a
email_mode_file=/home/openclaw/.config/gogcli/email-mode
if [[ -r "$email_mode_file" ]] && [[ "$(tr -d '\\r\\n' < "$email_mode_file")" == draft_only ]]; then
  set -- --gmail-no-send "$@"
fi
exec /home/openclaw/.local/secure-bin/gog-real-0.43.0-20261018 "$@"
'''
test = B/'gog-wrapper-test.sh'
test.write_text(text.replace('exec '+str(binary)+' "$@"', '''[[ -n "${GOG_KEYRING_PASSWORD:-}" ]] && [[ "$1" == --gmail-no-send ]] && echo guard-and-keyring-pass'''))
r = subprocess.run(['bash', str(test), 'drive', 'get'], capture_output=True, text=True, check=True)
assert r.stdout.strip() == 'guard-and-keyring-pass'
stage = wrapper.with_name('gog.cody-stage')
stage.write_text(text)
os.chown(stage, 1000, 1000)
stage.chmod(0o700)
stage.replace(wrapper)
def demote():
    os.setgroups([1000]); os.setgid(1000); os.setuid(1000)
env = os.environ.copy()
env.pop('GOG_KEYRING_PASSWORD', None)
env['HOME'] = '/home/openclaw'
r = subprocess.run([str(wrapper), '--account', 'jack@zbiz.work', 'drive', 'get', '1WwcUydKp99SdWaezifjYnrYMjiuC99Sk', '--fields', 'id,size', '--json'], env=env, preexec_fn=demote, cwd='/home/openclaw', capture_output=True, text=True, check=True)
data = json.loads(r.stdout)
assert int(data.get('file', data)['size']) == 7018879122
receipt = {'binarySha256': expected, 'wrapperSha256': sha(wrapper), 'keyringAndDraftGuardTest': 'passed', 'runtimeDriveRead': 'passed', 'version': '0.43.0'}
(B/'gog-repair.json').write_text(json.dumps(receipt, indent=2))
print(json.dumps(receipt))

