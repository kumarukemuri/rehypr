import tempfile,subprocess,shutil,os,configparser
from pathlib import Path
repo=Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory(prefix='setup-layout-') as td:
 b=Path(td);r=b/'repo';shutil.copytree(repo,r,symlinks=True,ignore=shutil.ignore_patterns('.git'))
 home=b/'home';home.mkdir();bin=b/'bin';bin.mkdir()
 packages=[]
 for name in ['core','aur']:packages += [s for s in (r/f'install/packages/{name}.txt').read_text().splitlines() if s and not s.startswith('#')]
 (b/'packages').write_text('\n'.join(packages)+'\n')
 for name,body in {'pacman':'cat "$TEST_PACKAGES"','sudo':'exit 0','yay':'exit 0','systemctl':'exit 0','gsettings':'exit 0','xdg-user-dirs-update':'exit 0'}.items():
  p=bin/name;p.write_text('#!/bin/sh\n'+body+'\n');p.chmod(0o755)
 for p in [r/'dotfiles/hyprland/.config/hypr/colors.conf',r/'dotfiles/hyprland/.config/hypr/config/colors.lua']:p.unlink()
 env=dict(os.environ,HOME=str(home),XDG_CONFIG_HOME=str(home/'.config'),PATH=str(bin)+':'+os.environ['PATH'],TEST_PACKAGES=str(b/'packages'))
 for args in [['--dry-run'],[],[]]:
  result=subprocess.run(['bash',str(r/'install/setup.sh'),'--install',*args],cwd=b,env=env,capture_output=True,text=True)
  assert result.returncode==0,result.stdout+result.stderr
  if args:
   assert not list(home.iterdir())
   continue
  for version in (3,4,5,6):
   gtk=version<5
   path=home/'.config'/(f'gtk-{version}.0/settings.ini' if gtk else f'qt{version}ct/qt{version}ct.conf')
   settings=configparser.ConfigParser(interpolation=None);settings.read(path)
   if gtk:
    assert settings['Settings']['gtk-font-name']=='JetBrainsMono Nerd Font Propo 14'
   else:
    defaults=configparser.ConfigParser(interpolation=None)
    defaults.read(r/f'install/templates/qtct/qt{version}ct.conf.in')
    for key,family in (('general','JetBrainsMono Nerd Font Propo'),('fixed','JetBrainsMono Nerd Font')):
     assert settings['Fonts'][key]==defaults['Fonts'][key]
     parts=settings['Fonts'][key].strip('"').split(',')
     assert parts[:2]==[family,'14']
     assert len(parts)==(10 if version==5 else 19)
     assert parts[4]==('50' if version==5 else '400')
     assert parts[5]=='0'
     if version==6:assert parts[16]=='Regular'
    if settings.has_option('Interface','test_preference'):
     assert settings['Interface']['test_preference']=='retained'
     assert settings['Interface']['wheel_scroll_lines']=='7'
    settings['Interface']['test_preference']='retained'
    settings['Interface']['wheel_scroll_lines']='7'
    settings['Fonts']['general']='"Sans,9,-1,5,50,0,0,0,0,0"'
    settings['Fonts']['fixed']='"Monospace,9,-1,5,50,0,0,0,0,0"'
    with path.open('w') as stream:settings.write(stream)
 assert (home/'.config/hypr/colors.conf').exists()
 assert not (home/'.config/hypr/scripts/setup.sh').exists()
 assert (home/'.config/qt6ct/qt6ct.conf').exists()
 print('PASS: relocated setup dry-run, clean installation and repeated installation with real Stow/Matugen and mocked system changes.')
