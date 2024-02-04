#!/bin/sh

set -e

cd "$(dirname "$0")"

OUROBOROS_NAME="$(jq --raw-output '.Name + " v" + .Version' < penumbra/meta.json)"
MDK_NAME="$(jq --raw-output '.Name + " v" + .Version' < penumbra_mdk/meta.json)"

rm -rf build/ouroboros
rm -f "build/${OUROBOROS_NAME}.pmp"

rm -rf build/mdk
rm -rf "build/${MDK_NAME}.pmp"

mkdir -p build/ouroboros/shader
mkdir -p build/mdk/shpk_devkit

INSTALL_DIR="build/ouroboros/shader" DK_INSTALL_DIR="build/mdk/shpk_devkit" ./build.sh

cp -v penumbra/*.json build/ouroboros
cp -v penumbra_mdk/*.json build/mdk

cd build/ouroboros
zip -r -9 "../${OUROBOROS_NAME}.pmp" .
cd -

cd build/mdk
zip -r -9 "../${MDK_NAME}.pmp" .
cd -
