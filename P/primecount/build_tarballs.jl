# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

include(joinpath(@__DIR__, "..", "..", "platforms", "microarchitectures.jl"))

name = "primecount"
version = v"7.2.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/kimwalisch/primecount.git", "d65b5f1e17fc2689549d3a373c1765298caf78ba"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/primecount/
atomic_patch -p1 ../patches/0001-Allow-disabling-building-static-library-for-Windows.patch
mkdir build && cd build
# We disable popcnt in CMake settings, but we expand the microarchitectures to
# let the compiler deal with the appropriate flags.
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DBUILD_STATIC_LIBS=OFF \
    -DWITH_POPCNT=OFF \
    ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
# code contains std::string values
platforms = expand_cxxstring_abis(platforms)
# Let's limit expansion to x86_64.  For example I didn't see any difference
# between armv8_0 vs apple-m1 on the same hardware.
platforms = expand_microarchitectures(platforms; filter=p->arch(p)=="x86_64")

augment_platform_block = """
    $(MicroArchitectures.augment)

    function augment_platform!(platform::Platform)
        # We augment only x86_64
        @static if Sys.ARCH === :x86_64
            augment_microarchitecture!(platform)
        else
            platform
        end
    end
    """

# The products that we will ensure are always built
products = [
    ExecutableProduct("primecount", :primecount),
    LibraryProduct("libprimecount", :libprimecount),
    LibraryProduct("libprimesieve", :libprimesieve),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"5.2.0", julia_compat="1.6", augment_platform_block)
