function rcssh --description 'SSH to disposable ru-central1.internal hosts without saved host keys'
    if test (count $argv) -lt 1
        echo 'Usage: rcssh [user@]host.ru-central1.internal [remote command]' >&2
        return 2
    end

    set -l destination $argv[1]
    if not string match -qr '^([A-Za-z0-9_][A-Za-z0-9_.-]*@)?([A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?\.)*ru-central1\.internal$' -- $destination
        echo 'rcssh: expected [user@]host.ru-central1.internal, not SSH options' >&2
        return 2
    end

    # These disposable VMs are rebuilt frequently. Trust their current keys
    # without consulting or changing the user's saved host keys.
    command env TERM=xterm-256color ssh \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -o GlobalKnownHostsFile=/dev/null \
        -o UpdateHostKeys=no \
        -- $argv
end
