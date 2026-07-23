using BinaryBuilder, Pkg

# libjulia's platform/version helpers (libjulia_platforms, julia_versions)
include(joinpath(@__DIR__, "../../L/libjulia/common.jl"))

function build_xrt_cxxwrap(ARGS, version::VersionNumber)
    name = "xrt_cxxwrap"

    sources = [
        GitSource("https://github.com/simeonschaub/XRT.jl.git",
                  "82352fee73b120160ff8f2104914bc2282640d8e"),
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
        Dependency("libcxxwrap_julia_jll"; compat="0.13"),
        Dependency("xrt_jll"; compat="~$(version.major).$(version.minor)"),
        Dependency("Libuuid_jll"; platforms=filter(Sys.islinux, platforms)),
        BuildDependency(PackageSpec(name="boost_jll", version="1.79.0")),
    ]

    build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
                   preferred_gcc_version=v"9", julia_compat="1.6")
end
