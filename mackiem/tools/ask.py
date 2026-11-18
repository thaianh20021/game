# Asks a second model on the owner's router (default: Gemini 4 hydrogen (medium reasoning) through Antigravity) and prints its answer.
# Usage: MK_KEYS="key" python tools/ask.py <prompt file> [model]   (the key is read from the environment only)
# Not streamed: with long prompts the streamed answer of the Gemini models came back empty.
import json
import os
import sys
import urllib.request

key = (os.environ.get('MK_KEYS') or os.environ.get('MK_KEY') or '').split()[0]
model = sys.argv[2] if len(sys.argv) > 2 else 'ag/gemini-4-hydrogen-medium'
prompt = open(sys.argv[1], encoding='utf-8').read()
body = json.dumps({'model': model, 'stream': False, 'max_tokens': 32000,
                   'messages': [{'role': 'user', 'content': prompt}]}).encode()
req = urllib.request.Request('https://thaianhdev.loc.cc/v1/chat/completions', data=body,
                             headers={'Authorization': 'Bearer ' + key, 'Content-Type': 'application/json'})
with urllib.request.urlopen(req, timeout=900) as r:
    d = json.loads(r.read().decode('utf-8', 'replace'))
c = d['choices'][0]
sys.stdout.reconfigure(encoding='utf-8')
print(c['message'].get('content') or '')
sys.stderr.write('finish=%s usage=%s\n' % (c.get('finish_reason'), d.get('usage')))
