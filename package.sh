#!/bin/sh

set -e

cd "$(dirname "$0")"

VERSION="$(git describe --tags --always | sed -e 's/^v\|^.*\?-v//')"
OUROBOROS_NAME="$(jq --raw-output '.Name' < penumbra/meta.json) v${VERSION}"
MDK_NAME="$(jq --raw-output '.Name' < penumbra_mdk/meta.json) v${VERSION}"

rm -rf build/ouroboros
rm -f "build/${OUROBOROS_NAME}.pmp"

rm -rf build/mdk
rm -rf "build/${MDK_NAME}.pmp"

mkdir -p build/ouroboros/shader
mkdir -p build/mdk/shpk_devkit

INSTALL_DIR="build/ouroboros/shader" DK_INSTALL_DIR="build/mdk/shpk_devkit" ./build.sh

cp -v penumbra/*.json build/ouroboros
cp -v penumbra_mdk/*.json build/mdk

jq --arg VERSION "${VERSION}" '.Version |= $VERSION' penumbra/meta.json > build/ouroboros/meta.json
jq --arg VERSION "${VERSION}" '.Version |= $VERSION' penumbra_mdk/meta.json > build/mdk/meta.json

cd build/ouroboros
zip -r -9 "../${OUROBOROS_NAME}.pmp" .
cd -

cd build/mdk
zip -r -9 "../${MDK_NAME}.pmp" .
cd -
