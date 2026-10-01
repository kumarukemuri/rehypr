"""Offline regressions: SSH trust preservation and wallpaper template injection."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

REPO = Path(__file__).resolve().parents[2]
SETTER = REPO / 'dotfiles/hyprland/.config/hypr/scripts/set-wallpaper.sh'
TEMPLATE = REPO / 'dotfiles/matugen/.config/matugen/templates/hyprland-colors.lua'
with tempfile.TemporaryDirectory(prefix='rehypr-security-') as td:
    root = Path(td)
    bin_dir = root / 'bin'; bin_dir.mkdir()
    log = root / 'calls'
    env = dict(os.environ, HOME=str(root), PATH=str(bin_dir)+':'+os.environ['PATH'],
               AUDIT_LOG=str(log), AUDIT_REPO=str(REPO))
    for name, body in {
        'ssh': 'printf "%s\\n" "$@" >> "$AUDIT_LOG"; exit 255',
        'ssh-keygen': 'printf "UNEXPECTED-KEY-CHANGE\\n" >> "$AUDIT_LOG"; exit 99',
        'ssh-keyscan': 'printf "UNEXPECTED-SCAN\\n" >> "$AUDIT_LOG"; exit 99',
        'matugen': 'printf "UNEXPECTED-MATUGEN\\n" >> "$AUDIT_LOG"',
        'notify-send': 'exit 0',
    }.items():
        path = bin_dir / name
        path.write_text('#!/bin/sh\n'+body+'\n'); path.chmod(0o755)
    source = 'source "$AUDIT_REPO/dotfiles/fish/.config/fish/functions/rcssh.fish"; rcssh $argv'
    result = subprocess.run(['fish', '--no-config', '-c', source, '--', 'user@vm.ru-central1.internal', 'uptime'], env=env, capture_output=True)
    assert result.returncode == 255  # Changed-key failure must propagate.
    assert log.read_text().splitlines() == ['-o','StrictHostKeyChecking=ask','--','user@vm.ru-central1.internal','uptime']
    log.unlink()
    for dest in ('-oProxyCommand=bad@vm.ru-central1.internal', 'host.example.org', 'x;bad.ru-central1.internal'):
        result = subprocess.run(['fish','--no-config','-c',source,'--',dest],env=env,capture_output=True)
        assert result.returncode == 2 and not log.exists()
    for name in ('quote".jpg', 'line\nbreak.jpg', 'back\\slash.jpg', 'variable$.jpg', 'comment#.jpg', 'comma,.jpg'):
        image = root / name; image.write_bytes(b'fixture')
        result = subprocess.run(['bash',str(SETTER),str(image),'--no-reload'],env=env,capture_output=True)
        assert result.returncode != 0 and not log.exists(), name

    # Exercise real Matugen/Lua without reading or writing live config.
    if shutil.which('matugen') and shutil.which('lua'):
        image = root / 'x" .. (function() _G.REHYPR_AUDIT_MARKER = true return "" end)() .. ".jpg'
        shutil.copyfile(next((REPO/'dotfiles/hyprland/.config/hypr/wallpapers').glob('*.jpg')), image)
        output = root / 'colors.lua'
        config = root / 'matugen.toml'
        config.write_text('[config]\n[templates.audit]\ninput_path = '+json.dumps(str(TEMPLATE))+'\noutput_path = '+json.dumps(str(output))+'\n')
        subprocess.run(['matugen','-c',str(config),'image','--prefer','darkness',str(image)],check=True,capture_output=True)
        subprocess.run(['lua','-e','local colors=dofile('+json.dumps(str(output))+'); assert(REHYPR_AUDIT_MARKER == nil); assert(colors.background ~= nil)'],check=True)
print('PASS: SSH changed-key failures preserved, option injection rejected, unsafe wallpaper paths blocked, Lua filename injection removed.')
