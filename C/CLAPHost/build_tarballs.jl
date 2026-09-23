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
#
# 1.1.0 rebuilds from a tree carrying SciML/AudioPlugins.jl#40, which lifted a
# fixed 32-entry descriptor cache in `clap_host_scan`. A CLAP module may hold
# hundreds of plugins in one file -- the Airwindows collection that
# Airwindows_jll ships is 504 -- and 1.0.1 reported any such module as holding
# 32, silently and indistinguishably from a module that really is that small.
# Airwindows_jll is unusable without this rebuild. Minor rather than patch
# because the scan ABI also *gained* functions (additive, nothing removed or
# changed): clap_host_scan_count, and the vendor/version/description and
# feature-keyword getters that a bundle registry needs to classify what it
# found.
name = "CLAPHost"
version = v"1.2.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/SciML/AudioPlugins.jl.git",
              "f48574da93f3fac9f3d612c16b60657043320c35"),  # SciML/AudioPlugins.jl main
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
