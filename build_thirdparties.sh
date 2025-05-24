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
emcmake cmake $source_path/openjpeg -DCMAKE_C_FLAGS="-fPIC" -DBUILD_JPIP=OFF $CMAKE_BUILD_TYPE
emmake make

echo "Building libx264"
mkdir -p $build_path/x264
cd $build_path/x264
emconfigure $source_path/x264/configure --enable-static --enable-pic --disable-cli  --disable-asm --disable-thread --host=i686-gnu --prefix="$build_path/out"
emmake make install-lib-static "${MAKEFLAGS}"


echo "Building ffmpeg-x264"
export EM_PKG_CONFIG_PATH=$build_path/out/lib/pkgconfig
mkdir -p $build_path/ffmpeg-x264
cd $build_path/ffmpeg-x264
emconfigure $source_path/ffmpeg/configure --target-os=none --arch=x86_32 --enable-cross-compile --disable-x86asm --disable-inline-asm --disable-stripping --disable-programs --disable-doc --disable-runtime-cpudetect --disable-autodetect --disable-pthreads --pkg-config-flags="--static" --nm="$source_path/emsdk/upstream/bin/llvm-nm" --ar=emar --ranlib=emranlib --cc=emcc --cxx=em++ --objcc=emcc --dep-cc=emcc --enable-pic --enable-gpl --enable-libx264
emmake make "${MAKEFLAGS}"

echo "Building ffmpeg-flac"
mkdir -p $build_path/ffmpeg-flac
cd $build_path/ffmpeg-flac
emconfigure $source_path/ffmpeg/configure --target-os=none --arch=x86_32 --enable-cross-compile --disable-x86asm --disable-inline-asm --disable-stripping --disable-programs --disable-doc --disable-runtime-cpudetect --disable-autodetect --disable-pthreads --pkg-config-flags="--static" --nm="$source_path/emsdk/upstream/bin/llvm-nm" --ar=emar --ranlib=emranlib --cc=emcc --cxx=em++ --objcc=emcc --dep-cc=emcc --enable-pic --disable-everything --enable-decoder=flac
emmake make "${MAKEFLAGS}"

echo "Building ffmpeg-mpeg1"
mkdir -p $build_path/ffmpeg-mpeg1
cd $build_path/ffmpeg-mpeg1
emconfigure $source_path/ffmpeg/configure --target-os=none --arch=x86_32 --enable-cross-compile --disable-x86asm --disable-inline-asm --disable-stripping --disable-programs --disable-doc --disable-runtime-cpudetect --disable-autodetect --disable-pthreads --pkg-config-flags="--static" --nm="$source_path/emsdk/upstream/bin/llvm-nm" --ar=emar --ranlib=emranlib --cc=emcc --cxx=em++ --objcc=emcc --dep-cc=emcc --enable-pic --disable-everything --enable-decoder=mpeg1video
emmake make "${MAKEFLAGS}"

echo "Building ffmpeg-hevc"
mkdir -p $build_path/ffmpeg-hevc
cd $build_path/ffmpeg-hevc
emconfigure $source_path/ffmpeg/configure --target-os=none --arch=x86_32 --enable-cross-compile --disable-x86asm --disable-inline-asm --disable-stripping --disable-programs --disable-doc --disable-runtime-cpudetect --disable-autodetect --disable-pthreads --pkg-config-flags="--static" --nm="$source_path/emsdk/upstream/bin/llvm-nm" --ar=emar --ranlib=emranlib --cc=emcc --cxx=em++ --objcc=emcc --dep-cc=emcc --enable-pic --disable-everything --enable-decoder=hevc
emmake make "${MAKEFLAGS}"

echo "Building liba52"
cd $source_path
wget -nc https://distfiles.adelielinux.org/source/a52dec/a52dec-0.8.0.tar.gz
tar -xf a52dec-0.8.0.tar.gz
mkdir -p $build_path/liba52
cd $build_path/liba52
emconfigure $source_path/a52dec-0.8.0/configure  --disable-oss CFLAGS="-fPIC"
emmake make "${MAKEFLAGS}"

echo "Building ogg"
mkdir -p $build_path/ogg
cd $build_path/ogg
emcmake cmake $source_path/ogg -DCMAKE_C_FLAGS="-fpic" $CMAKE_BUILD_TYPE
emmake make "${MAKEFLAGS}"

echo "Building vorbis"
mkdir -p $build_path/vorbis
cd $build_path/vorbis
emcmake cmake $source_path/vorbis -DCMAKE_C_FLAGS="-fpic"  -DOGG_LIBRARY=$build_path/ogg  -DOGG_INCLUDE_DIR="$source_path/ogg/include;$build_path/ogg/include" -DBUILD_SHARED_LIBS=OFF -DBUILD_TESTING=OFF -DHAVE_LIBM=OFF -DBUILD_TESTING=OFF  $CMAKE_BUILD_TYPE
emmake make "${MAKEFLAGS}"

echo "Building xvid"
cd $source_path
wget -nc https://downloads.xvid.com/downloads/xvidcore-1.3.7.tar.gz
tar -xf xvidcore-1.3.7.tar.gz
mkdir -p $build_path/xvidcore
cd $source_path/xvidcore/build/generic
emconfigure ./configure --disable-assembly --disable-pthread
emmake make "${MAKEFLAGS}" libxvidcore.a
cp $source_path/xvidcore/build/generic/=build/libxvidcore.a $build_path/xvidcore

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

echo "Building theora"
cd $source_path/theora
./autogen.sh
mkdir -p $build_path/theora
cd $build_path/theora
emconfigure $source_path/theora/configure --disable-shared --enable-static --disable-examples --disable-encode --disable-vorbistest  --disable-oggtest --disable-asm --disable-spec --disable-doc --with-ogg-libraries=$build_path/ogg  --with-ogg-includes="$build_path/ogg/include -I$source_path/ogg/include" CFLAGS="-fPIC"
emmake make "${MAKEFLAGS}"

echo "Building libmpeg2"
cd $source_path/libmpeg2
mkdir -p $build_path/libmpeg2
cd $build_path/libmpeg2
emconfigure ../configure  --host=generic-unknown-linux-gnu --disable-sdl  --enable-static --with-pic
emmake make "${MAKEFLAGS}"


echo "Building libfaad"
cd $source_path/libfaad
mkdir -p $build_path/libfaad
cd $build_path/libfaad
emconfigure ../configure  --with-pic --enable-static
emmake make "${MAKEFLAGS}"
