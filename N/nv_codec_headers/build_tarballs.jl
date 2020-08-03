# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "nv_codec_headers"
version = v"10.0.26"

# Collection of sources required to build this package
sources = [
    ArchiveSource("https://github.com/FFmpeg/nv-codec-headers/releases/download/n10.0.26.0/nv-codec-headers-10.0.26.0.tar.gz",
                  "2552723fef0adbed1c327e9cca167226b35d8a5d17fb86c753b71d70b26f141c"),
]

# Bash recipe for building across all platforms
script = raw"""
cd nv-codec-headers-*

mkdir ${prefix}/include
mv include/ffnvcodec ${prefix}/include/
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [AnyPlatform()]

# The products that we will ensure are always built
products = [
    FileProduct("include/ffnvcodec/dynlink_cuda.h", :dynlink_cuda_h),
    FileProduct("include/ffnvcodec/dynlink_cuviddec.h", :dynlink_cuviddec_h),
    FileProduct("include/ffnvcodec/dynlink_loader.h", :dynlink_loader_h),
    FileProduct("include/ffnvcodec/dynlink_nvcuvid.h", :dynlink_nvcuvid_h),
    FileProduct("include/ffnvcodec/nvEncodeAPI.h", :nvEncodeAPI_h),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
