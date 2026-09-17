# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

# The headless CLAP host from AudioPlugins.jl (https://github.com/SciML/AudioPlugins.jl):
# one C translation unit, `csrc/clap_host.c`, exposing a C ABI of scalar doubles
# for hosting CLAP audio plugins. CLAP itself is header-only (MIT) and vendored
# in the same repository, so this builds with nothing but a C compiler.
#
# CLAPHost_jll 1.0.0 was built from an earlier AudioPlugins.jl commit that
# already carried Project.toml version 1.0.0, so the JLL version can no longer
# equal the package version: 1.0.1 is the registered AudioPlugins v1.0.0
# sources, with Windows.
name = "CLAPHost"
version = v"1.0.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/SciML/AudioPlugins.jl.git",
              "1ba3d23b08c0159f66782a831f89cb729339d325"),  # v1.0.0 (registered)
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

platforms = supported_platforms()

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
