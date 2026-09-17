"""Profile selection, setup persistence, helpers and real Hyprland config validation."""
from pathlib import Path
import os, subprocess, tempfile, shutil
REPO = Path(__file__).resolve().parents[2]
HYPR = REPO / 'dotfiles/hyprland/.config/hypr'
with tempfile.TemporaryDirectory(prefix='rehypr-profiles-') as tmp:
    root = Path(tmp); home = root / "user's home"; home.mkdir()
    (home / '.config').mkdir(); (home / '.config/hypr').symlink_to(os.path.relpath(HYPR, home / '.config'))
    drm = root / 'drm'; drm.mkdir()
    env = dict(os.environ, HOME=str(home), REHYPR_DRM_DIR=str(drm))
    def run(cmd, ok=True, **kwargs):
        result = subprocess.run(cmd, env=env, cwd=REPO, capture_output=True, text=True, **kwargs)
        if ok: assert result.returncode == 0, result.stdout + result.stderr
        return result
    def resolve(): return run(['bash', str(HYPR/'scripts/profile.sh')]).stdout.strip()
    assert resolve() == 'desktop'
    (drm/'card0-eDP-1').mkdir(); (drm/'card0-eDP-1/status').write_text('disconnected\n')
    assert resolve() == 'laptop'
    (drm/'card1-DP-1').mkdir(); assert resolve() == 'laptop'
    setup = ['bash', str(REPO/'install/setup.sh')]
    run(setup+['--profile','desktop','--dry-run']); assert not (home/'.config/rehypr').exists()
    for mode, expected in [('desktop','desktop'),('laptop','laptop'),('auto','laptop')]:
        run(setup+['--profile',mode]); assert resolve()==expected
    profile=home/'.config/rehypr/profile'
    profile.write_text('bad\n'); assert run(['bash',str(HYPR/'scripts/profile.sh')],ok=False).returncode != 0
    assert run(setup+['--profile','bad'],ok=False).returncode==2
    profile.write_text('desktop\n')
    # Profile stays outside Stow and is preserved by previewing install.
    run(setup+['--install','--dry-run']); assert profile.read_text()=='desktop\n'
    if shutil.which('Hyprland'):
        for mode in ['desktop','laptop']:
            profile.write_text(mode+'\n')
            run(['Hyprland','--verify-config','-c',str(HYPR/'hyprland.lua')])
    # Laptop guard must not issue DDC requests.
    if shutil.which('fish'):
        profile.write_text('laptop\n')
        script = 'source '+str(REPO/'dotfiles/fish/.config/fish/functions/set_brightness.fish')+'; function ddcutil; echo UNEXPECTED; end; set_brightness 50'
        r=run(['fish','--no-config','-c',script],ok=False)
        assert r.returncode != 0 and 'UNEXPECTED' not in r.stdout
print('PASS: auto/override/invalid profiles, disconnected eDP, dry-run, quote-safe HOME, persistence, desktop/laptop Hyprland validation, DDC guard.')
