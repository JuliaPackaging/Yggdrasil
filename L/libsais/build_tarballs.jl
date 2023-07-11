# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libsais"
version = v"2.7.3"

# Collection of sources required to complete build
sources = [
    GitSource(
        "https://github.com/IlyaGrebnov/libsais.git",
        "558fa82fbb2ed441212a69e58cbb12c51a5f9b7b",
    ),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/libsais
install_license LICENSE
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} \
	-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
	-DLIBSAIS_USE_OPENMP=ON \
	-DLIBSAIS_BUILD_SHARED_LIB=ON \
	-DCMAKE_BUILD_TYPE=Release
make -j${nproc} all
install -Dvm 755 liblibsais.${dlext} ${libdir}/liblibsais.${dlext}
for file in ${WORKSPACE}/srcdir/libsais/include/*.h; do
	install -Dvm 644 ${file} ${includedir}/$(basename ${file})
done
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [LibraryProduct("liblibsais", :liblibsais)]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency(
        PackageSpec(
            name = "CompilerSupportLibraries_jll",
            uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae",
        );
        platforms = filter(!Sys.isbsd, platforms),
    ),
    Dependency(
        PackageSpec(
            name = "LLVMOpenMP_jll", 
            uuid = "1d63c593-3942-5779-bab2-d838dc0a180e"
        );
        platforms = filter(Sys.isbsd, platforms),
    ),
]

# Build the tarballs, and possibly a `build.jl` as well.
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
    preferred_gcc_version = v"9",
)
