#!/usr/bin/env python3
"""Render the vendored monochrome Papirus fork when Matugen changes its palette."""
import argparse
import configparser
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

SOURCE = Path(__file__).resolve().parent.parent / 'papirus'
NAME = 'Rehypr-Papirus'


def generate(source, destination, primary):
    if not re.fullmatch(r'#[0-9a-fA-F]{6}', primary):
        raise ValueError('Expected a six-digit primary color')
    manifest_bytes = (source / 'manifest.json').read_bytes()
    manifest = json.loads(manifest_bytes)
    templates = {name: (source / name).read_text() for name in sorted(set(manifest['icons'].values()))}
    fingerprint = hashlib.sha256(manifest_bytes + primary.encode() + json.dumps(templates, sort_keys=True).encode() + b'render-v2').hexdigest()
    rgb = [int(primary[i:i + 2], 16) for i in (1, 3, 5)]
    def shade(factor):
        return '#' + ''.join(f'{round(channel * factor):02x}' for channel in rgb)
    def render(template):
        return templates[template].replace('@PRIMARY@', primary).replace('@DARK@', shade(.78)).replace('@EMBLEM@', shade(.35))
    layout = hashlib.sha256(manifest_bytes).hexdigest()
    canonical = {}
    for output, template in manifest['icons'].items():
        canonical.setdefault(template, output)
    def refresh_cache(path):
        if shutil.which('gtk-update-icon-cache'):
            subprocess.run(['gtk-update-icon-cache', '-f', '-t', str(path)], check=True, stdout=subprocess.DEVNULL)
    destination.parent.mkdir(parents=True, exist_ok=True)
    with (destination.parent / '.rehypr-papirus.lock').open('w') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        stamp = destination / '.fingerprint'
        if stamp.exists() and stamp.read_text() == fingerprint:
            return False
        layout_stamp = destination / '.layout'
        if not destination.is_symlink() and layout_stamp.exists() and layout_stamp.read_text() == layout:
            # Alias links and metadata stay in place on palette-only updates.
            for template, output in canonical.items():
                target = destination / output
                temporary = target.with_name('.' + target.name + '.tmp')
                temporary.write_text(render(template))
                temporary.replace(target)
            refresh_cache(destination)
            stamp.write_text(fingerprint)
            return True
        with tempfile.TemporaryDirectory(prefix='.rehypr-icons-', dir=destination.parent) as tmp:
            stage = Path(tmp) / NAME
            stage.mkdir()
            rendered = {}
            for output, template in manifest['icons'].items():
                target = stage / output
                target.parent.mkdir(parents=True, exist_ok=True)
                if template in rendered:
                    target.symlink_to(os.path.relpath(rendered[template], target.parent))
                    continue
                svg = render(template)
                target.write_text(svg)
                rendered[template] = target
            for output, original in manifest.get('fallbacks', {}).items():
                target = stage / output
                target.parent.mkdir(parents=True, exist_ok=True)
                target.symlink_to(original)
            index = configparser.ConfigParser(interpolation=None)
            index.optionxform = str
            index['Icon Theme'] = {'Name': NAME, 'Inherits': manifest['inherits']}
            for group in ('Directories', 'ScaledDirectories'):
                names = [name for name, props in manifest['directories'].items() if props['group'] == group]
                if names:
                    index['Icon Theme'][group] = ','.join(names)
            for name, props in manifest['directories'].items():
                index[name] = {key: value for key, value in props.items() if key != 'group'}
            with (stage / 'index.theme').open('w') as stream:
                index.write(stream, space_around_delimiters=False)
            refresh_cache(stage)
            (stage / '.layout').write_text(layout)
            (stage / '.fingerprint').write_text(fingerprint)
            if destination.is_symlink():
                raise ValueError('Refusing to replace a symlinked theme')
            backup = Path(tmp) / 'previous'
            if destination.exists():
                destination.rename(backup)
            try:
                stage.rename(destination)
            except OSError:
                if backup.exists():
                    backup.rename(destination)
                raise
    return True


def activate():
    config = Path(os.environ.get('XDG_CONFIG_HOME', Path.home() / '.config'))
    for version in (3, 4, 5, 6):
        gtk = version < 5
        path = config / (f'gtk-{version}.0/settings.ini' if gtk else f'qt{version}ct/qt{version}ct.conf')
        settings = configparser.ConfigParser(interpolation=None, strict=False)
        settings.optionxform = str
        settings.read(path)
        section, key = ('Settings', 'gtk-icon-theme-name') if gtk else ('Appearance', 'icon_theme')
        if settings.get(section, key, fallback='') == NAME:
            continue
        if not settings.has_section(section):
            settings.add_section(section)
        settings.set(section, key, NAME)
        path.parent.mkdir(parents=True, exist_ok=True)
        with path.open('w') as stream:
            settings.write(stream, space_around_delimiters=False)
    if os.environ.get('DBUS_SESSION_BUS_ADDRESS') and shutil.which('gsettings'):
        schemas = subprocess.run(['gsettings', 'list-schemas'], capture_output=True, text=True, check=True).stdout.splitlines()
        for schema in ('org.gnome.desktop.interface', 'org.cinnamon.desktop.interface'):
            if schema in schemas:
                subprocess.run(['gsettings', 'set', schema, 'icon-theme', NAME], check=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('palette', type=Path)
    parser.add_argument('--activate', action='store_true')
    args = parser.parse_args()
    data = Path(os.environ.get('XDG_DATA_HOME', Path.home() / '.local/share'))
    changed = generate(SOURCE, data / 'icons' / NAME, args.palette.read_text().strip())
    if args.activate:
        activate()
    print(f'{NAME}: {"updated" if changed else "unchanged"}')


if __name__ == '__main__':
    main()
