# Disable fish greeting
set -g fish_greeting

if status is-login
    if test (tty) = "/dev/tty1"
        if command -q uwsm; and uwsm check may-start
            exec uwsm start hyprland.desktop
        end
    end
end
