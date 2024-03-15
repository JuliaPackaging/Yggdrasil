# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Doxygen"
version = v"1.10.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/doxygen/doxygen/releases/download/Release_$(version.major)_$(version.minor)_$(version.patch)/doxygen-$(version).src.tar.gz",
                  "dd7c556b4d96ca5e682534bc1f1a78a5cfabce0c425b14c1b8549802686a4442"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/doxygen*

if [[ "${target}" == *-linux-* ]] || [[ "${target}" == *-freebsd* ]]; then
    atomic_patch -p1 ../patches/skip-iconv-in-glibc-test.patch
fi

# Avoid error
# /workspace/srcdir/doxygen-1.10.0/deps/filesystem/filesystem.hpp:4681:11: error: no member named 'utimensat' in the global namespace
# See <https://github.com/doxygen/doxygen/issues/10055>.
atomic_patch -p1 ../patches/utimensat.patch

mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ..
make -j${nproc}
make install

install_license ../LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("doxygen", :doxygen),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Libiconv_jll")),
]

# Build the tarballs, and possibly a `build.jl` as well.
# - compile error on g++ < 9
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version = v"9")
