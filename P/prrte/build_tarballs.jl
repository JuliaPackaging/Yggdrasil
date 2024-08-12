# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "prrte"
version = v"3.0.2"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/openpmix/prrte/releases/download/v$(version)/prrte-$(version).tar.bz2",
                  "1aaa1bb930e8e940251ea682b4a6abc24e4849fa9ffbaaaaf2750a38ba4e474a"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/prrte-*

# Autotools doesn't add `${includedir}` as an include directory on some platforms
export CPPFLAGS="-I${includedir}"

./configure \
    --build=${MACHTYPE} \
    --enable-shared \
    --host=${target} \
    --prefix=${prefix} \
    --with-hwloc=${prefix} \
    --with-libevent=${prefix} \
    --with-pmix=${prefix}
make -j${nproc}
make install
"""

platforms = supported_platforms()
# PMIx is not supported on FreeBSD
filter!(!Sys.isfreebsd, platforms)
# `configure` does not find `libevent` on Windows (could probably be fixed)
filter!(!Sys.iswindows, platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("prte", :prte)
    ExecutableProduct("prun", :prun)
    ExecutableProduct("prte_info", :prte_info)
    ExecutableProduct("prterun", :prterun)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Hwloc_jll", uuid="e33a78d0-f292-5ffc-b300-72abe9b543c8")),
    Dependency(PackageSpec(name="PMIx_jll", uuid="32165bc3-0280-59bc-8c0b-c33b6203efab")),
    Dependency(PackageSpec(name="libevent_jll", uuid="1080aeaf-3a6a-583e-a51c-c537b09f60ec")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
