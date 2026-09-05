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
gpac_flags="--enable-pic --disable-all --enable-fin --enable-fout --enable-writegen --enable-resample --enable-reframer --enable-log --disable-qjs --use-png=no --use-jpeg=no --use-vorbis=no --disable-ogg --use-xvid=no --disable-sdl --extra-libs=-sERROR_ON_UNDEFINED_SYMBOLS=0"

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
emcmake cmake $source_path/faad2 $CMAKE_BUILD_TYPE -DCMAKE_C_FLAGS="-fPIC" -DBUILD_SHARED_LIBS=OFF -DFAAD2_BUILD_PROGRAMS=OFF -DFAAD2_BUILD_TESTS=OFF -DFAAD2_BUILD_EXAMPLES=OFF -DFAAD2_ENABLE_STATIC=ON -DFAAD2_ENABLE_PIC=ON
emmake make "${MAKEFLAGS}"

echo "Building libraw"
cd $source_path/libraw
autoreconf --install
mkdir -p $build_path/libraw
cd $build_path/libraw
emconfigure $source_path/libraw/configure --disable-examples --disable-jasper --disable-openmp CFLAGS="-fPIC -fvisibility=hidden" CXXFLAGS="-fPIC -fvisibility=hidden -fvisibility-inlines-hidden"
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
CFLAGS="-fPIC" emconfigure $source_path/flac/configure --disable-shared --enable-static --disable-programs --disable-examples --disable-ogg PANDOC=no
CFLAGS="-fPIC" emmake make "${MAKEFLAGS}"

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
emcmake cmake $source_path/poppler  $CMAKE_BUILD_TYPE -DFONT_CONFIGURATION=generic -DENABLE_LIBOPENJPEG=OFF -DENABLE_CMS=none -DENABLE_DCTDECODER=OFF -DENABLE_NSS3=OFF -DENABLE_GPGME=OFF -DENABLE_LIBTIFF=OFF -DENABLE_QT5=OFF -DENABLE_QT6=OFF -DENABLE_LCMS=OFF -DENABLE_LIBCURL=OFF -DENABLE_BOOST=OFF -DBUILD_SHARED_LIBS=OFF -DENABLE_LIBJPEG=OFF -DCMAKE_POSITION_INDEPENDENT_CODE=ON
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

echo "Building vvdec"
# The vvdec submodule must stay on the v3.2.0 tag. On master as of
# v3.2.0-30-g81156d6 ("make VPS, SPS, PPS shared_ptrs also" and following),
# vvdec::Picture::finalInit dereferences a null pointer and the decoder
# segfaults after ~10 pictures - reproduced with the stock upstream vvdecapp
# built natively, single- and multi-threaded, so it is not specific to this
# wasm build or to the filter driving it.
cd $source_path/vvdec
# Same idiom as poppler above: the local adaptations (C++17, making the WASM
# -pthread compile flag opt-out, and dropping the embind bindings) live in a
# patch file instead of an in-place perl rewrite, so re-running this script is
# idempotent.
PATCH_FILE_VVDEC="$source_path/vvdec.patch"
if git apply --check "$PATCH_FILE_VVDEC" >/dev/null 2>&1; then
    echo "Applying vvdec patch"
    git apply "$PATCH_FILE_VVDEC"
fi

mkdir -p $build_path/vvdec
cd $build_path/vvdec
# - VVDEC_ENABLE_WASM_PTHREADS=OFF: see vvdec.patch. The filter drives the
#   decoder with vvdecParams.threads = 0, i.e. fully in the calling thread.
# - VVDEC_ENABLE_X86_SIMD=OFF: keeps vvdec scalar. The WASM branch of vvdec's
#   CMakeLists otherwise adds -msimd128, which no other module in this player
#   is built with. Turn it back ON (and accept the simd128 requirement) if
#   decoding speed matters more than uniformity.
# - VVDEC_ENABLE_WASM_BINDINGS=OFF: see vvdec.patch. Drops vvdec's embind JS
#   bindings, which the filter does not use and which no longer compile against
#   emscripten 6.0.8's embind headers.
# - VVDEC_ENABLE_WERROR=OFF: upstream builds with -Werror, and the emscripten
#   clang warns on constructs (unused templates/functions/local typedefs) that
#   the native builds do not.
# - VVDEC_ENABLE_LINK_TIME_OPT=OFF: avoids shipping LTO bitcode in the .a that
#   is later linked into a side module.
# - VVDEC_TOPLEVEL_OUTPUT_DIRS=OFF: keeps artifacts in the build tree instead
#   of writing them back into the vvdec submodule's bin/ and lib/.
emcmake cmake $source_path/vvdec $CMAKE_BUILD_TYPE \
  -DBUILD_SHARED_LIBS=OFF \
  -DVVDEC_LIBRARY_ONLY=ON \
  -DVVDEC_ENABLE_WASM_PTHREADS=OFF \
  -DVVDEC_ENABLE_X86_SIMD=OFF \
  -DVVDEC_ENABLE_WASM_BINDINGS=OFF \
  -DVVDEC_ENABLE_WERROR=OFF \
  -DVVDEC_ENABLE_LINK_TIME_OPT=OFF \
  -DVVDEC_TOPLEVEL_OUTPUT_DIRS=OFF \
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
  -DCMAKE_CXX_FLAGS="-fPIC" \
  -DCMAKE_C_FLAGS="-fPIC"

