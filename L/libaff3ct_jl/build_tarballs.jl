# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using BinaryBuilderBase

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "microarchitectures.jl"))

name = "libaff3ct_jl"
version = v"0.1.0"

sources = [
    GitSource("https://github.com/JuliaGNSS/libaff3ct_jl.git",
              "2d7645a4cae0ffd446bf51d0aef2bcbcac13a605"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/libaff3ct_jl*
rm -rf build && mkdir build && cd build

cmake .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH="${prefix}" \
    -DBUILD_TESTING=OFF
make -j${nproc}
make install

# Install license
install_license ${WORKSPACE}/srcdir/LICENSE
"""

# Must match the same platform set as aff3ct_jll
platforms = supported_platforms()
platforms = expand_cxxstring_abis(
    expand_microarchitectures(platforms, ["x86_64", "avx", "avx2", "avx512"])
)

augment_platform_block = """
    $(MicroArchitectures.augment)

    function augment_platform!(platform::Platform)
        @static if Sys.ARCH === :x86_64
            augment_microarchitecture!(platform)
        else
            platform
        end
    end
    """

products = [
    LibraryProduct("libaff3ct_jl", :libaff3ct_jl),
]

dependencies = [
    Dependency("aff3ct_jll"),
    Dependency("CompilerSupportLibraries_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"8",
               julia_compat="1.6",
               augment_platform_block)
