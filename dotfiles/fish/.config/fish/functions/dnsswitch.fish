function dnsswitch --description 'Configure split DNS for ru-central1.internal'
    if test (count $argv) -ne 1
        echo 'Usage: dnsswitch dev|auto|test|remove' >&2
        return 2
    end

    set -l config_dir /etc/systemd/resolved.conf.d
    set -l config_file $config_dir/ru-central1.conf
    set -l nameserver

    switch $argv[1]
        case dev
            set nameserver 10.92.16.2
        case auto
            set nameserver 10.94.96.2
        case test
            set nameserver 10.94.12.2
        case remove
            sudo rm -f -- $config_file; or return
            sudo systemctl restart systemd-resolved.service
            return $status
        case '*'
            echo 'Usage: dnsswitch dev|auto|test|remove' >&2
            return 2
    end

    sudo mkdir -p -- $config_dir; or return
    printf '[Resolve]\nDNS=%s\nDomains=~ru-central1.internal\n' $nameserver \
        | sudo tee $config_file >/dev/null
    or return

    sudo systemctl restart systemd-resolved.service
end
