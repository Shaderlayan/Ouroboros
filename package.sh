#!/bin/bash

set -e

cd "$(dirname "$0")"

rm -rf build/ouroboros
rm -f build/ouroboros.pmp

rm -rf build/mdk
rm -rf build/mdk.pmp

mkdir -p build/ouroboros/shader
mkdir -p build/mdk/shpk_devkit

INSTALL_DIR="build/ouroboros/shader" DK_INSTALL_DIR="build/mdk/shpk_devkit" ./build.sh

cp -v penumbra/*.json build/ouroboros
cp -v penumbra_mdk/*.json build/mdk

pushd build/ouroboros
zip -r -9 ../ouroboros.pmp .
popd

pushd build/mdk
zip -r -9 ../mdk.pmp .
popd
