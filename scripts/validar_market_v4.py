#!/usr/bin/env python3
"""Valida arquitectura v4 sin acceder a redes ni datos confidenciales."""
from pathlib import Path
from html.parser import HTMLParser
import json, subprocess
ROOT=Path(__file__).resolve().parents[1]/'site'
class Tags(HTMLParser):
 def __init__(self): super().__init__();self.refs=[]
 def handle_starttag(self,tag,attrs):
  d=dict(attrs)
  if tag in ('img','a','script','link') and (d.get('src') or d.get('href')):self.refs.append(d.get('src') or d.get('href'))
for name in ('index.html','menu.html','market.html'):
 path=ROOT/name
 assert path.is_file(),name
 body=path.read_text(encoding='utf-8')
 assert '<html lang="es">' in body and 'noindex' in body
 p=Tags();p.feed(body)
 for url in p.refs:
  if url.startswith(('http://','https://','mailto:','tel:','#','data:')):continue
  url=url.split('#')[0].split('?')[0]
  if url:assert (ROOT/url).is_file(),(name,url)
 if name!='index.html':
  # Node verifies the inline application script without loading the DOM.
  import re, tempfile
  script=re.findall(r'<script>(.*?)</script>',body,re.S)
  assert len(script)==1,name
  with tempfile.NamedTemporaryFile(mode='w',suffix='.js') as f:
   f.write(script[0]);f.flush()
   subprocess.run(['node','--check',f.name],check=True)
 assert 'ROOTS & ROUTES' in body
for name,expected in [('menu_digital.json',49),('productos.json',1361)]:
 a=json.loads((ROOT/name).read_text(encoding='utf-8'))
 assert len(a)==expected,(name,len(a))
 assert all(isinstance(x,dict) for x in a)
assert 'market.html' in (ROOT/'index.html').read_text(encoding='utf-8')
assert 'menu.html' in (ROOT/'index.html').read_text(encoding='utf-8')
print('ROOTS_V4_SITE_PASS: navegación, 3 páginas, JS y datos')
