# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message
using BinaryBuilder, Pkg

name = "WFA2"
version = v"2.3.3"

# Collection of sources required to complete build
sources = [
    GitSource(
        "https://github.com/smarco/WFA2-lib.git",
        "d1116831a3514fff39321a73b8b526f17f7a2c18",
    ),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/WFA2-lib
install_license LICENSE
atomic_patch -p1 ../patches/remove_march_native.patch
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      -DOPENMP=TRUE \
      -DBUILD_SHARED_LIBS=ON ..
cmake --build . --parallel ${nproc} --target all
cmake --build . --target install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# Windows/MingW build: missing sys/mman headers
platforms = supported_platforms(; exclude = Sys.iswindows)

# The products that we will ensure are always built
products = [LibraryProduct("libwfa2", :libwfa2), LibraryProduct("libwfa2cpp", :libwfa2cpp)]

# Dependencies that must be installed before this package can be built
dependencies = [
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else
    Dependency(
        PackageSpec(;
            name = "CompilerSupportLibraries_jll",
            uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae",
        );
        platforms = filter(!Sys.isbsd, platforms),
    ),
    Dependency(
        PackageSpec(;
            name = "LLVMOpenMP_jll",
            uuid = "1d63c593-3942-5779-bab2-d838dc0a180e",
        );
        platforms = filter(Sys.isbsd, platforms),
    ),
]

# Build the tarballs, and possibly a `build.jl` as well
build_tarballs(
    ARGS,
    name,
    version,
    sources,
    script,
    platforms,
    products,
    dependencies;
    julia_compat = "1.6",
    preferred_gcc_version = v"6",
)

