#!/usr/bin/env python3
"""Auditoría reproducible de contenido web estático con biblioteca estándar."""
from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urlsplit
import json, re, subprocess, tempfile, sys

BASE = Path(__file__).resolve().parent.parent / 'site'
class Inspector(HTMLParser):
    def __init__(self):
        super().__init__(); self.refs=[]; self.ids=[]; self.scripts=[];self.active_script=None
    def handle_starttag(self, tag, attrs):
        kv=dict(attrs)
        if kv.get('id'): self.ids.append(kv['id'])
        if tag in ('img','script','link','a','iframe'):
            u=kv.get('src',kv.get('href'))
            if u: self.refs.append((tag,u))
        if tag=='script': self.active_script={'type':kv.get('type'),'text':''}
    def handle_data(self, data):
        if self.active_script is not None:self.active_script['text']+=data
    def handle_endtag(self,tag):
        if tag=='script' and self.active_script is not None:
            self.scripts.append(self.active_script);self.active_script=None

failures=[];warnings=[]
def require(cond,msg):
    if not cond:failures.append(msg)
html=BASE/'index.html'
require(html.exists(),'Falta index.html')
if html.exists():
    body=html.read_text(encoding='utf8')
    parsed=Inspector();parsed.feed(body)
    require(len(parsed.scripts)>=3,'Scripts principales ausentes')
    require(len(set(parsed.ids))==len(parsed.ids),'IDs HTML duplicados')
    for tag,url in parsed.refs:
        if url.startswith(('#','mailto:','tel:','https://','http://','data:','${')):continue
        if '?' in url:url=url.split('?',1)[0]
        require((BASE/url).is_file(),f'Recurso local inexistente: {tag}: {url}')
    for i,part in enumerate(parsed.scripts):
        if part['type'] and part['type'] not in ('text/javascript','module'):continue
        with tempfile.NamedTemporaryFile(mode='w',suffix='.js',encoding='utf8') as tmp:
            tmp.write(part['text']);tmp.flush()
            try:
                result=subprocess.run(['node','--check',tmp.name],capture_output=True,text=True)
            except FileNotFoundError:
                warnings.append('Node no instalado: omitida validación de sintaxis JS');break
            require(result.returncode==0, f'Script JS {i} inválido: {result.stderr[:300]}')
    require('noindex' in body.lower(),'Falta noindex para entorno staging')
    try:
        branches=json.loads(re.search(r'const BRANCHES=(\[.*?\]);',body,re.S).group(1))
        require(len(branches)==5, f'Sucursales esperadas: 5, encontradas: {len(branches)}')
    except Exception as exc: failures.append('No se pueden analizar las sucursales: '+str(exc))
    wa=re.search(r"const WA='(\d+)'",body)
    if wa:
        num=wa.group(1)
        if not re.fullmatch(r'5939\d{8}',num):
            warnings.append('WhatsApp no validado: '+num+' no se ajusta a la longitud móvil habitual de Ecuador')
    else:warnings.append('No se identificó número WhatsApp')
    try:
        m=json.loads((BASE/'menu_digital.json').read_text(encoding='utf8'))
        require(len(m)==49,f'Menú digital inesperado: {len(m)}')
    except Exception as exc: failures.append('Menú inválido: '+str(exc))
    try:
        prod=json.loads((BASE/'productos.json').read_text(encoding='utf8'))
        require(len(prod)==1361,f'Productos inesperados: {len(prod)}')
    except Exception as exc: failures.append('Catálogo inválido: '+str(exc))
    warnings.append('Direcciones, precios y condiciones promocionales aún requieren confirmación comercial')
require((BASE/'robots.txt').exists(), 'Falta robots staging')
print('RESULTADO VALIDACIÓN:', 'APROBADO TÉCNICO ESTÁTICO' if not failures else 'NO APROBADO')
for x in failures:print('ERROR:',x)
for x in warnings:print('AVISO:',x)
sys.exit(1 if failures else 0)
