using BinaryBuilder, Pkg
using Base.BinaryPlatforms: arch, os, tags

const YGGDRASIL_DIR = "../.."
# For MicroArchitectures
include(joinpath(YGGDRASIL_DIR, "platforms", "microarchitectures.jl"))
# For should_build_platform
include(joinpath(YGGDRASIL_DIR,"fancy_toys.jl"))

name = "blasfeo"
version = v"0.1.4"

# Source
sources = [
    GitSource(
        "https://github.com/giaf/blasfeo.git",
        "2825f3368c3e02003a0c42500a0605f687c9ccc8",  # current master branch
    ),
]


# Build
# Some notes from out of band conversations with @giaf:
#    - It only makes sense to build for the following platforms:
#        - X64_AMD_ZEN5: Specifically for AMD chips with good AVX512 implementation (desktop)
#            - Currently support this but questionably useful because it is _only_ good on specifically Zen5 workstation
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
            LA = "HIGH_PERFORMANCE"
        end
    elseif arch(platform) == "aarch64" && os(platform) == "macos"
        if platform["march"] == "apple_m1"
            TARGET = "ARMV8A_APPLE_M1"
            LA = "HIGH_PERFORMANCE"
        else
            TARGET = "GENERIC"
            LA = "HIGH_PERFORMANCE"
        end
    else
        TARGET = "GENERIC"
        LA = "HIGH_PERFORMANCE"
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
    expand_microarchitectures(filter!((p) -> Sys.iswindows(p) && arch(p) == "x86_64",supported_platforms()), ["x86_64","avx", "avx2","avx512"]);
    expand_microarchitectures(filter!((p) -> Sys.isapple(p) && arch(p) == "x86_64",supported_platforms()), ["x86_64","avx", "avx2"]);
    expand_microarchitectures(filter!((p) -> Sys.isapple(p) && arch(p) == "aarch64",supported_platforms()), ["apple_m1"])
]
# Products
products = [
    LibraryProduct("libblasfeo", :blasfeo, "blasfeo/lib")
]

# augment_platform so we get the correct, that is fast, build
augment_platform_block = """
$(MicroArchitectures.augment)

function augment_platform!(platform::Platform)
    augment_microarchitecture!(platform)
end
"""

# Dependencies
dependencies = Dependency[]


for platform in platforms
    should_build_platform(platform) || continue # Don't build things on the wrong platforms
    # This is necessary because for mingw-gcc has problems with xmm registers on <v8.4 <v9.3 <10.
    # See this bug report: https://gcc.gnu.org/bugzilla/show_bug.cgi?id=65782
    # We set to v"10" because of how `preferred_gcc_version` works:
    # https://github.com/JuliaPackaging/Yggdrasil/pull/6843#issuecomment-1585288925
    gcc_ver = (Sys.iswindows(platform) && platform["march"] == "avx512") ? v"10" : nothing
    build_tarballs(
        ARGS,
        name,
        version,
        sources,
        get_script(;platform=platform),
        [platform],
        products,
        dependencies,
        julia_compat="1.6",
        augment_platform_block=augment_platform_block,
        lock_microarchitecture=false, # blasfeo build handles march/m* flags
        preferred_gcc_version=gcc_ver,
    )
end
