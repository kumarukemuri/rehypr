# Security review — 2026-10-01

Scope: the tracked rehypr configuration, installer and scripts, plus all 20
commits and 7,404 unique blobs reachable through locally available Git refs
before the history reset. The local main and GitHub main initially matched.
No live SSH connection, lockscreen bypass, or production command injection was
performed. The old history is retained only in an external local backup bundle.

## Fixed findings

### High: SSH host-key replacement bypassed server authentication

`rcssh.fish` fetched unauthenticated keys with ssh-keyscan, deleted saved host
and address keys when none matched, then connected with accept-new. An attacker
able to impersonate the endpoint could replace the trusted key. The internal
DNS suffix did not authenticate the endpoint.

The helper now uses StrictHostKeyChecking=ask, never deletes keys automatically,
validates the entire destination and terminates SSH option parsing with `--`.
A rebuilt VM requires checking its fingerprint through a trusted channel before
manually changing known_hosts. Regression tests also reject destinations that
try to inject SSH options.

Reference: https://man.openbsd.org/ssh_config#StrictHostKeyChecking

### High: wallpaper filenames were executable Lua template input

The Matugen Lua template embedded `{{image}}` directly in a quoted Lua string.
A crafted image filename could break out of the string. A real Matugen render
and a standalone Lua load reproduced execution of a harmless in-memory marker
inside an isolated temporary directory. Exploitation requires selecting an
attacker-controlled filename/path and subsequently loading the generated palette.

The unused image field was removed from the Lua palette. The wallpaper setter
also rejects control characters, quotes, backslashes, commas, dollar signs and
hashes before passing paths into line-based configuration or wallpaper IPC.
The image path remains available through `$image` for Hyprpaper/Hyprlock.
A real-template regression test confirms the crafted filename no longer runs Lua.

### Medium: lockscreen grace period

`hyprlock.conf` configured `grace = 10`, allowing passwordless cancellation
within the grace period on versions supporting that setting. Changed to zero.
This does not change the inactivity timeout or enable a new auto-lock policy.

Reference: https://wiki.hypr.land/Hypr-Ecosystem/hyprlock/

### Preventive: runtime files in the public source tree

Fish universal variables and systemd activation symlinks were tracked despite
being machine-local state. They are excluded from the new snapshot and ignored;
local files remain intact. Added ignores for Fish history, SSH/AWS directories
and the bot's private configuration. Ignore rules do not prevent explicit force-adds.

## Remaining considerations

- No matches were found for private-key headers, common GitHub/AWS/Slack/Google
  token formats, JWTs, credential-bearing URLs or common password/token/secret
  assignments in the scanned text blobs. This was a custom pattern scan and
  manual review, not an assurance that arbitrary-format secrets cannot exist.
- `dnsswitch.fish` publishes internal DNS addresses and an internal domain suffix.
  These are infrastructure metadata, not authentication credentials. Personal
  usernames, hostnames, device names and paths are also present. They remain
  intentionally visible in this personal dotfile snapshot.
- The idle rule powers displays off after 60 seconds; it does not itself lock
  the session. Sleep and the explicit lock shortcut are separate. Automatic
  locking after inactivity requires choosing a timeout and adding a lock rule.
- The installer builds yay/AUR packages from live upstream sources and invokes
  privileged package installation. PKGBUILDs and their sources remain part of
  the trust boundary; this review does not audit all third-party packages/CVEs.
- Replacing Git history removes old commits from branch ancestry, not from
  existing clones, forks, pull-request refs or GitHub caches. Any credential
  discovered later must be revoked even after a history reset.

## Validation

Passed: `test_security.py`, `test_wallpaper.py`, `test_setup.py`,
`test_layout.py`, `test_profiles.py`, `test_profiles.lua`, Bash/Fish syntax checks
and `git diff --check`. Security tests use isolated HOME/PATH fixtures and a
harmless Lua marker; they never edit real known_hosts or load the live palette.
The profile tests include Hyprland --verify-config for all three profiles.
