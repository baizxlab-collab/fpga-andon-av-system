"""Verify published files, protected HDL, local links and board dependencies."""
from pathlib import Path
import re,json,hashlib,xml.etree.ElementTree as ET
from urllib.parse import unquote,urlsplit
ROOT=Path(__file__).resolve().parents[1]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def files():
    return [p for p in ROOT.rglob('*') if p.is_file() and not any(x in ('.git','build','__pycache__') for x in p.relative_to(ROOT).parts)]
def main():
    manifest=ROOT/'SHA256SUMS.txt'
    if not manifest.exists():raise RuntimeError('Missing SHA256SUMS.txt')
    recorded={}
    for line in manifest.read_text(encoding='utf-8').splitlines():
        h,n=line.split('  ',1)
        p=(ROOT/n).resolve()
        assert p.is_relative_to(ROOT) and p.is_file(),n
        assert sha(p)==h,'Hash mismatch: '+n
        recorded[n]=h
    actual={p.relative_to(ROOT).as_posix() for p in files() if p!=manifest}
    assert actual==set(recorded),(actual-set(recorded),set(recorded)-actual)
    hdl=json.loads((ROOT/'verification/encryption_manifest.json').read_text(encoding='utf-8'))
    assert len(hdl)==317
    for n,r in hdl.items():
        p=ROOT/r['file'];assert sha(p)==r['encrypted_sha256'],n
        text=p.read_text(encoding='utf-8')
        assert 'anlogic-rsa-009' in text and 'MGC-VERIF-SIM-RSA-1' in text,n
        assert text.count('`pragma protect begin_protected')==text.count('`pragma protect end_protected')==1,n
        outside=re.sub(r'`pragma protect begin_protected.*?`pragma protect end_protected','',text,flags=re.S)
        outside=re.sub(r'//[^\n]*','',outside)
        assert not outside.strip(),'Unprotected content in '+n
    assert not any(p.suffix.lower() in ('.v','.sv','.vh','.vhd','.vhdl','.db') for p in files()),'Unexpected plaintext HDL or build database'
    for b in 'ABCD':
        p=ROOT/'boards'/b/(b+'.al')
        for f in ET.parse(p).findall('.//Source_Files/*/File'):
            q=(p.parent/f.attrib['Path']).resolve()
            assert q.is_relative_to(ROOT) and q.is_file(),q
    links=0
    for p in files():
        if p.suffix.lower()!='.md':continue
        t=p.read_text(encoding='utf-8')
        refs=re.findall(r'\]\(([^)]+)\)',t)+re.findall(r'(?:src|href)="([^"]+)"',t)
        for ref in refs:
            u=urlsplit(ref)
            if u.scheme or not u.path:continue
            q=(p.parent/unquote(u.path)).resolve()
            assert q.is_relative_to(ROOT) and q.exists(),(p.name,ref)
            links+=1
    for p in files():
        if p.suffix in ('.md','.py','.json','.al','.adc','.sdc','.txt','.yml','.html'):
            t=p.read_text(encoding='utf-8',errors='replace')
            assert not re.search(r'(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,}|-----BEGIN (?:RSA |OPENSSH )?PRIVATE KEY-----)',t),p
            assert ('D:'+'/Codex/'+'projects/') not in t and ('C:'+'/Users/') not in t and ('C:'+'\\Users'+'\\') not in t,p
    result={'passed':True,'files':len(actual)+1,'encrypted_hdl_files':len(hdl),'local_document_links':links,'board_projects':4}
    print(json.dumps(result,ensure_ascii=False))
if __name__=='__main__':main()
