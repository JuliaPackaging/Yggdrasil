# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

include("../../platforms/macos_sdks.jl")

# AudioPlugins provides scalar-double singleton and instance hosting, plus the
# native live-session/device ABI. Its vendored C sources build directly with CC.
# Host JLL versions track this C ABI independently of the Julia package version.
name = "CLAPHost"
version = v"1.4.0"

# The source pin carries the explicit Windows host exports (https://github.com/SciML/AudioPlugins.jl/pull/99).
sources = [
    GitSource("https://github.com/SciML/AudioPlugins.jl.git",
              "5321b9ba259db907961eecc9edd42cdea7bd469e"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/AudioPlugins.jl
install_license LICENSE csrc/vendor/CLAP-LICENSE csrc/vendor/miniaudio.LICENSE

LIVE_LIBS="-pthread -lm"
if [[ "${target}" == *-mingw* ]]; then
    LIVE_LIBS="${LIVE_LIBS} -lavrt -lole32 -luuid -luser32 -lwinmm"
elif [[ "${target}" == *-apple-* ]]; then
    # __builtin_available needs ___isPlatformVersionAtLeast from compiler-rt
    LIVE_LIBS="${LIVE_LIBS} -framework CoreFoundation -framework CoreAudio -framework AudioToolbox -L${libdir}/darwin -lclang_rt.osx"
else
    LIVE_LIBS="${LIVE_LIBS} -ldl"
fi

mkdir -p "${libdir}" "${includedir}"
${CC} -std=gnu11 -O2 -fPIC -shared -Wall -Wextra -DAP_LIVE_WITH_DEVICE \
    -o "${libdir}/libclap_host.${dlext}" \
    csrc/clap_host.c csrc/clap_live.c csrc/live_device.c ${LIVE_LIBS}
install -Dm644 csrc/clap_host.h "${includedir}/clap_host.h"
install -Dm644 csrc/clap_live.h "${includedir}/clap_live.h"
install -Dm644 csrc/live_device.h "${includedir}/live_device.h"
"""

sources, script = require_macos_sdk("11.3", sources, script; deployment_target="10.15")

platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libclap_host", :libclap_host),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("LLVMCompilerRT_jll"; platforms = filter(Sys.isapple, platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", preferred_gcc_version=v"9")
