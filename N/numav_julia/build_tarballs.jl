using BinaryBuilder, Pkg

name = "numav_julia"
version = v"0.2.0"

sources = [ 
    GitSource(
        "https://github.com/mmfiuza/numav.git", 
        "2e4f51b7c8ecceca09a4f9a7464f0017778daeb0"
    )
]

script = raw"""
    # oneMKL is picked for the available platforms, otherwise Eigen is picked
    if [[ ${target} == x86_64-linux-gnu* || ${target} == x86_64-w64* ]];
    then
        SOLVER=ONEMKL
    else
        SOLVER=EIGEN
    fi
    
    cd ${WORKSPACE}/srcdir/numav && mkdir build && cd build
    cmake \
        -D CMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
        -D CMAKE_BUILD_TYPE=Release \
        -D SOLVER=${SOLVER} \
        -D BIND_JULIA=TRUE \
        -D Julia_PREFIX=${prefix} \
        -D JlCxx_DIR=${prefix}/lib/cmake/JlCxx \
        -D Boost_DIR=${prefix}/bin/cmake/Boost-1.87.0 \
        -D CMAKE_FIND_ROOT_PATH=${prefix} \
        -D CMAKE_INSTALL_PREFIX=${prefix} \
        ..
    cmake --build . --config Release --target install -- -j${nproc}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
include("../../L/libjulia/common.jl")
filter!(>=(v"1.10"), julia_versions)
platforms = vcat(libjulia_platforms.(julia_versions)...)
platforms = filter(p -> nbits(p) == 64, platforms)
platforms = expand_cxxstring_abis(platforms)

products = [ LibraryProduct("libnumav_julia", :libnumav_julia) ]

mkl_platforms = filter(p ->
    (arch(p) == "x86_64" && Sys.islinux(p) && libc(p) == "glibc") ||
    (arch(p) == "x86_64" && Sys.iswindows(p)),
    platforms
)

dependencies = [
    Dependency("libcxxwrap_julia_jll", compat="0.14.10"),
    Dependency("HDF5_jll", compat="2.1"),
    Dependency("spdlog_jll", compat="1.15.0"),
    BuildDependency(PackageSpec(name="libjulia_jll", version="1.11.0")),
    BuildDependency(PackageSpec(name="Eigen_jll", version="5.0.1")),
    BuildDependency(PackageSpec(name="boost_jll", version="1.87.0")),

    # oneMKL for x86_64-linux-gnu and x86_64-w64
    Dependency("MKL_jll", compat="=2025.2.0"; platforms=mkl_platforms),
    BuildDependency(
        PackageSpec(name="MKL_Headers_jll", version="2025.2.0");
        platforms=mkl_platforms
    ),
]

build_tarballs(
    ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version=v"10",
    julia_compat=libjulia_julia_compat(julia_versions)
)
