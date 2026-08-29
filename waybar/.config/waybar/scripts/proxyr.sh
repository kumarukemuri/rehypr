#!/usr/bin/env bash

set -euo pipefail

APP="/opt/v2rayn-bin/v2rayN"

start() {
    if ! pgrep -x v2rayN >/dev/null; then
        uwsm app -- "$APP" >/dev/null 2>&1 &
        disown
    fi
}

stop() {
    pkill -x v2rayN 2>/dev/null || true
}

restart() {
    pkill -x v2rayN 2>/dev/null || true
    sleep 1
    pkill -9 -x v2rayN 2>/dev/null || true
    uwsm app -- "$APP" >/dev/null 2>&1 &
    disown
}

case "${1:-}" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    *)
        echo "usage: $0 {start|stop|restart}"
        exit 1
        ;;
esac