# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "xrt_cxxwrap"
version = v"0.1.0"

# The CxxWrap wrapper that XRT.jl (github.com/pc2/XRT.jl) currently compiles at
# first `using XRT` via `deps/build.jl`. Packaging it as a JLL removes that
# local build step: XRT.jl (and, downstream, IRON) can then depend on
# `xrt_cxxwrap_jll` and `@wrapmodule` the shipped `libxrtwrap` directly.
#
# The wrapper source lives under `deps/xrt_cxxwrap/` in the XRT.jl repo
# (CMakeLists.txt + src/xrtwrap.cpp). We build only that subtree here.
sources = [
    GitSource("https://github.com/simeonschaub/XRT.jl.git",
              "1be581bcbf8e01293d8f94853c8455c7893eef60"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/XRT.jl
install_license LICENSE
cd deps/xrt_cxxwrap

# --- Configure & build ------------------------------------------------------
# The wrapper (CMakeLists.txt + src/xrtwrap.cpp) self-adapts to both the old flat
# and the new (>= 2.20) nested XRT header layouts, so no source patching is needed
# here. xrt_jll, boost_jll and Libuuid_jll all install into ${prefix}; libcxxwrap's
# JlCxx CMake package is found via JlCxx_DIR, and Julia_PREFIX points its bundled
# FindJulia at libjulia_jll's julia.h (without it JlCxx's headers pull in a julia.h
# that isn't on the include path). XRT_VERSION_NUMBER stamps the library SONAME
# suffix (libxrtwrap.so.<major>.<minor>) that XRT.jl's `XRTWrap.libname()` looks up
# -- keep it in step with the xrt_jll major.minor.
XRT_VER_MM="2.23"

cmake -S . -B build \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DJlCxx_DIR=${prefix}/lib/cmake/JlCxx \
    -DJulia_PREFIX=${prefix} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=17 \
    -DXILINX_XRT=${prefix} \
    -DLIB_UUID_DIR=${prefix} \
    -DLIB_BOOST_DIR=${prefix} \
    -DXRT_VERSION_NUMBER=${XRT_VER_MM}

VERBOSE=ON cmake --build build --config Release --target install -- -j${nproc}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.
#
# CxxWrap wrappers are built per Julia version and per C++-string ABI, so we
# expand over libjulia's supported Julia versions like the other *_cxxwrap
# recipes. Only build for 64-bit Linux and Windows
include("../../L/libjulia/common.jl")
platforms = vcat(libjulia_platforms.(julia_versions)...)
filter!(p -> (Sys.islinux(p) && libc(p) == "glibc") || Sys.iswindows(p), platforms)
filter!(p -> arch(p) == "x86_64", platforms)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built.
# The library carries a versioned suffix (libxrtwrap.so.2.23) rather than a
# plain `.so`; the LibraryProduct glob still matches it.
products = [
    LibraryProduct("libxrtwrap", :libxrtwrap),
]

# Dependencies that must be installed before this package can be built.
#   * libcxxwrap_julia_jll  -- provides JlCxx (link) and must match the CxxWrap
#     version XRT.jl uses (CxxWrap 0.16 <-> libcxxwrap_julia 0.13). Bump both in
#     lockstep; a mismatch is an ABI break at @wrapmodule time.
#   * xrt_jll               -- headers + libxrt_coreutil (link).
#   * Libuuid_jll           -- libuuid (link).
#   * boost_jll             -- headers only (XRT's public headers include Boost).
dependencies = [
    BuildDependency("libjulia_jll"),
    Dependency("libcxxwrap_julia_jll"; compat="0.13"),
    Dependency(PackageSpec(; name = "xrt_jll", path = "/home/simeon/.julia/dev/xrt_jll")),#; compat="2.23"),
    Dependency("Libuuid_jll"; platforms=filter(Sys.islinux, platforms)),
    BuildDependency(PackageSpec(name="boost_jll", version="1.79.0")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"9", julia_compat="1.6")
