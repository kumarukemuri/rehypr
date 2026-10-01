function rcssh --description 'SSH to ru-central1.internal hosts with host-key verification'
    if test (count $argv) -lt 1
        echo 'Usage: rcssh [user@]host.ru-central1.internal [remote command]' >&2
        return 2
    end

    set -l destination $argv[1]
    if not string match -qr '^([A-Za-z0-9_][A-Za-z0-9_.-]*@)?([A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?\.)*ru-central1\.internal$' -- $destination
        echo 'rcssh: expected [user@]host.ru-central1.internal, not SSH options' >&2
        return 2
    end

    # A changed key must fail. Verify the replacement fingerprint through a
    # trusted channel before manually updating known_hosts for a rebuilt VM.
    command env TERM=xterm-256color ssh \
        -o StrictHostKeyChecking=ask \
        -- $argv
end
