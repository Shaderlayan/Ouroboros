#!/bin/sh

set -e

cd "$(dirname "$0")"

./configure.py

CONCURRENCY="$(getconf _NPROCESSORS_ONLN)"
if [ -z "$CONCURRENCY" ]; then
    CONCURRENCY=4
fi

fxc 2>/dev/null || true
make -j"$CONCURRENCY" all

if [ -n "$MOD_NAME" ]; then
    mkdir -p "$HOME/.xlextra/Penumbra/$MOD_NAME/shader"
    INSTALL_DIR="$HOME/.xlextra/Penumbra/$MOD_NAME/shader"
fi

if [ -n "$INSTALL_DIR" ]; then
    cp -v build/*.shpk "$INSTALL_DIR"
fi

if [ -n "$DK_NAME" ]; then
    mkdir -p "$HOME/.xlextra/Penumbra/$DK_NAME/shpk_devkit"
    DK_INSTALL_DIR="$HOME/.xlextra/Penumbra/$DK_NAME/shpk_devkit"
fi

if [ -n "$DK_INSTALL_DIR" ]; then
    cp -v base_devkit.json "$DK_INSTALL_DIR/_base.json"
    for devkit in */devkit.json; do
        cp -v -- "$devkit" "$DK_INSTALL_DIR/$(basename "$(dirname "$devkit")").json"
    done
fi