# "vvdec" only: the default "all" target also builds tests/vvdec_unit_test,
# an executable whose link still carries vvdec's WASM -sUSE_PTHREADS link
# options and therefore fails against these non-pthread objects. Only
# libvvdec.a is needed here.
emmake make vvdec "${MAKEFLAGS}"

# ---------------------------------------------------------------------------
# Image decoders added for the still-image formats (GIF, WebP, JPEG-LS, JPEG XR,
# JBIG/JBIG2, DjVu, FLIF, ICNS, IFF/ILBM, XCF, PSD, JPEG XT, Exif).
# ---------------------------------------------------------------------------

# jbigkit and jxrlib call "ar" and "ranlib" by name in their makefiles instead
# of honouring $(AR), so a command-line AR=emar has no effect on them. Put
# emar/emranlib in front of the system ones on PATH for those two builds only.
mkdir -p $build_path/emar-shim
printf '#!/bin/sh\nexec emar "$@"\n' > $build_path/emar-shim/ar
printf '#!/bin/sh\nexec emranlib "$@"\n' > $build_path/emar-shim/ranlib
chmod +x $build_path/emar-shim/ar $build_path/emar-shim/ranlib

echo "Building giflib"
# giflib has no out-of-tree build, so build in the source tree like xvid and
# copy the result out. "libgif.a" only: the default target also builds the
# gifbuild/giftext utilities.
cd $source_path/giflib
emmake make libgif.a CC=emcc AR=emar
mkdir -p $build_path/giflib
cp $source_path/giflib/libgif.a $build_path/giflib

echo "Building libwebp"
mkdir -p $build_path/libwebp
cd $build_path/libwebp
emcmake cmake $source_path/libwebp -DCMAKE_C_FLAGS="-fpic" -DBUILD_SHARED_LIBS=OFF -DWEBP_BUILD_ANIM_UTILS=OFF -DWEBP_BUILD_CWEBP=OFF -DWEBP_BUILD_DWEBP=OFF -DWEBP_BUILD_GIF2WEBP=OFF -DWEBP_BUILD_IMG2WEBP=OFF -DWEBP_BUILD_VWEBP=OFF -DWEBP_BUILD_WEBPINFO=OFF -DWEBP_BUILD_WEBPMUX=OFF -DWEBP_BUILD_EXTRAS=OFF -DWEBP_BUILD_WEBP_JS=OFF $CMAKE_BUILD_TYPE
emmake make "${MAKEFLAGS}"

echo "Building charls"
mkdir -p $build_path/charls
cd $build_path/charls
emcmake cmake $source_path/charls -DCMAKE_CXX_FLAGS="-fPIC" -DBUILD_SHARED_LIBS=OFF -DCHARLS_BUILD_TESTS=OFF -DCHARLS_BUILD_SAMPLES=OFF -DCHARLS_BUILD_CLI=OFF -DCHARLS_INSTALL=OFF $CMAKE_BUILD_TYPE
emmake make "${MAKEFLAGS}"

echo "Building jbigkit"
# In-tree again (plain handwritten makefile), and only the library: the default
# target also builds the tstcodec test program.
cd $source_path/jbig/libjbig
PATH=$build_path/emar-shim:$PATH emmake make libjbig.a CC=emcc CFLAGS="-O2 -fPIC"
mkdir -p $build_path/jbig
cp $source_path/jbig/libjbig/libjbig.a $build_path/jbig

echo "Building jbig2dec"
cd $source_path/jbig2dec
[ -f configure ] || LIBTOOLIZE=$(command -v libtoolize || command -v glibtoolize) autoreconf -fi
mkdir -p $build_path/jbig2dec
cd $build_path/jbig2dec
emconfigure $source_path/jbig2dec/configure --enable-static --disable-shared --without-libpng CFLAGS="-fPIC"
emmake make "${MAKEFLAGS}" libjbig2dec.la

