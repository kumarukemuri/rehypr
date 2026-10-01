#!/usr/bin/env python3
"""Migrate only links owned by this checkout; never follow unrelated home links."""
import argparse
import datetime
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

REPO = Path(__file__).resolve().parent.parent
HOME = Path(os.environ['HOME']).absolute()
PACKAGES = (REPO / 'install/stow-packages.txt').read_text().splitlines()
ROOTS = sorted({Path('.config') / p.name
                for package in PACKAGES
                for p in (REPO / 'dotfiles' / package / '.config').glob('*')}
               | {Path('.local/share/themes') / p.name
                  for p in (REPO / 'dotfiles/themes/.local/share/themes').glob('*')}
               | {Path('.config/qt5ct'), Path('.config/qt6ct')})


def exists(p):
    return p.exists() or p.is_symlink()


def copy(src, dst):
    dst.parent.mkdir(parents=True, exist_ok=True)
    if src.is_symlink():
        dst.symlink_to(os.readlink(src))
    elif src.is_dir():
        shutil.copytree(src, dst, symlinks=True)
    else:
        shutil.copy2(src, dst)


def remove(p):
    if p.is_symlink() or p.is_file():
        p.unlink()
    elif p.is_dir():
        shutil.rmtree(p)


def link_target(p):
    return Path(os.path.abspath(p.parent / os.readlink(p)))


def owned_old(target):
    for package in PACKAGES + ['qtct']:
        old = REPO / package
        if target == old or old in target.parents:
            return package, target.relative_to(old)
    return None


def links_under(p):
    if p.is_symlink():
        yield p
    elif p.is_dir():
        for child in p.iterdir():
            yield from links_under(child)


def identical(a, b):
    if a.is_symlink() or b.is_symlink():
        return a.is_symlink() and b.is_symlink() and os.readlink(a) == os.readlink(b)
    return a.is_file() and b.is_file() and a.read_bytes() == b.read_bytes()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--check', action='store_true')
    parser.add_argument('--dry-run', action='store_true')
    args = parser.parse_args()
    links = [(p, owned_old(link_target(p))) for root in ROOTS
             for p in links_under(HOME / root) if owned_old(link_target(p))]
    if args.check:
        if links:
            sys.exit('Old checkout links detected. Run install/setup.sh --migrate first.')
        return

    if not links:
        stow(REPO / "dotfiles", HOME, simulate=True)
        if not args.dry_run:
            stow(REPO / "dotfiles", HOME, simulate=False)
        print("No legacy links remain.")
        return

    transfers = []
    for package in PACKAGES:
        old = REPO / package
        if not old.is_dir() or old.is_symlink():
            continue
        for folder, dirs, files in os.walk(old, followlinks=False):
            for name in files + [d for d in dirs if (Path(folder) / d).is_symlink()]:
                src = Path(folder) / name
                dst = REPO / 'dotfiles' / package / src.relative_to(old)
                if exists(dst):
                    if not identical(src, dst):
                        sys.exit(f'Conflicting local file: {src} -> {dst}')
                else:
                    transfers.append((src, dst))
    for p, (package, rel) in links:
        print(f'RELINK {p} -> {"local Qt settings" if package == "qtct" else REPO / "dotfiles" / package / rel}')
    for src, dst in transfers:
        print(f'PRESERVE {src} -> {dst}')

    # Preview against a private HOME and source tree, including residual local files.
    with tempfile.TemporaryDirectory(prefix='rehypr-migrate-') as tmp:
        stage = Path(tmp)
        source = stage / 'dotfiles'
        shutil.copytree(REPO / 'dotfiles', source, symlinks=True)
        for src, dst in transfers:
            copy(src, source / dst.relative_to(REPO / 'dotfiles'))
        preview = stage / 'home'
        preview.mkdir()
        for root in ROOTS:
            original = HOME / root
            if exists(original):
                copy(original, preview / root)
        # Make relative links refer to their real HOME targets before remapping.
        for root in ROOTS:
            for p in list(links_under(preview / root)):
                original = HOME / p.relative_to(preview)
                target = link_target(original)
                old = owned_old(target)
                p.unlink()
                if old:
                    package, rel = old
                    if package == 'qtct':
                        materialize_qt(original, p, rel)
                    else:
                        p.symlink_to(os.path.relpath(source / package / rel, p.parent))
                else:
                    try:
                        target = source / target.relative_to(REPO / 'dotfiles')
                    except ValueError:
                        pass
                    p.symlink_to(os.path.relpath(target, p.parent))
        stow(source, preview, simulate=True)
        if args.dry_run:
            print('Dry run: HOME and repository were not changed.')
            return

    state = Path(os.environ.get('XDG_STATE_HOME', str(HOME / '.local/state'))) / 'rehypr'
    state.mkdir(parents=True, exist_ok=True)
    backup = Path(tempfile.mkdtemp(prefix=datetime.datetime.now().strftime('migration-%Y%m%d-%H%M%S-'), dir=state))
    for root in ROOTS:
        if exists(HOME / root):
            copy(HOME / root, backup / 'home' / root)
    palette_paths = [REPO / 'dotfiles/hyprland/.config/hypr/colors.conf',
                     REPO / 'dotfiles/hyprland/.config/hypr/config/colors.lua']
    palette_before = {p: p.read_bytes() for p in palette_paths if p.is_file()}
    for p in palette_before:
        copy(p, backup / 'palette' / p.name)
    (backup / 'manifest.json').write_text(json.dumps({
        'links': [{'path': str(p), 'old': os.readlink(p), 'package': package, 'relative': str(rel)} for p, (package, rel) in links],
        'copies': [{'old': str(a), 'new': str(b)} for a, b in transfers],
    }, indent=2))
    created = []
    try:
        for src, dst in transfers:
            copy(src, backup / 'local' / src.relative_to(REPO))
            copy(src, dst)
            created.append(dst)
        for p, (package, rel) in links:
            p.unlink()
            if package == 'qtct':
                # Read from the original link's target, which is still retained.
                materialize_qt(backup / 'home' / p.relative_to(HOME), p, rel,
                               original_target=REPO / package / rel)
            else:
                p.symlink_to(os.path.relpath(REPO / 'dotfiles' / package / rel, p.parent))
        for p in palette_paths:
            if p.is_file():
                text = p.read_text()
                for package in PACKAGES:
                    text = text.replace(str(REPO / package) + '/', str(REPO / 'dotfiles' / package) + '/')
                p.write_text(text)
        stow(REPO / 'dotfiles', HOME, simulate=False)
    except BaseException:
        for root in ROOTS:
            remove(HOME / root)
            if exists(backup / 'home' / root):
                copy(backup / 'home' / root, HOME / root)
        for p in created:
            remove(p)
        for p, data in palette_before.items():
            p.write_bytes(data)
        print(f'Migration failed; original links restored. Backup: {backup}', file=sys.stderr)
        raise
    print(f'Migration complete. Backup: {backup}')


