#!/bin/sh

set -e

cd "$(dirname "$0")"

rm -rf build/alum
rm -f build/alum.pmp

rm -rf build/hso
rm -rf build/hso.pmp

mkdir -p build/alum/shader build/alum/shpk_devkit
mkdir -p build/hso/shader build/hso/shpk_devkit

echo "Building configuration alum1 ..." >&2
INSTALL_DIR="build/alum/shader" ./build.sh alum1

echo "Building configuration alum ..." >&2
INSTALL_DIR="build/alum/shader" ./build.sh alum

for strength in "" wk sg; do
    for direction in "" rv; do
        for rotation in "" cw fl cc; do
            echo "Building configuration $strength $direction $rotation ..." >&2
            INSTALL_DIR="build/hso/shader" ./build.sh $strength $direction $rotation
        done
    done
    echo "Building configuration $strength x3 ..." >&2
    INSTALL_DIR="build/hso/shader" ./build.sh $strength x3
done

cp -v hair/devkit.json build/alum/shpk_devkit/hair.json
cp -v iris/devkit.json build/alum/shpk_devkit/iris.json
cp -v iris/devkit1.json build/alum/shpk_devkit/iris1.json
cp -v skin/devkit.json build/alum/shpk_devkit/skin.json
cp -v skin/devkit1.json build/alum/shpk_devkit/skin1.json

cp -v skin/devkit1.json build/hso/shpk_devkit/skin.json

cp -v penumbra/*.json build/alum
cp -v penumbra_hso/*.json build/hso

cd build/alum
zip -r -9 ../alum.pmp .
cd -

cd build/hso
zip -r -9 ../hso.pmp .
cd -
