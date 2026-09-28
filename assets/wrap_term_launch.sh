#!/usr/bin/env sh

cat ~/.local/state/lumi/sequences.txt 2>/dev/null

exec "$@"