def materialize_qt(original, dest, rel, original_target=None):
    target = original_target or link_target(original)
    if target.exists():
        # Qt must no longer depend on a legacy Stow link.
        if target.is_dir():
            shutil.copytree(target, dest, symlinks=False, ignore_dangling_symlinks=True)
            if rel.name in ("qt5ct", "qt6ct"):
                (dest / "colors").mkdir(exist_ok=True)
                conf = dest / (rel.name + ".conf")
                if not conf.is_file():
                    version = "5" if rel.name == "qt5ct" else "6"
                    template = (REPO / f"install/templates/qtct/qt{version}ct.conf.in").read_text()
                    conf.write_text(template.replace("@COLOR_SCHEME_PATH@", str(HOME / f".config/qt{version}ct/colors/matugen.conf")))
                    print(f"Restored missing Qt settings from template: {conf}")
        else:
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(target, dest)
        return
    parts = rel.parts
    version = '5' if 'qt5ct' in parts else '6'
    if rel.name == f'qt{version}ct.conf':
        conf = dest
    elif rel.name == f'qt{version}ct':
        dest.mkdir(parents=True, exist_ok=True)
        conf = dest / f'qt{version}ct.conf'
    elif rel.name == 'colors':
        dest.mkdir(parents=True, exist_ok=True)
        print(f'Recreated missing Qt colors directory: {dest}; regenerate the palette.')
        return
    else:
        raise RuntimeError(f'Cannot recover missing Qt file: {target}')
    conf.parent.mkdir(parents=True, exist_ok=True)
    template = (REPO / f'install/templates/qtct/qt{version}ct.conf.in').read_text()
    conf.write_text(template.replace('@COLOR_SCHEME_PATH@', str(HOME / f'.config/qt{version}ct/colors/matugen.conf')))
    print(f'Restored missing Qt settings from template: {conf}')


def stow(source, home, simulate):
    cmd = ['stow', '--dir=' + str(source), '--target=' + str(home), '--restow']
    if simulate:
        cmd.append('--simulate')
    subprocess.run(cmd + PACKAGES, check=True)


if __name__ == '__main__':
    try:
        main()
    except (OSError, RuntimeError, subprocess.CalledProcessError) as error:
        sys.exit(str(error))
