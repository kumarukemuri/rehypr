from pathlib import Path
import tempfile, shutil, subprocess, os
repo=Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory(prefix='layout-test-') as td:
 base=Path(td);r=base/'repo space';shutil.copytree(repo,r,symlinks=True,ignore=shutil.ignore_patterns('.git','__pycache__'))
 home=base/'home';home.mkdir();env=dict(os.environ,HOME=str(home),XDG_STATE_HOME=str(home/'.local/state'))
 def run(*args,ok=True):
  result=subprocess.run(['bash',str(r/'install/setup.sh'),*(['--restow'] if '--migrate' not in args else []),*args],cwd=base,env=env,capture_output=True,text=True)
  if ok:assert result.returncode==0,result.stdout+result.stderr
  return result
 for text, options, code in [('0\n', [], 0), ('', [], 2), ('bad\n2\n', ['--dry-run'], 0), ('3\n', ['--dry-run'], 0)]:
  result=subprocess.run(['bash',str(r/'install/setup.sh'),*options],input=text,cwd=base,env=env,capture_output=True,text=True)
  assert result.returncode==code,result.stdout+result.stderr
  assert not list(home.iterdir())
 for options in [['--install','--restow'],['--restow','--noconfirm'],['--unknown']]:
  result=subprocess.run(['bash',str(r/'install/setup.sh'),*options],cwd=base,env=env,capture_output=True,text=True)
  assert result.returncode==2,result.stdout+result.stderr
 run('--dry-run');assert not list(home.iterdir())
 run();run();assert (home/'.config/hypr').resolve()==r/'dotfiles/hyprland/.config/hypr'
 # Recreate legacy HOME links after a pull; ignored palette files remained behind.
 for root, dirs, files in os.walk(home,followlinks=False):
  for name in dirs+files:
   p=Path(root)/name
   if p.is_symlink():
    target=Path(os.path.abspath(p.parent/os.readlink(p)))
    try:rel=target.relative_to(r/'dotfiles')
    except ValueError:continue
    p.unlink();p.symlink_to(r/rel)
 old=r/'hyprland/.config/hypr';old.mkdir(parents=True)
 old_palette=old/'colors.conf';old_palette.write_text('$image = '+str(r/'hyprland/.config/hypr/wallpapers/buds.jpg')+'\n')
 (r/'dotfiles/hyprland/.config/hypr/colors.conf').unlink()
 # Broken legacy Qt directory link.
 qt=home/'.config/qt6ct';qt.symlink_to(r/'qtct/.config/qt6ct')
 assert run(ok=False).returncode!=0
 before=os.readlink(home/'.config/hypr')
 run('--migrate','--dry-run');assert os.readlink(home/'.config/hypr')==before;assert not (home/'.local/state').exists()
 # Conflicting residual files abort before touching HOME.
 (old/'hyprland.lua').write_text('conflict')
 assert run('--migrate',ok=False).returncode!=0
 assert os.readlink(home/'.config/hypr')==before
 (old/'hyprland.lua').unlink()
 # Simulate stow execution failure after successful preflight.
 b=base/'bin';b.mkdir();p=b/'stow';real=shutil.which('stow')
 p.write_text('#!/bin/sh\ncase " $* " in *" --simulate "*) exec '+real+' "$@";; *) exit 42;; esac\n');p.chmod(0o755)
 oldpath=env['PATH'];env['PATH']=str(b)+':'+oldpath
 assert run('--migrate',ok=False).returncode!=0
 assert os.readlink(home/'.config/hypr')==before
 assert not (r/'dotfiles/hyprland/.config/hypr/colors.conf').exists()
 env['PATH']=oldpath
 run('--migrate')
 assert (home/'.config/hypr/colors.conf').is_file()
 assert str(r/'dotfiles/hyprland/.config/hypr/wallpapers/buds.jpg') in (home/'.config/hypr/colors.conf').read_text()
 assert old_palette.exists()
 assert not qt.is_symlink();assert (qt/'qt6ct.conf').exists()
 run('--migrate');run()
 print('PASS: fresh and repeated restow; legacy/dangling links; Qt recovery; dry-run; residual-file conflict; rollback after Stow failure; spaced path; repeated migration.')