echo "Building jxrlib"
mkdir -p $build_path/jxrlib
cd $source_path/jxrlib
# CFLAGS has to be restated in full because the makefile assigns it
# unconditionally, and the three -Wno-error flags are needed because jxrlib
# predates C99 conformance being enforced: _byteswap_ulong is defined in
# strcodec.c but declared in no header, and JXRGlue passes typed pointers to
# void** parameters. Same relaxations Debian carries as patches.
PATH=$build_path/emar-shim:$PATH emmake make CC=emcc DIR_BUILD=$build_path/jxrlib CFLAGS="-I. -Icommon/include -Iimage/sys -D__ANSI__ -DDISABLE_PERF_MEASUREMENT -w -Wno-error=implicit-function-declaration -Wno-error=incompatible-pointer-types -Wno-error=int-conversion -fPIC -O2" $build_path/jxrlib/libjpegxr.a $build_path/jxrlib/libjxrglue.a

echo "Building libexif"
cd $source_path/libexif
[ -f configure ] || LIBTOOLIZE=$(command -v libtoolize || command -v glibtoolize) autoreconf -fi
mkdir -p $build_path/libexif
cd $build_path/libexif
emconfigure $source_path/libexif/configure --enable-static --disable-shared --disable-nls --disable-docs CFLAGS="-fPIC"
emmake make "${MAKEFLAGS}"

echo "Building libicns"
cd $source_path/libicns
[ -f configure ] || LIBTOOLIZE=$(command -v libtoolize || command -v glibtoolize) autoreconf -fi
mkdir -p $build_path/libicns
cd $build_path/libicns
# libicns requires libpng even for the library part, and its configure link
# test has nothing to find in the emscripten sysroot, so point it at the libpng
# built above (source tree for png.h, build tree for pnglibconf.h).
emconfigure $source_path/libicns/configure --enable-static --disable-shared --without-jasper CFLAGS="-fPIC" CPPFLAGS="-I$source_path/libpng-code -I$build_path/libpng" LDFLAGS="-L$build_path/libpng" LIBS="-lpng16 -lz"
emmake make "${MAKEFLAGS}"

echo "Building libiff"
cd $source_path/libiff
[ -f configure ] || LIBTOOLIZE=$(command -v libtoolize || command -v glibtoolize) autoreconf -fi
mkdir -p $build_path/libiff
cd $build_path/libiff
emconfigure $source_path/libiff/configure --enable-static --disable-shared --prefix=$build_path/out CFLAGS="-fPIC"
# Library subdirectory only: the iffjoin/iffpp command line tools do not
# compile out of tree (they include "iff.h" without the source include path).
# It is installed into $build_path/out because libilbm links against it.
emmake make "${MAKEFLAGS}" -C src/libiff
emmake make -C src/libiff install

echo "Building libilbm"
cd $source_path/libilbm
[ -f configure ] || LIBTOOLIZE=$(command -v libtoolize || command -v glibtoolize) autoreconf -fi
mkdir -p $build_path/libilbm
cd $build_path/libilbm
# libilbm looks for libiff through pkg-config, which knows nothing about the
# emscripten prefix; its configure accepts these two variables instead.
LIBIFF_CFLAGS="-I$build_path/out/include" LIBIFF_LIBS="-L$build_path/out/lib -liff" emconfigure $source_path/libilbm/configure --enable-static --disable-shared --prefix=$build_path/out CFLAGS="-fPIC"
emmake make "${MAKEFLAGS}" -C src/libilbm

echo "Building flif"
mkdir -p $build_path/flif
cd $build_path/flif
# The CMake project lives in src/, and requires libpng (used by the encoder's
# PNG input path). Only the decoder library is built here; swap the target for
# flif_lib_static to get the encoder as well.
emcmake cmake $source_path/flif/src -DBUILD_SHARED_LIBS=OFF -DBUILD_STATIC_LIBS=ON -DPNG_LIBRARY=$build_path/libpng/libpng16.a -DPNG_PNG_INCLUDE_DIR="$source_path/libpng-code" -DCMAKE_CXX_FLAGS="-fPIC -I$build_path/libpng" $CMAKE_BUILD_TYPE
emmake make "${MAKEFLAGS}" flif_lib_dec_static

