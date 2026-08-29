function set_brightness --description "Set brightness for all, main, or secondary monitors"
    set -l value
    set -l target_buses

    switch (count $argv)
        case 1
            set value $argv[1]
            set target_buses 4 7 8
        case 2
            set -l target (string lower -- $argv[1])
            set value $argv[2]

            switch $target
                case main
                    # DP-1
                    set target_buses 7
                case sec
                    # HDMI-A-1 and DP-2
                    set target_buses 4 8
                case '*'
                    echo "Error: target must be 'main' or 'sec'
                    return 2
            end
        case '*'
            echo "Usage:"
            echo "  set_brightness <0-100>"
            echo "  set_brightness <main|sec> <0-100>"
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
