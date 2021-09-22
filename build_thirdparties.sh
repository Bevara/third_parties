#!/bin/bash
echo "Setting environnement"
BUILD_DIR=$PWD

# Find source path
source_path="`echo $0 | sed -e 's#/build_thirdparties.sh##'`"
source_path_used="yes"
if test -z "$source_path" -o "$source_path" = "." ; then
    source_path="`pwd`"
    source_path_used="no"
    build_path=$source_path
else
    source_path="`cd \"$source_path\"; pwd`"
    build_path="`pwd`"
fi

if [ -z "$MAKEFLAGS" ]; then
    UNAMES=$(uname -s)
    MAKEFLAGS=
    if which nproc >/dev/null; then
        MAKEFLAGS=-j$(nproc)
    elif [ "$UNAMES" = "Darwin" ] && which sysctl >/dev/null; then
        MAKEFLAGS=-j$(sysctl -n machdep.cpu.thread_count)
    fi
fi

echo "Downloading dependencies"
cd $source_path
git submodule update --init

echo "Configuring emsdk"
source $source_path/emsdk_vers.txt
cd $source_path/emsdk
./emsdk install $EMSDK_VERS
./emsdk activate $EMSDK_VERS
. ./emsdk_env.sh

# emsdk library patch
EMSCRIPTEN=$EMSDK/upstream/emscripten
export PATH=$PATH:$EMSDK/upstream/bin

echo "Building gpac"
cd $source_path/gpac
source ./check_revision.sh

mkdir -p $BUILD_DIR/gpac
cd $BUILD_DIR/gpac
emconfigure $source_path/gpac/configure --target-os=emscripten --disable-ogg --disable-remotery --disable-3d  --disable-x11  --use-png=no --use-jpeg=no --use-xvid=no
emmake make "${MAKEFLAGS}" -C src all

echo "Building tinyxml2"
mkdir -p $BUILD_DIR/tinyxml2
cd $BUILD_DIR/tinyxml2
emcmake cmake $source_path/tinyxml2
emmake make "${MAKEFLAGS}" 