echo "Building djvulibre"
cd $source_path/djvulibre
[ -f configure ] || LIBTOOLIZE=$(command -v libtoolize || command -v glibtoolize) autoreconf -fi
mkdir -p $build_path/djvulibre
cd $build_path/djvulibre
emconfigure $source_path/djvulibre/configure --enable-static --disable-shared --disable-desktopfiles --disable-xmltools --disable-nls CXXFLAGS="-fPIC"
# libdjvu only: the tools/ directory builds djvused, ddjvu and friends, which
# are of no use here.
emmake make "${MAKEFLAGS}" -C libdjvu

echo "Building psd_sdk"
mkdir -p $build_path/psd_sdk
cd $build_path/psd_sdk
# Not the CMake build: it always compiles the platform NativeFile backend, and
# the Linux one includes <aio.h>, which emscripten does not have. The core
# library does not need it - a filter supplies its own psd::File implementation -
# so compile everything except those backends.
em++ -c -std=c++17 -fPIC ${EMCCFLAGS:--O3} -I$source_path/psd_sdk/src/Psd $(ls $source_path/psd_sdk/src/Psd/*.cpp | grep -v NativeFile)
emar rcs libpsd.a *.o

echo "Building libjpeg-xt"
cd $source_path/libjpeg-xt
# Built in the source tree: configure only writes an "automakefile" fragment
# that the in-tree Makefile includes.
# - ac_cv_func_setjmp/longjmp: configure's link test for them fails under emcc,
#   but emscripten does implement both, and the library refuses to compile
#   without them.
# - SETTINGS=clang: configure stores the full compiler path in SETTINGS and the
#   makefile then includes Makefile_Settings.$(SETTINGS); only the literal
#   "clang" and "gcc" variants exist.
ac_cv_func_longjmp=yes ac_cv_func_setjmp=yes emconfigure ./configure
emmake make "${MAKEFLAGS}" SETTINGS=clang AR=emar libstatic
mkdir -p $build_path/libjpeg-xt
cp $source_path/libjpeg-xt/libjpeg.a $build_path/libjpeg-xt

echo "Building xcftools"
cd $source_path/xcftools
# In-tree as well (its handwritten Makefile.in does not support VPATH builds),
# and only the converters: the default target also runs the gettext manpage
# rules. The two -include flags work around missing declarations under
# emscripten (munmap in io-unix.c, be64toh in xcf-general.c).
emconfigure ./configure --disable-nls CFLAGS="-fPIC -O2 -D_GNU_SOURCE -include sys/mman.h -include endian.h -I$source_path/libpng-code -I$build_path/libpng" LDFLAGS="-L$build_path/libpng"
emmake make "${MAKEFLAGS}" xcf2png xcf2pnm xcfinfo
mkdir -p $build_path/xcftools
cp $source_path/xcftools/xcf2png $source_path/xcftools/xcf2png.wasm $source_path/xcftools/xcf2pnm $source_path/xcftools/xcf2pnm.wasm $source_path/xcftools/xcfinfo $source_path/xcftools/xcfinfo.wasm $build_path/xcftools

# bcdec (DDS/BCn) is a single public-domain header, bcdec.h: include it from the
# filter with #define BCDEC_IMPLEMENTATION in one translation unit. Nothing to
# build here.

# Three submodules deliberately have no build step, none of them being portable
# to wasm32 as they stand:
# - svt-jpeg-xs: Source/Lib/*/ASM_SSE4_1 and ASM_AVX2 are compiled
#   unconditionally and use x86 intrinsics (__m128i); the CMake project also
#   requires a nasm/yasm assembler.
# - nitro: its coda-oss base aborts at configure time with "Unexpected Pointer
#   Size: 4 Bytes" - it assumes a 64-bit target.
# - vtflib: its CMake requires libtxc_dxtn, which is not vendored here. bcdec
#   above covers the same BC1-BC7 decompression if a VTF filter needs it.

# The four libraries below have no usable git remote (SVN-only or
# tarball-only upstreams, or a git tree that needs a source generator), so they
# are fetched as release tarballs the same way libjpeg, liba52, xvid, libmad
# and lame are, instead of being submodules.

echo "Building libmng"
cd $source_path
wget -nc https://downloads.sourceforge.net/project/libmng/libmng-devel/2.0.3/libmng-2.0.3.tar.gz
tar -xf libmng-2.0.3.tar.gz
# The tarball ships the maintainer's own generated config.h, which enables
# MNG_FULL_CMS. Every .c does #include "config.h", and a quoted include is
# resolved next to the including file first, so that copy would win over the one
# CMake generates and pull in lcms2. Drop it and let the -I path find CMake's.
rm -f $source_path/libmng-2.0.3/config.h
mkdir -p $build_path/libmng
cd $build_path/libmng
# JNG frames are JPEG-compressed, so libmng needs libjpeg: point it at the
# jpeg-9e tree built above the same way vorbis is pointed at the ogg build,
# since find_package(JPEG) has nothing to find in the emscripten sysroot.
# Set -DWITH_JPEG=OFF instead if MNG-without-JNG is enough.
# zlib comes from the emscripten sysroot (embuilder built it at the top of this
# script), like it does for libpng.
# -DTRUE/-DFALSE: libmng_types.h defines HAVE_BOOLEAN and its own "boolean"
# typedef to work around jpeg-9, which makes jmorecfg.h skip the enum that would
# otherwise declare TRUE and FALSE; libmng_jpeg.c uses them anyway.
emcmake cmake $source_path/libmng-2.0.3 -DCMAKE_C_FLAGS="-fpic -DTRUE=1 -DFALSE=0" -DBUILD_SHARED_LIBS=OFF -DBUILD_STATIC_LIBS=ON -DBUILD_MAN=OFF -DWITH_LCMS2=OFF -DWITH_LCMS1=OFF -DWITH_JPEG=ON -DJPEG_LIBRARY=$build_path/libjpeg/.libs/libjpeg.a -DJPEG_INCLUDE_DIR="$source_path/jpeg-9e;$build_path/libjpeg" $CMAKE_BUILD_TYPE
emmake make "${MAKEFLAGS}"

echo "Building libpgf"
cd $source_path
wget -nc https://downloads.sourceforge.net/project/libpgf/libpgf/6.14.12/libpgf-src-6.14.12.tar.gz
tar -xf libpgf-src-6.14.12.tar.gz
mkdir -p $build_path/pgf
cd $build_path/pgf
# The tarball unpacks to an unversioned "libpgf" directory, hence the "pgf"
# build directory, which would otherwise collide with it when build_path and
# source_path are the same. Its autotools setup is not usable: AC_OUTPUT is
# still called with the deprecated multi-line argument list and config.status
# then fails to find its own Makefile.in. The library is six .cpp files with no
# dependencies, so compile them directly.
# - -D__POSIX__: PGFplatform.h derives it from __linux__/__APPLE__/__GLIBC__,
#   none of which emscripten defines, and falls back to the Win32 branch.
# - -std=c++14: the sources use dynamic exception specifications
#   (throw(IOException)), removed in C++17, which is emcc's default.
em++ -c -fPIC -std=c++14 ${EMCCFLAGS:--O3} -D__POSIX__ -I$source_path/libpgf/include $source_path/libpgf/src/*.cpp
emar rcs libpgf.a Decoder.o Encoder.o PGFimage.o PGFstream.o Subband.o WaveletTransform.o

echo "Building libnsgif"
cd $source_path
wget -nc https://download.netsurf-browser.org/libs/releases/libnsgif-1.0.0-src.tar.gz
tar -xf libnsgif-1.0.0-src.tar.gz
mkdir -p $build_path/libnsgif
cd $build_path/libnsgif
# libnsgif's Makefile pulls in the separate netsurf-buildsystem package and
# does its own host/toolchain detection, neither of which survives emcc. The
# library is two C files with no dependencies, so compile them directly.
emcc -c -fPIC -std=c99 ${EMCCFLAGS:--O3} -I$source_path/libnsgif-1.0.0/include -I$source_path/libnsgif-1.0.0/src $source_path/libnsgif-1.0.0/src/gif.c $source_path/libnsgif-1.0.0/src/lzw.c
emar rcs libnsgif.a gif.o lzw.o

echo "Building recoil"
cd $source_path
wget -nc https://downloads.sourceforge.net/project/recoil/recoil/6.4.5/recoil-6.4.5.tar.gz
tar -xf recoil-6.4.5.tar.gz
mkdir -p $build_path/recoil
cd $build_path/recoil
# The git tree only holds the C source (recoil.ci) plus the transpiler
# invocation; the release tarball is the one that ships the generated recoil.c.
# Its makefile builds recoil2png and GIMP/ImageMagick plugins, none of which
# apply here, so compile the two library files directly.
emcc -c -fPIC ${EMCCFLAGS:--O3} -I$source_path/recoil-6.4.5 $source_path/recoil-6.4.5/recoil.c $source_path/recoil-6.4.5/recoil-stdio.c
emar rcs librecoil.a recoil.o recoil-stdio.o
