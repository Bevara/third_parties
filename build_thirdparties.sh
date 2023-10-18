#!/bin/bash
debuginfo="no"
no_gcc_opt="no"

for opt do
    case "$opt" in
        --enable-debug) debuginfo="yes"; no_gcc_opt="yes"
            ;;
    esac
done

echo "Setting environnement"
mkdir -p third_parties
cd third_parties

find source path
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

if test "$debuginfo" = "yes"; then
    EMCCFLAGS="-g"
    CMAKE_BUILD_TYPE="-DCMAKE_BUILD_TYPE=Debug"
else
    CMAKE_BUILD_TYPE="-DCMAKE_BUILD_TYPE=Release"
fi

echo "Configuring emsdk"
source $source_path/emsdk_vers.txt
cd $source_path/emsdk
./emsdk install $EMSDK_VERS
./emsdk activate $EMSDK_VERS
. ./emsdk_env.sh

emsdk library patch
EMSCRIPTEN=$EMSDK/upstream/emscripten
export PATH=$PATH:$EMSDK/upstream/bin

echo "Building emscripten libs"
embuilder build libc libc++ libc++abi --pic

echo "Building gpac"
cd $source_path/gpac
source $source_path/gpac/check_revision.sh

mkdir -p $build_path/gpac
cd $build_path/gpac
gpac_flags="--enable-pic --use-xvid=no --disable-qjs --use-png=no --use-jpeg=no --disable-ogg --use-vorbis=no --extra-libs=-sERROR_ON_UNDEFINED_SYMBOLS=0"

if test "$debuginfo" = "yes"; then
    gpac_flags+=" --enable-debug"
fi
emconfigure $source_path/gpac/configure $gpac_flags
emmake make "${MAKEFLAGS}"

echo "Building gpac minimal"
mkdir -p $build_path/gpac_minimal
cd $build_path/gpac_minimal
gpac_flags="--disable-all"

if test "$debuginfo" = "yes"; then
    gpac_flags+=" --enable-debug"
fi
emconfigure $source_path/gpac/configure $gpac_flags
emmake make "${MAKEFLAGS}"


if test "$debuginfo" = "yes"; then
    gpac_flags+=" --enable-debug"
fi
emconfigure $source_path/gpac/configure $gpac_flags
emmake make "${MAKEFLAGS}"

echo "Building rapidjson"
mkdir -p $build_path/rapidjson
cd $build_path/rapidjson
emcmake cmake $source_path/rapidjson $CMAKE_BUILD_TYPE
emmake make "${MAKEFLAGS}"

echo "Building libpng"
mkdir -p $build_path/libpng
cd $build_path/libpng
emcmake cmake $source_path/libpng-code -DPNG_SHARED=OFF -DPNG_STATIC=ON -DPNG_EXECUTABLES=OFF -DPNG_TESTS=OFF -DPNG_FRAMEWORK=OFF -DPNG_DEBUG=OFF -DPNG_HARDWARE_OPTIMIZATIONS=OFF  -DCMAKE_C_FLAGS="-fpic" $CMAKE_BUILD_TYPE
emmake make "${MAKEFLAGS}"

echo "Building libjpeg"
cd $source_path
wget -nc http://www.ijg.org/files/jpegsrc.v9e.tar.gz
tar -xf jpegsrc.v9e.tar.gz
mkdir -p $build_path/libjpeg
cd $build_path/libjpeg
emconfigure $source_path/jpeg-9e/configure --enable-static --disable-shared CFLAGS="-fPIC"
emmake make "${MAKEFLAGS}"

echo "Building higway"
mkdir -p $build_path/higway
cd $build_path/higway
emcmake cmake $source_path/highway -DCMAKE_C_FLAGS="-fpic" -DHWY_ENABLE_CONTRIBS=OFF -DHWY_ENABLE_EXAMPLES=OFF -DHWY_ENABLE_INSTAL=OFF -DHWY_ENABLE_TESTS=OFF  $CMAKE_BUILD_TYPE 
emmake make "${MAKEFLAGS}"

echo "Building brotli"
cd $source_path/brotli
sh ./bootstrap
mkdir -p $build_path/brotli
cd $build_path/brotli
emconfigure $source_path/brotli/configure --enable-static --disable-shared CFLAGS="-fPIC"
emmake make "${MAKEFLAGS}"

echo "Building libjxl"
cd $source_path/libjxl
git submodule update --init --recursive
mkdir -p $build_path/libjxl
cd $build_path/libjxl
emcmake cmake $source_path/libjxl -DCMAKE_C_FLAGS="-fpic" -DBUILD_SHARED_LIBS=FALSE -DJPEGXL_ENABLE_FUZZERS=FALSE -DJPEGXL_ENABLE_DEVTOOLS=FALSE -DJPEGXL_ENABLE_TOOLS=FALSE -DJPEGXL_ENABLE_JPEGLI=FALSE -DJPEGXL_ENABLE_JPEGLI_LIBJPEG=FALSE -DJPEGXL_ENABLE_DOXYGEN=FALSE -DJPEGXL_ENABLE_MANPAGES=FALSE -DJPEGXL_ENABLE_BENCHMARK=FALSE -DJPEGXL_ENABLE_EXAMPLES=FALSE -DJPEGXL_BUNDLE_LIBPNG=FALSE -DJPEGXL_ENABLE_JNI=FALSE -DJPEGXL_ENABLE_SJPEG=FALSE -DJPEGXL_ENABLE_OPENEXR=FALSE -DJPEGXL_ENABLE_SKCMS=FALSE -DJPEGXL_BUNDLE_SKCMS=FALSE -DJPEGXL_ENABLE_VIEWERS=FALSE -DJPEGXL_ENABLE_TCMALLOC=FALSE -DJPEGXL_ENABLE_PLUGINS=FALSE -DJPEGXL_ENABLE_COVERAGE=FALSE -DJPEGXL_ENABLE_PROFILER=FALSE -DJPEGXL_ENABLE_SIZELESS_VECTORS=FALSE -DJPEGXL_ENABLE_TRANSCODE_JPEG=FALSE -DJPEGXL_ENABLE_BOXES=FALSE -DJPEGXL_STATIC=ON -DJPEGXL_WARNINGS_AS_ERRORS=FALSE -DBUILD_TESTING=FALSE $CMAKE_BUILD_TYPE
emmake make "${MAKEFLAGS}"

echo "Building openjpeg"
mkdir -p $build_path/openjpeg
cd $build_path/openjpeg
emcmake cmake $source_path/openjpeg -DCMAKE_C_FLAGS="-fPIC" $CMAKE_BUILD_TYPE
emmake make "${MAKEFLAGS}"

