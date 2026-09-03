#!/bin/bash
debuginfo="no"
no_gcc_opt="no"

for opt do
    case "$opt" in
        --enable-debug) debuginfo="yes"; no_gcc_opt="yes"
            ;;
    esac
done

echo "Updating submodules"
#git submodule update --init

echo "Setting environnement"
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
embuilder build libc libc++ libc++abi zlib --pic

# echo "Building ffmpeg-x264"
# export EM_PKG_CONFIG_PATH=$build_path/out/lib/pkgconfig
# mkdir -p $build_path/ffmpeg-x264
# cd $build_path/ffmpeg-x264
# emconfigure $source_path/ffmpeg/configure --target-os=none --arch=x86_32 --enable-cross-compile --disable-x86asm --disable-inline-asm --disable-stripping --disable-programs --disable-doc --disable-runtime-cpudetect --disable-autodetect --disable-pthreads --pkg-config-flags="--static" --nm="$source_path/emsdk/upstream/bin/llvm-nm" --ar=emar --ranlib=emranlib --cc=emcc --cxx=em++ --objcc=emcc --dep-cc=emcc --enable-pic --enable-gpl --enable-libx264
# emmake make "${MAKEFLAGS}"

# echo "Building ffmpeg-flac"
# mkdir -p $build_path/ffmpeg-flac
# cd $build_path/ffmpeg-flac
# emconfigure $source_path/ffmpeg/configure --target-os=none --arch=x86_32 --enable-cross-compile --disable-x86asm --disable-inline-asm --disable-stripping --disable-programs --disable-doc --disable-runtime-cpudetect --disable-autodetect --disable-pthreads --pkg-config-flags="--static" --nm="$source_path/emsdk/upstream/bin/llvm-nm" --ar=emar --ranlib=emranlib --cc=emcc --cxx=em++ --objcc=emcc --dep-cc=emcc --enable-pic --disable-everything --enable-decoder=flac
# emmake make "${MAKEFLAGS}"

# echo "Building ffmpeg-mpeg1"
# mkdir -p $build_path/ffmpeg-mpeg1
# cd $build_path/ffmpeg-mpeg1
# emconfigure $source_path/ffmpeg/configure --target-os=none --arch=x86_32 --enable-cross-compile --disable-x86asm --disable-inline-asm --disable-stripping --disable-programs --disable-doc --disable-runtime-cpudetect --disable-autodetect --disable-pthreads --pkg-config-flags="--static" --nm="$source_path/emsdk/upstream/bin/llvm-nm" --ar=emar --ranlib=emranlib --cc=emcc --cxx=em++ --objcc=emcc --dep-cc=emcc --enable-pic --disable-everything --enable-decoder=mpeg1video
# emmake make "${MAKEFLAGS}"

# echo "Building ffmpeg-hevc"
# mkdir -p $build_path/ffmpeg-hevc
# cd $build_path/ffmpeg-hevc
# emconfigure $source_path/ffmpeg/configure --target-os=none --arch=x86_32 --enable-cross-compile --disable-x86asm --disable-inline-asm --disable-stripping --disable-programs --disable-doc --disable-runtime-cpudetect --disable-autodetect --disable-pthreads --pkg-config-flags="--static" --nm="$source_path/emsdk/upstream/bin/llvm-nm" --ar=emar --ranlib=emranlib --cc=emcc --cxx=em++ --objcc=emcc --dep-cc=emcc --enable-pic --disable-everything --enable-decoder=hevc
# emmake make "${MAKEFLAGS}"

# echo "Building ffmpeg-dmx"
# mkdir -p $build_path/ffmpeg-dmx
# cd $build_path/ffmpeg-dmx
# emconfigure $source_path/ffmpeg/configure --target-os=none --arch=x86_32 --enable-cross-compile --disable-decoders --disable-x86asm --disable-inline-asm --disable-stripping --disable-programs --disable-doc --disable-runtime-cpudetect --disable-autodetect --disable-pthreads --pkg-config-flags="--static" --nm="$source_path/emsdk/upstream/bin/llvm-nm" --ar=emar --ranlib=emranlib --cc=emcc --cxx=em++ --objcc=emcc --dep-cc=emcc --enable-pic  --disable-encoders --disable-parsers --disable-muxers --disable-protocols --disable-filters  --disable-indevs  --disable-bsfs --enable-protocol=file
# emmake make "${MAKEFLAGS}"

