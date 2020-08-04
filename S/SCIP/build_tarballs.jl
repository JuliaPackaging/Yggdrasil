# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SCIP"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://scip.zib.de/download/release/scipoptsuite-7.0.1.tgz", "971962f2d896b0c8b8fa554c18afd2b5037092685735d9494a05dc16d56ad422")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd scipoptsuite-7.0.1/
mkdir build
cd build/
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DPAPILO=0 -DZIMPL=OFF -DBOOST=off ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, libc=:glibc),
    Linux(:x86_64, libc=:glibc),
    Linux(:aarch64, libc=:glibc),
    Linux(:armv7l, libc=:glibc, call_abi=:eabihf),
    Linux(:powerpc64le, libc=:glibc),
    Linux(:i686, libc=:musl),
    Linux(:x86_64, libc=:musl),
    Linux(:aarch64, libc=:musl),
    Linux(:armv7l, libc=:musl, call_abi=:eabihf),
    MacOS(:x86_64),
    FreeBSD(:x86_64),
    Windows(:i686),
    Windows(:x86_64),
]

platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("scip", :scip),
    LibraryProduct("libgcg", :libgcg),
    LibraryProduct("libscip", :libscip),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="bliss_jll", uuid="508c9074-7a14-5c94-9582-3d4bc1871065"))
    Dependency(PackageSpec(name="GMP_jll", uuid="781609d7-10c4-51f6-84f2-b8444358ff6d"))
    Dependency(PackageSpec(name="Ipopt_jll", uuid="9cc047cb-c261-5740-88fc-0cf96f7bdcc7"))
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
    Dependency(PackageSpec(name="Readline_jll", uuid="05236dd9-4125-5232-aa7c-9ec0c9b2c25a"))
    Dependency(PackageSpec(name="Ncurses_jll", uuid="68e3532b-a499-55ff-9963-d1c0c0748b3a"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"5.2.0")
