using BinaryBuilder, Pkg
using Base.BinaryPlatforms: arch, os, tags

name = "blasfeo"
version = v"0.1.4"

# Source
sources = [
    GitSource(
        "https://github.com/apozharski/blasfeo.git",
        "268f5244cc1e434b5dd5a5eceb6e42e9e3f0e849",  # current master branch
    ),
]


# Build
# Some notes from out of band conversations with @giaf:
#    - It only makes sense to build for the following platforms:
#        - X64_AMD_ZEN5: Specifically for AMD chips with good AVX512 implementation (desktop)
#            - Currently don't support this because it is _only_ useful for specifically Zen5
#        - X64_INTEL_HASWELL: Generically for any 64 bit hardware supporting AVX2 and FMA (including AMD chips?)
#        - X64_INTEL_SANDY_BRIDGE: For older Intel/AMD chips with avx support (what about chips with avx+fma?)
#        - ARMV8A_APPLE_M1: Same as other ARMV8 just with different alignment due to cache size difference?
#    - COLMAJ overhead for things e.g. HPIPM does is not so bad (@giaf wrote specific code to handle different sizes)
#      but best performance is still PANELMAJ.
#    - It does not make sense to compile the BLAS API because BLASFEO doesn't implement well or at all some things
#      that supporting this would require. Therefore, supporting this with libblastrampoline does not make sense.
function get_script(; platform::Platform)
    # Set TARGET and LA
    if arch(platform) == "x86_64"
        march = platform["march"]
        if platform["march"] == "avx"
            TARGET = "X64_INTEL_SANDY_BRIDGE"
            LA = "HIGH_PERFORMANCE"
        elseif platform["march"] == "avx2"
            TARGET = "X64_INTEL_HASWELL"
            LA = "HIGH_PERFORMANCE"
        elseif platform["march"] == "avx512" # TODO(@apozharski) This may not _actually_ make sense for SKYLAKE-X chips, but alas
            TARGET = "X64_AMD_ZEN5"
            LA = "HIGH_PERFORMANCE"
        else
            TARGET = "GENERIC"
            LA = "REFERENCE"
        end
    elseif arch(platform) == "aarch64" && os(platform) == "macos"
        if platform["march"] == "apple_m1"
            TARGET = "ARMV8A_APPLE_M1"
            LA = "HIGH_PERFORMANCE"
        else
            TARGET = "GENERIC"
            LA = "REFERENCE"
        end
    else
        TARGET = "GENERIC"
    end
    # Set OS variable
    if Sys.islinux(platform)
        OS = "LINUX"
    elseif Sys.isapple(platform)
        OS = "MAC"
    elseif Sys.iswindows(platform)
        OS = "WINDOWS"
    else
        error("unsupported platform")
    end

    script = raw"""
cd $WORKSPACE/srcdir/blasfeo
echo "
TARGET= """ * TARGET *
raw"""

LA= """ * LA *
raw"""

OS= """ * OS *
raw"""

MF = PANELMAJ
BLAS_API = 0
PREFIX = ${prefix}
" > Makefile.local
make shared_library -j ${nproc}
make install_shared
"""
end

# Platforms
platforms = [
    expand_microarchitectures(filter!((p) -> Sys.islinux(p) && arch(p) == "x86_64",supported_platforms()), ["x86_64","avx", "avx2","avx512"]);
    #expand_microarchitectures(filter!((p) -> Sys.iswindows(p) && arch(p) == "x86_64",supported_platforms()), ["x86_64","avx", "avx2","avx512"]); # windows support would require work in blasfeo
    expand_microarchitectures(filter!((p) -> Sys.isapple(p) && arch(p) == "x86_64",supported_platforms()), ["x86_64","avx", "avx2"]);
    expand_microarchitectures(filter!((p) -> Sys.isapple(p) && arch(p) == "aarch64",supported_platforms()), ["apple_m1"])
]
# Products
products = [
    LibraryProduct("libblasfeo", :blasfeo, "blasfeo/lib")
]

# Dependencies
dependencies = Dependency[]

for platform in platforms
    build_tarballs(
        ARGS,
        name,
        version,
        sources,
        get_script(;platform=platform),
        [platform],
        products,
        dependencies,
        julia_compat = "1.6",
        lock_microarchitecture=false, # blasfeo build handles march/m* flags
    )
end
