# Shared recipe body for xrt_cxxwrap_jll.
#
# Each `xrt_cxxwrap@<major.minor>` folder is a thin build_tarballs.jl that calls
# `build_xrt_cxxwrap` with the XRT version it targets. The JLL version follows XRT;
# between versions the only things that change are the xrt_jll compat bound and the
# XRT major.minor stamped into the wrapper's SONAME -- both derived here from
# `version`, so the two version folders differ only in the number they pass.
#
# The wrapper itself is XRT.jl's deps/xrt_cxxwrap (github.com/pc2/XRT.jl). Its
# source self-adapts to both the old flat and the new (>= 2.20) nested XRT header
# layouts, so one commit builds every version. Packaging it as a JLL removes XRT.jl's
# local compile-on-first-use (deps/build.jl): XRT.jl (and, downstream, IRON) can then
# depend on `xrt_cxxwrap_jll` and `@wrapmodule` the shipped `libxrtwrap` directly.
using BinaryBuilder, Pkg

# libjulia's platform/version helpers (libjulia_platforms, julia_versions). Resolved
# relative to this file, so it works however the version folders include us.
include("../../L/libjulia/common.jl")

function build_xrt_cxxwrap(ARGS, version::VersionNumber)
    name = "xrt_cxxwrap"

    # The wrapper source builds every supported XRT version unchanged.
    sources = [
        GitSource("https://github.com/simeonschaub/XRT.jl.git",
                  "82352fee73b120160ff8f2104914bc2282640d8e"),
    ]

    # XRT_VERSION_NUMBER stamps the library SONAME suffix (libxrtwrap.so.<maj>.<min>)
    # that XRT.jl's `XRTWrap.libname()` looks up -- keep it at the xrt_jll major.minor.
    script = "XRT_VER_MM=$(version.major).$(version.minor)\n" * raw"""
cd ${WORKSPACE}/srcdir/XRT.jl
install_license LICENSE
cd deps/xrt_cxxwrap

# --- Configure & build ------------------------------------------------------
# The wrapper (CMakeLists.txt + src/xrtwrap.cpp) self-adapts to both the old flat
# and the new (>= 2.20) nested XRT header layouts, so no source patching is needed.
# xrt_jll, boost_jll and Libuuid_jll all install into ${prefix}; libcxxwrap's JlCxx
# CMake package is found via JlCxx_DIR, and Julia_PREFIX points its bundled FindJulia
# at libjulia_jll's julia.h (without it JlCxx's headers pull in a julia.h that isn't
# on the include path).
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

    # CxxWrap wrappers are built per Julia version and per C++-string ABI, so expand
    # over libjulia's supported Julia versions like the other *_cxxwrap recipes. Only
    # 64-bit Linux and Windows, the platforms xrt_jll exists for.
    platforms = vcat(libjulia_platforms.(julia_versions)...)
    filter!(p -> (Sys.islinux(p) && libc(p) == "glibc") || Sys.iswindows(p), platforms)
    filter!(p -> arch(p) == "x86_64", platforms)
    platforms = expand_cxxstring_abis(platforms)

    # The library carries a versioned suffix (libxrtwrap.so.<maj>.<min>) on Linux and
    # the native libxrtwrap.dll on Windows; the LibraryProduct glob matches both.
    products = [
        LibraryProduct("libxrtwrap", :libxrtwrap),
    ]

    # Dependencies:
    #   * libcxxwrap_julia_jll  -- provides JlCxx (link). Must match the CxxWrap
    #     version XRT.jl uses (CxxWrap 0.16 <-> libcxxwrap_julia 0.13); a mismatch is
    #     an ABI break at @wrapmodule time.
    #   * xrt_jll               -- headers + libxrt_coreutil (link), pinned to the
    #     matching XRT minor series.
    #   * Libuuid_jll           -- libuuid (link); Linux only.
    #   * boost_jll             -- headers only (XRT's public headers include Boost).
    dependencies = [
        BuildDependency("libjulia_jll"),
        Dependency("libcxxwrap_julia_jll"; compat="0.13"),
        Dependency("xrt_jll"; compat="~$(version.major).$(version.minor)"),
        Dependency("Libuuid_jll"; platforms=filter(Sys.islinux, platforms)),
        BuildDependency(PackageSpec(name="boost_jll", version="1.79.0")),
    ]

    build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
                   preferred_gcc_version=v"9", julia_compat="1.6")
end
