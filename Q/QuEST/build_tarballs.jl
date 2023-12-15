# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "QuEST"
version = v"3.7.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/QuEST-Kit/QuEST.git", "d4f75f724993b4af8e43a796e3c09ce24ae11670")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/QuEST
cmake -B build \
    -DCMAKE_C_STANDARD=99 \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    .
cmake --build build --parallel ${nproc}
mkdir -p "${includedir}"
cp -vr $WORKSPACE/srcdir/QuEST/QuEST/include/* ${includedir}/
install -Dvm 755 build/QuEST/libQuEST.${dlext} ${libdir}/libQuEST.${dlext}
install_license LICENCE.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
filter!(platforms) do p
    !Sys.iswindows(p) &&
    !(BinaryBuilder.proc_family(p) != "intel" && Sys.islinux(p))
end

# The products that we will ensure are always built
products = [
    LibraryProduct("libQuEST", :libquest)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
