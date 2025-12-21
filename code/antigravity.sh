#!/bin/bash

ulimit -c 0
exec /usr/bin/antigravity --ozone-platform-hint=auto --enable-features=WaylandWindowDecorations "$@"