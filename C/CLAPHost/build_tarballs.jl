# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

# The headless CLAP host from AudioPlugins.jl (https://github.com/SciML/AudioPlugins.jl):
# one C translation unit, `csrc/clap_host.c`, exposing a C ABI of scalar doubles
# for hosting CLAP audio plugins. CLAP itself is header-only (MIT) and vendored
# in the same repository, so this builds with nothing but a C compiler.
#
# The version tracks the AudioPlugins.jl release whose `csrc/` is built.
name = "CLAPHost"
version = v"1.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/SciML/AudioPlugins.jl.git",
              "a371d82d5a5a476280f8d0ef0571f2768b5f70c8"),  # v1.0.0
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/AudioPlugins.jl
install_license LICENSE csrc/vendor/CLAP-LICENSE

mkdir -p "${libdir}" "${includedir}"
LIBS="-lm"
if [[ "${target}" == *-linux-* ]]; then
    LIBS="${LIBS} -ldl"
fi
${CC} -std=gnu99 -O2 -fPIC -shared -Wall -Wextra \
    -o "${libdir}/libclap_host.${dlext}" csrc/clap_host.c ${LIBS}
install -Dm644 csrc/clap_host.h "${includedir}/clap_host.h"
"""

# The host resolves plugins with dlopen(); Windows needs a LoadLibrary shim
# that the sources do not have yet, so it is excluded until they do.
platforms = filter(!Sys.iswindows, supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libclap_host", :libclap_host),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10")
