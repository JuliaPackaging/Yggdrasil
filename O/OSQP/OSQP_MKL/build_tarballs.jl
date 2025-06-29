# To ensure a build, it isn't sufficient to modify osqp_common.jl.
# You also need to update a line in this file:
#     Last updated: 2025-05-29

include("../osqp_common.jl")

# The MKL backend only supports double precision
bscript = build_script(algebra  = "mkl",
                       suffix   = "mkl",
                       usefloat = false,
                       builddir = "build")

script = init_env_script() * bscript

# The products that we will ensure are always built
products = [
    # Codegen is not part of the MKL version of the library
    LibraryProduct("libosqp_mkl", :osqp_mkl)
]

# We are limited to building on the platforms that support MKL
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("x86_64", "macos"),
    Platform("x86_64", "windows"),

    # MKL's CMake forces -m64 in the flags, so it doesn't work on 32-bit architectures right now
    # Platform("i686", "linux"; libc="glibc"),

    # i686 Windows does not have the import library for IntelOpenMP, so we are unable to build on that platform
    # Platform("i686", "windows"),
]

# This may look insane, but hear me out, this allows supporting both macOS and modern MKL versions.
#
# macOS requires MKL 2023.2.0 (or earlier), since 2024.0.0 removed support, however we don't want to pin
# other platforms to that MKL version because that could cause package conflicts down the line. Instead,
# we specify no compat bounds for MKL on the actual generated JLL (since we don't need a specific version
# right now) by using a RuntimeDependency.
#
# To build, we then introduce two BuildDependency sets:
# * One active on non-apple platforms that will use the most recent MKL_jll in the registry
# * One active on apple platforms that will use MKL_jll 2023.2.0
mkl_deps = [
    RuntimeDependency("MKL_jll"),

    BuildDependency("MKL_jll"; platforms=filter(!Sys.isapple, platforms)),
    BuildDependency("MKL_Headers_jll", platforms=filter(!Sys.isapple, platforms)),

    # MKL is no longer supported on macOS as of 2024.0.0, so we need 2023.2.0 on that platform
    BuildDependency(PackageSpec(; name="MKL_jll", version=v"2023.2.0"), platforms=filter(Sys.isapple, platforms)),
    BuildDependency(PackageSpec(; name="MKL_Headers_jll", version=v"2023.2.0"), platforms=filter(Sys.isapple, platforms)),
]

# Build the package
build_tarballs(ARGS, "OSQP_MKL", version, sources, script, platforms,
               products, [common_deps..., mkl_deps...]; julia_compat = "1.6")
