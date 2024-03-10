#!/bin/sh

set -e

cd "$(dirname "$0")"

IN_SUFFIX="1"
OUT_SUFFIX=""
DEF_ALUM_EMISSIVE_REDIRECT="1.0"
DEF_IRI_FACTOR="1.0"
DEF_IRI_Z_BIAS="0.5"
DEF_IRI_RHO="50.0"
DEF_IRI_THETA_XPOS="0.0"
DEF_IRI_THETA_SCALE="1.0"

for i in "$@"; do
    case "$i" in
        alum1)
            DEF_IRI_FACTOR=""
            ;;
        alum)
            IN_SUFFIX=""
            DEF_ALUM_EMISSIVE_REDIRECT=""
            DEF_IRI_FACTOR=""
            ;;
        wk)
            DEF_IRI_Z_BIAS="1.0"
            ;;
        sg)
            DEF_IRI_Z_BIAS="0.0"
            ;;
        rv)
            DEF_IRI_THETA_SCALE="-1.0"
            ;;
        x3)
            DEF_IRI_THETA_SCALE="3.0"
            ;;
        cw)
            DEF_IRI_THETA_XPOS="-90.0"
            ;;
        cc)
            DEF_IRI_THETA_XPOS="90.0"
            ;;
        fl)
            DEF_IRI_THETA_XPOS="-180.0"
            ;;
    esac
done

if [ -n "$DEF_IRI_FACTOR" ]; then
    if [ "$DEF_IRI_Z_BIAS" = "1.0" ]; then
        OUT_SUFFIX="$OUT_SUFFIX-wk"
    elif [ "$DEF_IRI_Z_BIAS" = "0.0" ]; then
        OUT_SUFFIX="$OUT_SUFFIX-sg"
    fi

    if [ "$DEF_IRI_THETA_SCALE" = "-1.0" ]; then
        OUT_SUFFIX="$OUT_SUFFIX-rv"
    elif [ "$DEF_IRI_THETA_SCALE" = "3.0" ]; then
        OUT_SUFFIX="$OUT_SUFFIX-x3"
    fi

    if [ "$DEF_IRI_THETA_XPOS" = "90.0" ]; then
        OUT_SUFFIX="$OUT_SUFFIX-cw"
    elif [ "$DEF_IRI_THETA_XPOS" = "-90.0" ]; then
        OUT_SUFFIX="$OUT_SUFFIX-cc"
    elif [ "$DEF_IRI_THETA_XPOS" = "-180.0" ]; then
        OUT_SUFFIX="$OUT_SUFFIX-fl"
    fi
else
    if [ -n "$DEF_ALUM_EMISSIVE_REDIRECT" ]; then
        OUT_SUFFIX="${OUT_SUFFIX}1"
    fi
    DEF_IRI_Z_BIAS=""
    DEF_IRI_RHO=""
    DEF_IRI_THETA_XPOS=""
    DEF_IRI_THETA_SCALE=""
fi

{
    [ -n "$DEF_ALUM_EMISSIVE_REDIRECT" ] && echo "#define ALUM_EMISSIVE_REDIRECT $DEF_ALUM_EMISSIVE_REDIRECT"
    [ -n "$DEF_IRI_FACTOR" ] && echo "#define IRI_FACTOR $DEF_IRI_FACTOR"
    [ -n "$DEF_IRI_Z_BIAS" ] && echo "#define IRI_Z_BIAS $DEF_IRI_Z_BIAS"
    [ -n "$DEF_IRI_RHO" ] && echo "#define IRI_RHO $DEF_IRI_RHO"
    [ -n "$DEF_IRI_THETA_XPOS" ] && echo "#define IRI_THETA_XPOS $DEF_IRI_THETA_XPOS"
    [ -n "$DEF_IRI_THETA_SCALE" ] && echo "#define IRI_THETA_SCALE $DEF_IRI_THETA_SCALE"
} > include/config.hlsli

./configure.py

CONCURRENCY="$(getconf _NPROCESSORS_ONLN)"
if [ -z "$CONCURRENCY" ]; then
    CONCURRENCY=4
fi

fxc 2>/dev/null || true
if [ -z "$DEF_IRI_FACTOR" ]; then
    make -j"$CONCURRENCY" all"$IN_SUFFIX"
else
    make -j"$CONCURRENCY" build/skin"$IN_SUFFIX".shpk
fi

if [ -n "$MOD_NAME" ]; then
    mkdir -p "$HOME/.xlextra/Penumbra/$MOD_NAME/shader"
    INSTALL_DIR="$HOME/.xlextra/Penumbra/$MOD_NAME/shader"
fi

if [ -n "$INSTALL_DIR" ]; then
    cp -v build/skin"$IN_SUFFIX".shpk "$INSTALL_DIR/skin$OUT_SUFFIX.shpk"
    if [ -z "$DEF_IRI_FACTOR" ]; then
        cp -v build/iris"$IN_SUFFIX".shpk "$INSTALL_DIR/iris$OUT_SUFFIX.shpk"
    fi
    if [ -z "$IN_SUFFIX" ]; then
        cp -v build/hair"$IN_SUFFIX".shpk "$INSTALL_DIR/hair$OUT_SUFFIX.shpk"
        cp -v build/characterglass"$IN_SUFFIX".shpk "$INSTALL_DIR/characterglass$OUT_SUFFIX.shpk"
    fi
fi
