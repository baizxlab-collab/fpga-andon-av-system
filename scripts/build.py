"""Build a protected board project with Anlogic TD 6.2.1 (Python 3.9+)."""
from pathlib import Path
import argparse, json, os, shutil, subprocess, sys
import xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parents[1]
def build(board,td,stage):
    board=board.upper()
    work=ROOT/'build'/board
    work.mkdir(parents=True,exist_ok=True)
    template=ROOT/'boards'/board/(board+'.al')
    project=ET.parse(template)
    project.getroot().set('Path',work.as_posix())
    for node in project.findall('.//Source_Files/*/File'):
        p=(template.parent/node.attrib['Path']).resolve()
        if not p.is_file():raise FileNotFoundError(p)
        node.set('Path',p.as_posix())
    top=project.findtext('.//TOP_MODULE/MODULE')
    config=work/(top+'.prj')
    project.write(config,encoding='utf-8',xml_declaration=True)
    for p in (ROOT/'memory'/board).glob('*'):shutil.copy2(p,work/p.name)
    adc=next(f.attrib['Path'] for f in project.findall('.//ADC_FILE/File'))
    sdc=next(f.attrib['Path'] for f in project.findall('.//SDC_FILE/File'))
    settings=json.loads((ROOT/'verification/build_settings.json').read_text(encoding='utf-8'))[board]
    lines=['if {[catch {','import_device eagle_s20.db -package EG4S20BG256',
           'open_project {'+config.as_posix()+'}', 'commit_param -step design',
           'elaborate -top '+top,'read_adc {'+adc+'}','read_sdc {'+sdc+'}']
    if stage in ('synth','bit'):
        lines += settings['synthesis']
    if stage=='bit':
        lines += settings['physical']
    lines += ['puts {PROTECTED_BUILD_PASS_'+board+'_'+stage+'}',
              '} failure]} {puts stderr $failure; exit 1}','exit 0']
    script=work/'build.tcl';script.write_text('\n'.join(lines),encoding='utf-8')
    log=work/(stage+'.log')
    with log.open('wb') as f:
        rc=subprocess.run([str(td/'bin/td_commands_prompt.exe'),script.as_posix()],cwd=work,stdout=f,stderr=subprocess.STDOUT).returncode
    txt=log.read_text(encoding='utf-8',errors='replace')
    ok=rc==0 and ('PROTECTED_BUILD_PASS_'+board+'_'+stage) in txt and 'ERROR:' not in txt
    result={'board':board,'stage':stage,'passed':ok,'tool_returncode':rc,'log':log.relative_to(ROOT).as_posix()}
    (work/(stage+'_result.json')).write_text(json.dumps(result,indent=2),encoding='utf-8')
    print(json.dumps(result),flush=True)
    if not ok:
        print(txt[-7000:]);raise RuntimeError('TD build failed for '+board)
    if stage=='bit':
        import re
        timing=(work/(top+'_pr.timing')).read_text(encoding='utf-8',errors='replace')
        for name in ['SWNS','HWNS']:
            match=re.search(name+r':\s*([-+0-9.]+)ns',timing)
            if not match or float(match.group(1))<0:raise RuntimeError('Timing check failed: '+name)
        if not ('start command "drc_check -all"' in txt and 'No multi-drive.' in txt and 'No abnormal timing path.' in txt):
            raise RuntimeError('Cannot confirm final DRC result; review log before bit generation')
        tcl=work/'bitgen_checked.tcl'
        tcl.write_text('if {[catch {\nimport_device eagle_s20.db -package EG4S20BG256\nopen_project {'+config.as_posix()+'} -noanalyze\nimport_db '+top+'_pr.db\ncommit_param -step bitgen\nbitgen -bit '+top+'.bit\nputs {PROTECTED_BITGEN_PASS}\n} failure]} {puts stderr $failure; exit 1}\nexit 0\n',encoding='utf-8')
        with (work/'bitgen_checked.log').open('wb') as f:
            rc=subprocess.run([str(td/'bin/td_commands_prompt.exe'),tcl.as_posix()],cwd=work,stdout=f,stderr=subprocess.STDOUT).returncode
        logtxt=(work/'bitgen_checked.log').read_text(encoding='utf-8',errors='replace')
        if rc or 'PROTECTED_BITGEN_PASS' not in logtxt or 'ERROR:' in logtxt:raise RuntimeError('Bit generation failed')
    return result

if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--board',required=True,choices=list('ABCD'))
    p.add_argument('--td',default=os.environ.get('TD_HOME','D:/Anlogic/TD6.2.1'))
    p.add_argument('--stage',choices=['elaborate','synth','bit'],default='synth')
    a=p.parse_args();build(a.board,Path(a.td),a.stage)
