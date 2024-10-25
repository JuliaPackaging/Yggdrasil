# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "FFLAS_FFPACK"
version = v"2.5.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/linbox-team/fflas-ffpack/releases/download/v$version/fflas-ffpack-$version.tar.gz", "dafb4c0835824d28e4f823748579be6e4c8889c9570c6ce9cce1e186c3ebbb23"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/fflas-ffpack-*

for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done

autoreconf
./configure CCNAM=${CC} CPLUS_INCLUDE_PATH=$includedir --prefix=$prefix --build=${MACHTYPE} --host=${target}

make -j ${nproc}
make install

install_license COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(exclude=Sys.iswindows) |> expand_cxxstring_abis

# The products that we will ensure are always built
products = [
    ExecutableProduct("fflas-ffpack-config", :fflas_ffpack_config)
    FileProduct("include/fflas-ffpack/fflas-ffpack-config.h", :fflas_ffpack_config_h)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GMP_jll"; compat="6.2.1"),
    Dependency("Givaro_jll"; compat="4.2.0"),
    Dependency("libblastrampoline_jll"; compat="5.4.0")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    clang_use_lld=false, julia_compat="1.9", preferred_gcc_version=v"6")
