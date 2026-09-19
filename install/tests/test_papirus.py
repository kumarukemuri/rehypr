"""Check the monochrome fork and real Matugen hook without touching the live theme."""
import json
import os
from pathlib import Path
import runpy
import subprocess
import tempfile
import tomllib
import xml.etree.ElementTree as ET

REPO = Path(__file__).resolve().parents[2]
MATUGEN = REPO / 'dotfiles/matugen/.config/matugen'
module = runpy.run_path(str(MATUGEN / 'scripts/papirus.py'))
manifest = json.loads((module['SOURCE'] / 'manifest.json').read_text())
with tempfile.TemporaryDirectory(prefix='rehypr-icons-test-') as td:
    root = Path(td)
    output = root / 'data/icons/Rehypr-Papirus'
    assert module['generate'](module['SOURCE'], output, '#123abc')
    folder = output / '16x16/places/folder-blue.svg'
    assert '#123abc' in folder.read_text()
    for size in (22, 24, 32, 48, 64):
        for name in ('folder-blue', 'folder-blue-download', 'folder-blue-documents'):
            svg = (output / f'{size}x{size}/places/{name}.svg').read_text()
            assert '#123abc' in svg and '#0e2d93' in svg
            assert '#5294e2' not in svg and '#e4e4e4' in svg
            assert '@PRIMARY@' not in svg and '@DARK@' not in svg and '@EMBLEM@' not in svg
    assert '#061442' in (output / '48x48/places/folder-blue-download.svg').read_text()
    assert '48x48/places/folder-red.svg' not in manifest['icons']
    templates = set()
    alias = None
    for name, template in manifest['icons'].items():
        target = output / name
        assert target.is_file(), name
        if template in templates:
            assert target.is_symlink(), name
            alias = target
        else:
            assert not target.is_symlink(), name
            ET.fromstring(target.read_text())
        templates.add(template)
    inode = alias.lstat().st_ino
    index_mtime = (output / 'index.theme').stat().st_mtime_ns
    assert module['generate'](module['SOURCE'], output, '#80d4dc')
    assert alias.lstat().st_ino == inode
    assert (output / 'index.theme').stat().st_mtime_ns == index_mtime
    assert '#80d4dc' in folder.read_text()
    stamp = folder.stat().st_mtime_ns
    assert not module['generate'](module['SOURCE'], output, '#80d4dc')
    assert folder.stat().st_mtime_ns == stamp
    try:
        module['generate'](module['SOURCE'], output, 'invalid')
        raise AssertionError('Invalid color accepted')
    except ValueError:
        pass
    config = root / '.config'
    config.mkdir()
    (config / 'matugen').symlink_to(MATUGEN)
    qt = config / 'qt6ct/qt6ct.conf'
    qt.parent.mkdir()
    qt.write_text('[Appearance]\nstyle=Fusion\n[Fonts]\ngeneral=Keep me\n')
    template = tomllib.loads((MATUGEN / 'config.toml').read_text())['templates']['papirus']
    isolated = root / 'matugen.toml'
    isolated.write_text('[config]\n[templates.papirus]\n' + '\n'.join(f'{k} = {json.dumps(v)}' for k, v in template.items()))
    env = dict(os.environ, HOME=str(root), XDG_CONFIG_HOME=str(config), XDG_DATA_HOME=str(root/'data'))
    env.pop('DBUS_SESSION_BUS_ADDRESS', None)
    subprocess.run(['matugen', '-c', str(isolated), 'color', 'hex', '#80d4dc'], env=env, check=True)
    assert 'icon_theme=Rehypr-Papirus' in qt.read_text()
    assert 'general=Keep me' in qt.read_text()
    assert 'gtk-icon-theme-name=Rehypr-Papirus' in (config/'gtk-3.0/settings.ini').read_text()
print('PASS: SVGs, aliases, preserved size variants, incremental updates, unchanged palette, validation and Matugen activation')
