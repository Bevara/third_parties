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

# emsdk library patch
EMSCRIPTEN=$EMSDK/upstream/emscripten
export PATH=$PATH:$EMSDK/upstream/bin

echo "Building gpac"
cd $source_path/gpac
source $source_path/gpac/check_revision.sh

mkdir -p $build_path/gpac
cd $build_path/gpac

#gpac_flags="--target-os=emscripten --disable-ogg --disable-3d  --disable-x11 --use-xvid=no --use-ffmpeg=local"
gpac_flags="--target-os=emscripten --disable-ogg --disable-3d  --disable-x11 --use-xvid=no --disable-qjs --use-png=no --use-jpeg=no"

if test "$debuginfo" = "yes"; then
    gpac_flags+=" --enable-debug"
fi
emconfigure $source_path/gpac/configure $gpac_flags
emmake make "${MAKEFLAGS}" -C src all

echo "Building rapidjson"
mkdir -p $build_path/rapidjson
cd $build_path/rapidjson
emcmake cmake $source_path/rapidjson $CMAKE_BUILD_TYPE
emmake make "${MAKEFLAGS}"

echo "Building openjpeg"
mkdir -p $build_path/openjpeg
cd $build_path/openjpeg
emcmake cmake $source_path/openjpeg -DCMAKE_C_FLAGS="-fPIC" $CMAKE_BUILD_TYPE
emmake make "${MAKEFLAGS}"

echo "Building nanojpeg"
cd $source_path
svn co http://svn.emphy.de/nanojpeg/
mkdir -p $build_path/nanojpeg
emcc "${EMCCFLAGS}" $source_path/nanojpeg/trunk/nanojpeg/nanojpeg.c -c -fPIC -o $build_path/nanojpeg/nanojpeg.o

echo "Building libpng"
mkdir -p $build_path/libpng
cd $build_path/libpng
emcmake cmake $source_path/libpng-code -DCMAKE_C_FLAGS="-fpic" $CMAKE_BUILD_TYPE
emmake make "${MAKEFLAGS}"

echo "Building libmad"
cd $source_path
wget -nc ftp://ftp.mars.org/pub/mpeg//libmad-0.15.1b.tar.gz
tar -xf libmad-0.15.1b.tar.gz
mkdir -p $build_path/libmad
cd $build_path/libmad
if test "$debuginfo" = "yes"; then
    mad_flags+="--enable-debugging"
fi
emconfigure $source_path/libmad-0.15.1b/configure --enable-static --with-pic CFLAGS=-Wno-error=unused-command-line-argument --build=x86_64-unknown-linux-gnu $mad_flags
emmake make "${MAKEFLAGS}"

echo "Building liba52"
cd $source_path
wget -nc https://liba52.sourceforge.io/files/a52dec-0.7.4.tar.gz
tar -xf a52dec-0.7.4.tar.gz
mkdir -p $build_path/liba52
cd $build_path/liba52
emconfigure $source_path/a52dec-0.7.4/configure  --disable-oss CFLAGS="-fPIC"
emmake make "${MAKEFLAGS}"


echo "Building ffmpeg"
mkdir -p $build_path/ffmpeg
cd $build_path/ffmpeg
if test "$debuginfo" = "no"; then
    ffmpeg_flags+="--disable-debug"
fi

emconfigure $source_path/ffmpeg/configure --target-os=none --arch=x86_32 --enable-cross-compile --disable-x86asm --disable-inline-asm --disable-stripping --disable-programs --disable-doc --disable-runtime-cpudetect --disable-autodetect --disable-pthreads --pkg-config-flags="--static" --nm="$source_path/emsdk/upstream/bin/llvm-nm" --ar=emar --ranlib=emranlib --cc=emcc --cxx=em++ --objcc=emcc --dep-cc=emcc --enable-pic --enable-shared $ffmpeg_flags
emmake make "${MAKEFLAGS}"