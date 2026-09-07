# iSAC, vendored

iSAC was removed from WebRTC in 2022 and no distribution packages it, so there
is no upstream git to point a submodule at. These are the sources, taken from
the last revision where the codec and the signal processing routines it calls
still matched each other:

    https://github.com/webrtc-sdk/webrtc
    branch main (m93_release), commit 9ea05f163f315b74facf9cf98f4f68f793e286e5

That pairing is the whole reason for pinning a revision rather than taking the
newest tree that still has the files. `WebRtcSpl_AnalysisQMF` was later changed
from int16 to float, while `isac/main` kept calling the int16 form; a checkout
that mixes the two compiles with warnings and decodes to noise.

What is here, and nothing else:

    modules/audio_coding/codecs/isac/main/{include,source}   the codec
    modules/audio_coding/codecs/isac/bandwidth_info.h
    modules/third_party/fft                                  the FFT it uses
    common_audio/signal_processing                           WebRtcSpl_*
    rtc_base/...                                             the few headers those include

C++ sources, unit tests and the SIMD variants (mips, neon, sse) are left out:
the C paths are what a WebAssembly build uses.

Licence: BSD-3-Clause, the WebRTC project's. See src/LICENSE upstream.
