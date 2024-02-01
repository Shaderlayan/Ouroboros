#!/bin/sh

cd "$(dirname "$0")" || exit 1

echo "Building configuration alum1 ..." >&2
MOD_NAME="Atramentum Luminis" ./build.sh alum1

echo "Building configuration alum ..." >&2
MOD_NAME="Atramentum Luminis" ./build.sh alum

for strength in "" wk sg; do
    for direction in "" rv; do
        for rotation in "" cw fl cc; do
            echo "Building configuration $strength $direction $rotation ..." >&2
            MOD_NAME="Hannish scale ointment" ./build.sh $strength $direction $rotation
        done
    done
    echo "Building configuration $strength x3 ..." >&2
    MOD_NAME="Hannish scale ointment" ./build.sh $strength x3
done
