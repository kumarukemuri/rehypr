import tempfile,subprocess,shutil,os
from pathlib import Path
repo=Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory(prefix='setup-layout-') as td:
 b=Path(td);r=b/'repo';shutil.copytree(repo,r,symlinks=True,ignore=shutil.ignore_patterns('.git'))
 home=b/'home';home.mkdir();bin=b/'bin';bin.mkdir()
 packages=[]
 for name in ['core','aur']:packages += [s for s in (r/f'install/packages/{name}.txt').read_text().splitlines() if s and not s.startswith('#')]
 (b/'packages').write_text('\n'.join(packages)+'\n')
 for name,body in {'pacman':'cat "$TEST_PACKAGES"','sudo':'exit 0','yay':'exit 0','systemctl':'exit 0','xdg-user-dirs-update':'exit 0'}.items():
  p=bin/name;p.write_text('#!/bin/sh\n'+body+'\n');p.chmod(0o755)
 for p in [r/'dotfiles/hyprland/.config/hypr/colors.conf',r/'dotfiles/hyprland/.config/hypr/config/colors.lua']:p.unlink()
 env=dict(os.environ,HOME=str(home),XDG_CONFIG_HOME=str(home/'.config'),PATH=str(bin)+':'+os.environ['PATH'],TEST_PACKAGES=str(b/'packages'))
 for args in [['--dry-run'],[],[]]:
  result=subprocess.run(['bash',str(r/'install/setup.sh'),*args],cwd=b,env=env,capture_output=True,text=True)
  assert result.returncode==0,result.stdout+result.stderr
  if args:assert not list(home.iterdir())
 assert (home/'.config/hypr/colors.conf').exists()
 assert not (home/'.config/hypr/scripts/setup.sh').exists()
 assert (home/'.config/qt6ct/qt6ct.conf').exists()
 print('PASS: relocated setup dry-run, clean installation and repeated installation with real Stow/Matugen and mocked system changes.')
