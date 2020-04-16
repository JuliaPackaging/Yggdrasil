# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "HiGHS"
version = v"0.1.3"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/ERGO-Code/HiGHS.git", "2aa374196a132decaa190ef02e214486b7c2f3be"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
if [[ "${target}" == *86*-linux-musl* ]]; then
    pushd /opt/${target}/lib/gcc/${target}/*/include
    # Fix bug in Musl C library, see
    # https://github.com/JuliaPackaging/BinaryBuilder.jl/issues/387
    atomic_patch -p0 $WORKSPACE/srcdir/patches/mm_malloc.patch
    popd
fi
mkdir -p HiGHS/build
cd HiGHS/build
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF ..
make -j${nproc} highs
make install highs
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gfortran_versions(
    expand_cxxstring_abis(supported_platforms())
)
filter!(p -> !isa(p, Windows), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libhighs", :libhighs),
    LibraryProduct("libipx", :libipx)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"4.9")