# echo "Building ffmpeg-full"
# mkdir -p $build_path/ffmpeg-full
# cd $build_path/ffmpeg-full
# emconfigure $source_path/ffmpeg/configure --target-os=none --arch=x86_32 --enable-cross-compile --disable-x86asm --disable-inline-asm --disable-stripping --disable-programs --disable-doc --disable-runtime-cpudetect --disable-autodetect --disable-pthreads --pkg-config-flags="--static" --nm="$source_path/emsdk/upstream/bin/llvm-nm" --ar=emar --ranlib=emranlib --cc=emcc --cxx=em++ --objcc=emcc --dep-cc=emcc --enable-pic --enable-gpl
# emmake make "${MAKEFLAGS}"


echo "Building gpac"
cd $source_path/gpac
source $source_path/gpac/check_revision.sh

mkdir -p $build_path/gpac
cd $build_path/gpac
gpac_flags="--enable-pic --use-xvid=no --disable-qjs --use-png=no --use-jpeg=no --disable-ogg --use-vorbis=no --extra-libs=-sERROR_ON_UNDEFINED_SYMBOLS=0"

if test "$debuginfo" = "yes"; then
    gpac_flags+=" --enable-debug --extra-cflags=-g"
fi
emconfigure $source_path/gpac/configure $gpac_flags
emmake make "${MAKEFLAGS}"

echo "Building gpac minimal"
mkdir -p $build_path/gpac_minimal
cd $build_path/gpac_minimal
gpac_flags="--enable-pic --disable-all --enable-fin --enable-fout --enable-writegen --enable-resample --enable-reframer --enable-log --disable-qjs --use-png=no --use-jpeg=no --use-vorbis=no --disable-ogg --use-xvid=no --extra-libs=-sERROR_ON_UNDEFINED_SYMBOLS=0"

if test "$debuginfo" = "yes"; then
    # --enable-debug alone only drops optimization to -O0 and keeps
    # asserts (see gpac/configure); it never actually adds -g, so
    # libgpac_static.a ends up with zero debug symbols regardless. The
    # EMCCFLAGS="-g" set above is a dead variable (never exported/used) -
    # --extra-cflags is the actual passthrough gpac/configure supports.
    gpac_flags+=" --enable-debug --extra-cflags=-g"
fi
emconfigure $source_path/gpac/configure $gpac_flags
# "lib" only: the default "all" target also links the gpac/mp4box CLI
# tools, which need filters (http/net, isobmff writers, ...) this minimal
# build deliberately drops via --disable-all, so that link fails. We only
# need libgpac_static.a to embed into solver_minimal.
emmake make lib "${MAKEFLAGS}"

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
#git submodule update --init --recursive
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
emconfigure ./configure --disable-assembly --disable-pthread CFLAGS="-fPIC"
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

echo "Building h264bsd"
mkdir -p $build_path/h264bsd
cd $build_path/h264bsd
h264bsd_cflags="-fPIC -O3"
if test "$debuginfo" = "yes"; then
    h264bsd_cflags="-fPIC -O0 -g"
