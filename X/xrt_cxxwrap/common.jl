using BinaryBuilder, Pkg

# libjulia's platform/version helpers (libjulia_platforms, julia_versions)
include(joinpath(@__DIR__, "../../L/libjulia/common.jl"))

function build_xrt_cxxwrap(ARGS, version::VersionNumber)
    name = "xrt_cxxwrap"

    sources = [
        GitSource("https://github.com/simeonschaub/XRT.jl.git",
                  "a494faa6023a81d2f0c8750d93e179df97e7e7dc"),
    ]

    script = "XRT_VER_MM=$(version.major).$(version.minor)\n" * raw"""
cd ${WORKSPACE}/srcdir/XRT.jl
install_license LICENSE
cd deps/xrt_cxxwrap

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

    platforms = vcat(libjulia_platforms.(julia_versions)...)
    filter!(p -> (Sys.islinux(p) && libc(p) == "glibc") || Sys.iswindows(p), platforms)
    filter!(p -> arch(p) == "x86_64", platforms)
    platforms = expand_cxxstring_abis(platforms)

    products = [
        LibraryProduct("libxrtwrap", :libxrtwrap),
    ]

    dependencies = [
        BuildDependency("libjulia_jll"),
        # 0.13 has no artifacts for Julia 1.14; 0.14 covers 1.10-1.14. Must match the
        # CxxWrap version XRT.jl uses (0.17 <-> libcxxwrap_julia 0.14).
        Dependency("libcxxwrap_julia_jll"; compat="0.14.8"),
        Dependency("xrt_jll"; compat="~$(version.major).$(version.minor)"),
        Dependency("Libuuid_jll"; platforms=filter(Sys.islinux, platforms)),
        BuildDependency(PackageSpec(name="boost_jll", version="1.79.0")),
    ]

    build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
                   preferred_gcc_version=v"9", julia_compat=libjulia_julia_compat(julia_versions))
end
