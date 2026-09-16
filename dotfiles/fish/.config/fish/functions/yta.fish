function yta --description "Interactive YouTube audio downloader"
    set -l max_attempts 5

    set -l zen_cookies (find ~/.config/zen -name cookies.sqlite -print -quit 2>/dev/null)
    set -l cookie_args

    if test -n "$zen_cookies"
        set -l zen_profile (dirname "$zen_cookies")
        set cookie_args --cookies-from-browser "firefox:$zen_profile"
        echo "Using Zen profile: $zen_profile"
    else
        echo "Zen cookies not found, continuing without authentication."
    end

    echo "YouTube audio downloader"
    echo "Paste URL and press Enter. Ctrl+C to exit."
    echo

    while true
        read -P "yta> " -l url

        # Ctrl+C / EOF
        if test $status -ne 0
            echo
            break
        end

        # Remove whitespace and surrounding quotes
        set url (string trim "$url")
        set url (string trim --chars "'\"" "$url")

        if test -z "$url"
            continue
        end

        for attempt in (seq $max_attempts)
            yt-dlp \
                $cookie_args \
                -f ba \
                -x \
                --embed-metadata \
                --embed-thumbnail \
                -o "%(artist,uploader)s - %(title)s.%(ext)s" \
                -- "$url"

            set -l exit_code $status

            if test $exit_code -eq 0
                echo
                break
            end

            if test $attempt -lt $max_attempts
                echo
                echo "Download failed. Retry $attempt/$max_attempts in 3s..."
                sleep 3
            else
                echo
                echo "Failed after $max_attempts attempts."
            end
        end

        echo
    end
end
