function set_brightness --description "Set brightness for all, main, or secondary monitors"
    set -l profile (bash "$HOME/.config/hypr/scripts/profile.sh")
    or return 1
    if test "$profile" != desktop
        echo "DDC brightness groups are configured for the desktop only; use laptop brightness keys." >&2
        return 1
    end
    set -l main_buses 7
    set -l secondary_buses 4 8
    set -l value
    set -l target_buses

    switch (count $argv)
        case 1
            set value $argv[1]
            set target_buses $secondary_buses[1] $main_buses $secondary_buses[2..-1]
        case 2
            set -l target (string lower -- $argv[1])
            set value $argv[2]

            switch $target
                case main
                    # DP-1
                    set target_buses $main_buses
                case sec secondary
                    # HDMI-A-1 and DP-2
                    set target_buses $secondary_buses
                case '*'
                    echo "Error: target must be 'main', 'sec', or 'secondary'"
                    return 2
            end
        case '*'
            echo "Usage:"
            echo "  set_brightness <0-100>"
            echo "  set_brightness <main|sec|secondary> <0-100>"
            return 2
    end

    if not string match -qr '^[0-9]+$' -- $value
        echo "Error: brightness must be an integer (0-100)"
        return 2
    end

    if test $value -lt 0 -o $value -gt 100
        echo "Error: brightness must be in range 0-100"
        return 2
    end

    for bus in $target_buses
        ddcutil setvcp 10 $value --bus $bus
    end
end
