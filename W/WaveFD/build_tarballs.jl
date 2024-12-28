# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "WaveFD"
version = v"0.6.1"

# Collection of sources required to build AzStorage
sources = [
    GitSource(
        "https://github.com/ChevronETC/WaveFD.jl.git",
        "b74720842f1f2fb7e836a8f2762aa78fd2ed1ce8"
    )
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/WaveFD.jl/src

CXXFLAGS="-funroll-loops"
if [[ "${target}" == i686-linux-gnu || "${target}" == x86_64-linux-gnu || "${target}" == powerpc6rle-linux-gnu ]]; then
    CXXFLAGS+=" -D__FUNCTION_CLONES__"
fi

echo "target=$target, CXXFLAGS=$CXXFLAGS"

cmake . -DCMAKE_CXX_FLAGS="${CXXFLAGS}" -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
make -j${nproc} VERBOSE=1
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libprop2DAcoIsoDenQ_DEO2_FDTD", :libprop2DAcoIsoDenQ_DEO2_FDTD),
    LibraryProduct("libprop2DAcoVTIDenQ_DEO2_FDTD", :libprop2DAcoVTIDenQ_DEO2_FDTD),
    LibraryProduct("libprop2DAcoTTIDenQ_DEO2_FDTD", :libprop2DAcoTTIDenQ_DEO2_FDTD),
    LibraryProduct("libprop3DAcoIsoDenQ_DEO2_FDTD", :libprop3DAcoIsoDenQ_DEO2_FDTD),
    LibraryProduct("libprop3DAcoVTIDenQ_DEO2_FDTD", :libprop3DAcoVTIDenQ_DEO2_FDTD),
    LibraryProduct("libprop3DAcoTTIDenQ_DEO2_FDTD", :libprop3DAcoTTIDenQ_DEO2_FDTD),
    LibraryProduct("libillumination", :libillumination),
    LibraryProduct("libspacetime", :libspacetime)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms)),
    Dependency("FFTW_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"9", allow_unsafe_flags=true, julia_compat="1.6")