fi
emcc -c $h264bsd_cflags -I$source_path/h264bsd/src $source_path/h264bsd/src/*.c
emar rcs libh264bsd.a *.o

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
emconfigure $source_path/libmpeg2/configure  --host=generic-unknown-linux-gnu --disable-sdl  --enable-static --with-pic
emmake make "${MAKEFLAGS}"


echo "Building libfaad"
cd $source_path/libfaad
mkdir -p $build_path/libfaad
cd $build_path/libfaad
emcmake cmake $source_path/faad2 $CMAKE_BUILD_TYPE
emmake make "${MAKEFLAGS}"

echo "Building libraw"
cd $source_path/libraw
autoreconf --install
mkdir -p $build_path/libraw
cd $build_path/libraw
emconfigure $source_path/libraw/configure --disable-examples --disable-jasper --disable-openmp CFLAGS="-fPIC" CXXFLAGS="-fPIC"
emmake make "${MAKEFLAGS}"

echo "Building libde265"
mkdir -p $build_path/libde265
cd $build_path/libde265
emcmake cmake $source_path/libde265  $CMAKE_BUILD_TYPE -DBUILD_SHARED_LIBS=OFF
emmake make "${MAKEFLAGS}"


echo "Building libheif"
mkdir -p $build_path/libheif
cd $build_path/libheif
CONFIGURE_ARGS="-DENABLE_MULTITHREADING_SUPPORT=OFF -DWITH_GDK_PIXBUF=OFF -DWITH_EXAMPLES=OFF -DBUILD_SHARED_LIBS=OFF -DENABLE_PLUGIN_LOADING=OFF -DWITH_LIBDE265=ON -DBUILD_TESTING=OFF -DLIBDE265_INCLUDE_DIR=$source_path/libde265 -DLIBDE265_LIBRARY=$build_path/libde265/libde265/libde265.a"
emcmake cmake $source_path/libheif  $CONFIGURE_ARGS $CMAKE_BUILD_TYPE  -DCMAKE_C_FLAGS="-fpic -D__EMSCRIPTEN_STANDALONE_WASM__" -DCMAKE_CXX_FLAGS="-fpic -D__EMSCRIPTEN_STANDALONE_WASM__"
emmake make "${MAKEFLAGS}"

echo "Building libaom"
mkdir -p $build_path/libaom
cd $build_path/libaom
emcmake cmake $source_path/libaom  $CMAKE_BUILD_TYPE -DAOM_TARGET_CPU=generic -DENABLE_DOCS=OFF -DENABLE_TESTS=OFF -DENABLE_EXAMPLES=OFF -DENABLE_TOOLS=OFF -DBUILD_SHARED_LIBS=OFF -DCMAKE_C_FLAGS="-fpic"
emmake make "${MAKEFLAGS}"

# echo "Building dav1d"
# mkdir -p $build_path/dav1d
# cd $build_path/dav1d
# meson setup build \
#   --cross-file cross_wasm.txt \
#   -Ddefault_library=static \
#   -Denable_asm=false \
#   -Denable_tools=false \
#   -Denable_tests=false \
#   --buildtype release

# ninja -C build


echo "Building timidity"
cd $source_path/timidity
autoreconf -fiv
mkdir -p $build_path/timidity
cd $build_path/timidity
emconfigure $source_path/timidity/configure CFLAGS="-std=gnu89 -Wno-implicit-function-declaration -Wno-implicit-int -fPIC"
emmake make "${MAKEFLAGS}" -C libarc
emmake make "${MAKEFLAGS}" -C libunimod

echo "Building libtiff"
cd $source_path/libtiff
./autogen.sh
mkdir -p $build_path/libtiff
cd $build_path/libtiff
emconfigure $source_path/libtiff/configure --disable-shared --disable-tools --disable-tests --disable-contrib --disable-docs CFLAGS="-fPIC" CXXFLAGS="-fPIC" --with-pic
emmake make "${MAKEFLAGS}"

echo "Building libaiff"
cd $source_path/libaiff
./autogen.sh
mkdir -p $build_path/libaiff
cd $build_path/libaiff
emconfigure $source_path/libaiff/configure --disable-shared --enable-static --disable-tools --disable-tests --disable-docs CFLAGS="-fPIC"
emmake make "${MAKEFLAGS}"

echo "Building flac"
cd $source_path/flac
./autogen.sh
mkdir -p $build_path/flac
cd $build_path/flac
emconfigure $source_path/flac/configure --disable-shared --enable-static --disable-programs --disable-examples --disable-ogg CFLAGS="-fPIC"
emmake make "${MAKEFLAGS}"

echo "Building opus"
cd $source_path/opus
mkdir -p $build_path/opus
cd $build_path/opus
emcmake cmake $source_path/opus  $CMAKE_BUILD_TYPE -DCMAKE_POSITION_INDEPENDENT_CODE=ON
emmake make "${MAKEFLAGS}"


echo "Building mpg123"
cd $source_path/mpg123
touch aclocal.m4 configure Makefile.in src/config.h.in
mkdir -p $build_path/mpg123
cd $build_path/mpg123
emconfigure $source_path/mpg123/configure CFLAGS="-fPIC -O2" --disable-shared --enable-static --disable-modules --disable-audiolibs --disable-mpg123-surround --with-cpu=generic --disable-aesl
emmake make "${MAKEFLAGS}"

echo "Building nestegg"
cd $source_path/nestegg
autoreconf -ivf
mkdir -p $build_path/nestegg
cd $build_path/nestegg
emconfigure $source_path/nestegg/configure --disable-shared --enable-static CFLAGS="-fPIC"
emmake make "${MAKEFLAGS}"

echo "Building libvpx"
cd $source_path/libvpx
mkdir -p $build_path/libvpx
cd $build_path/libvpx
CFLAGS="-fPIC" CXXFLAGS="-fPIC"  emconfigure $source_path/libvpx/configure --target=generic-gnu --enable-static --disable-shared --enable-pic --disable-multithread --disable-runtime-cpu-detect --disable-examples --disable-tools --disable-unit-tests --disable-docs --disable-vp8-encoder --disable-vp9-encoder
CFLAGS="-fPIC" CXXFLAGS="-fPIC"  emmake make "${MAKEFLAGS}"


echo "Building poppler"
cd $source_path/poppler
PATCH_FILE_POPPLER="$source_path/poppler.patch"
echo $PATCH_FILE_POPPLER
if git apply --check "$PATCH_FILE_POPPLER" >/dev/null 2>&1; then
    echo "Applying poppler patch"
    git apply "$PATCH_FILE_POPPLER"
fi

mkdir -p $build_path/poppler
cd $build_path/poppler
emcmake cmake $source_path/poppler  $CMAKE_BUILD_TYPE -DFONT_CONFIGURATION=generic -DENABLE_LIBOPENJPEG=OFF -DENABLE_CMS=none -DENABLE_DCTDECODER=OFF -DENABLE_NSS3=OFF -DENABLE_GPGME=OFF -DENABLE_LIBTIFF=OFF -DENABLE_QT5=OFF -DENABLE_QT6=OFF -DENABLE_LCMS=OFF -DENABLE_LIBCURL=OFF -DENABLE_BOOST=OFF -DBUILD_SHARED_LIBS=OFF -DCMAKE_POSITION_INDEPENDENT_CODE=ON
emmake make "${MAKEFLAGS}"

echo "Building libbpg"
cp $source_path/libbpg-CMakeLists.txt $source_path/libbpg/CMakeLists.txt
mkdir -p $build_path/libbpg
cd $build_path/libbpg
emcmake cmake $source_path/libbpg $CMAKE_BUILD_TYPE
emmake make "${MAKEFLAGS}"

echo "Building libavif"
cd $source_path/libavif
mkdir -p $build_path/libavif
cd $build_path/libavif
emcmake cmake $source_path/libavif  $CMAKE_BUILD_TYPE -DBUILD_SHARED_LIBS=OFF -DAVIF_CODEC_AOM=OFF -DAVIF_LIBYUV=OFF -DAVIF_LIBSHARPYUV=OFF -DAVIF_JPEG=OFF -DAVIF_ZLIBPNG=OFF -DAVIF_BUILD_APPS=OFF
emmake make "${MAKEFLAGS}"

echo "Building libx265"
cd $source_path/x265_git
mkdir -p $build_path/x265_git
cd $build_path/x265_git
emcmake cmake $source_path/x265_git/source $CMAKE_BUILD_TYPE -DENABLE_ASSEMBLY=OFF -DENABLE_SHARED=OFF -DENABLE_CLI=OFF -DX64=1 -DX86_64=1
emmake make "${MAKEFLAGS}"

echo "Building lame"
cd $source_path
wget -nc https://downloads.sourceforge.net/project/lame/lame/4.0/lame-4.0.tar.gz
tar -xf lame-4.0.tar.gz
mkdir -p $build_path/lame-4.0
cd $build_path/lame-4.0
CFLAGS="-fPIC -O3" emconfigure $source_path/lame-4.0/configure --enable-static --disable-shared --disable-decoder --disable-frontend --disable-nasm --host=generic-unknown-linux-gnu
emmake make "${MAKEFLAGS}"

echo "Building fdk-aac"
cd $source_path/fdk-aac
mkdir -p $build_path/fdk-aac
cd $build_path/fdk-aac
emcmake cmake $source_path/fdk-aac $CMAKE_BUILD_TYPE -DBUILD_SHARED_LIBS=OFF
emmake make "${MAKEFLAGS}"
