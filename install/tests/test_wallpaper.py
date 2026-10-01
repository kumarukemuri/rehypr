"""Validate output discovery without changing the live wallpaper or session."""
import os, subprocess, tempfile
from pathlib import Path
REPO=Path(__file__).resolve().parents[2]
SCRIPT=REPO/'dotfiles/hyprland/.config/hypr/scripts/set-wallpaper.sh'
with tempfile.TemporaryDirectory() as td:
    root=Path(td); home=root/'home';home.mkdir();bin=root/'bin';bin.mkdir();log=root/'calls'
    image=root/'wall paper.jpg';image.write_bytes(b'fixture')
    env=dict(os.environ,HOME=str(home),PATH=str(bin)+':'+os.environ['PATH'],LOG=str(log))
    commands={
        'hyprctl': '''if [ "$1" = monitors ]; then printf '%s\\n' '[{"name":"eDP-1"},{"name":"HDMI-A-2"}]'; else printf '%s\\n' "$*" >> "$LOG"; fi''',
        'matugen':'printf "matugen\\n" >> "$LOG"',
        'notify-send':'printf "%s\\n" "$*" >> "$LOG"',
    }
    for name,body in commands.items():
        p=bin/name;p.write_text('#!/bin/sh\n'+body+'\n');p.chmod(0o755)
    def run(*args):return subprocess.run(['bash',str(SCRIPT),str(image),*args],env=env,capture_output=True,text=True)
    assert run().returncode==0
    text=log.read_text();assert f'eDP-1,{image},cover' in text and f'HDMI-A-2,{image},cover' in text
    assert 'DP-1,' not in text.replace('eDP-1,','')
    log.unlink();assert run('--no-reload').returncode==0;assert log.read_text()=='matugen\n'
    (bin/'matugen').write_text('#!/bin/sh\nexit 1\n')
    log.unlink();assert run().returncode!=0
    assert 'hyprpaper wallpaper' not in log.read_text() and 'Wallpaper changed' not in log.read_text()
print('PASS: actual connected outputs, spaced paths, offline generation, generation failure stops IPC/success notification.')
