# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using BinaryBuilderBase

include(joinpath(@__DIR__, "..", "..", "platforms", "microarchitectures.jl"))

name = "ducc0"
version = v"0.29.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://gitlab.mpcdf.mpg.de/mtr/ducc.git", "d29050f2dff2a87dd430ddf2c82d590cc3aa42a4"),
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.15.sdk.tar.xz",
                  "2408d07df7f324d3beea818585a6d990ba99587c218a3969f924dfcc4de93b62"),
]

# Bash recipe for building across all platforms
script = raw"""

if [[ "${target}" == x86_64-apple-darwin* ]]; then
    # Install a newer SDK to work around compilation failures
    pushd $WORKSPACE/srcdir/MacOSX10.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    cp -ra usr/* "/opt/${target}/${target}/sys-root/usr/."
    cp -ra System "/opt/${target}/${target}/sys-root/."
    popd
    CXXFLAGS="-mmacosx-version-min=10.14"
fi

cd $WORKSPACE/srcdir/ducc*/julia
install_license ../LICENSE
${CXX} ${CXXFLAGS} -O3 -I ../src/ ducc_julia.cc -Wfatal-errors -pthread -std=c++17 -fPIC -fno-math-errno -fassociative-math -freciprocal-math -fno-signed-zeros -fno-trapping-math -ffp-contract=fast -ffinite-math-only -fno-rounding-math -fno-signaling-nans -fexcess-precision=fast -fvisibility=hidden -c
# -fcx-limited-range is not supported by clang
${CXX} ${CXXFLAGS} -O3 -o libducc_julia.${dlext} ducc_julia.o -Wfatal-errors -pthread -std=c++17 -shared -fPIC
install -Dvm 0755 "libducc_julia.${dlext}" "${libdir}/libducc_julia.${dlext}"
"""

# Expand for microarchitectures on x86_64 (library doesn't have CPU dispatching)
# Tests on Linux/x86_64 yielded a slow binary with avx512 for some reason, so disable that.
# Also, on Windows we want to avoid AVX/AVX2.
platforms = expand_cxxstring_abis(expand_microarchitectures(supported_platforms(), ["x86_64", "avx", "avx2"]; filter=!Sys.iswindows))

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
    LibraryProduct("libducc_julia", :libducc_julia)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll"; platforms=filter(p -> Sys.islinux(p) || Sys.isfreebsd(p), platforms))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"8", julia_compat="1.6", augment_platform_block)
