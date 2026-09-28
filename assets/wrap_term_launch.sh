#!/usr/bin/env sh

cat ~/.local/state/lumishell/sequences.txt 2>/dev/null

exec "$@"
