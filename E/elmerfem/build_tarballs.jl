# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder
using Pkg: PackageSpec

name = "elmerfem"

# elmerfem isn't releasing very often, with its last official release being 9.0 in May 2023 
# as of writing this build script.
#
# In order to provide more up-to-date builds, we will internally use the MAJOR and MINOR versions
# matching the latest official elmerfem release, but then use the PATCH version to be an integer that
# encodes the date at which `commit` was made, as YYYYMMDD.
commit = "4d67add946cb9ad886c04d0057047a0daf2e657c"
version = v"9.0.20231229"

sources = [GitSource("https://github.com/ElmerCSC/elmerfem.git", commit)]

# Bash recipe for building across all platforms
# NOTE: 
#   - libblastrampoline needs to be found slightly different on mingw platforms.
#       This snippet has been inspired by the approach in OPACK/build_tarballs.jl
#   - setting CMAKE_TOOLCHAIN_FILE is important for us to pick up the correct
#       version of gfortran within cmake.
#   - setting HOMEBREW_PREFIX is a workaround for building on MacOS. The CMakeFile insists that
#       either macports or homebrew is present, but this is only depended on for finding opencascade.
#       This in turn is only used by ElmerGUI, which we aren't building.
#   - -Wno-dev suppresses warnings about the CMakeLists wanting CMake 2, whereas we are using CMake 3.
#       So far nothing is actually broken, so won't try to do anything about it here.
#
script = raw"""
mkdir build && cd build

if [[ "${target}" == *mingw* ]]; then
  LBT="-L${libdir} -lblastrampoline-5"
else
  LBT="-L${libdir} -lblastrampoline"
fi

cmake ../elmerfem \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DWITH_CONTRIB=ON \
    -DWITH_LUA=ON \
    -DWITH_OpenMP=ON \
    -DWITH_MPI=OFF \
    -DBLAS_LIBRARIES="${LBT}" \
    -DLAPACK_LIBRARIES="${LBT}" \
    -DHOMEBREW_PREFIX="unused" \
    -Wno-dev
make -j${nproc}
make install

install_license ../elmerfem/LICENSE.md
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.
# NOTE: Elmer only supports gfortran>=7, which implies libgfortran>=4.
#   However, in practice I saw a compiler error on at least one libgfortran 4 platform, so
#   going to leave that disabled until someone requests that build...
# XXX: builds failing on MacOS right now -- CMake cannot find OpenMP.
#   We are installing LLVMOpenMP_jll on BSD-like systems (which includes MacOS), but presumably
#   we need to pass further information to .
# XXX: builds failing on Linux armv6l & armv7l -- compilation error. Skip for now.
# XXX: builds failing on Windows at the final hurdle:
#
#       [17:03:16] CMake Error at cmake_install.cmake:41 (file):
#       [17:03:16]   file INSTALL cannot find
#       [17:03:16]   "/workspace/srcdir/elmerfem/-L/workspace/destdir/bin -lblastrampoline-5":
#       [17:03:16]   No such file or directory.
#
#   The contents of cmake_install.cmake lines 40-42 are:
#
#       if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xUnspecifiedx" OR NOT CMAKE_INSTALL_COMPONENT)
#           file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/bin" TYPE FILE FILES "/workspace/srcdir/elmerfem/-L/workspace/destdir/bin -lblastrampoline-5")
#       endif()
#   
#   The linux cmake_install.cmake doesn't include this line at all, so perhaps we can just remove it
#   before running `make`...?
# XXX: build fails on FreeBSD with compilation error... suggests we need to use an older C++ standard:
#       [17:35:11] /workspace/srcdir/elmerfem/meshgen2d/src/BGTriangleMesh.cpp:33:7: error: no member named 'random_shuffle' in namespace 'std'
#       [17:35:11]         std::random_shuffle(indirect, indirect + len);
#       [17:35:11]         ~~~~~^
#       [17:35:11] 1 error generated.
platforms = [
    p for p in expand_gfortran_versions(supported_platforms()) if (
        libgfortran_version(p) >= v"5" &&
        !Sys.isapple(p) &&
        !(arch(p) in ("armv6l", "armv7l")) &&
        !Sys.iswindows(p) &&
        !Sys.isfreebsd(p)
    )
]

# The products to which we provide easy access in the jll wrapper.
products = [
    ExecutableProduct("ElmerGrid", :elmer_grid),
    ExecutableProduct("ElmerSolver", :elmer_solver),
    ExecutableProduct("Mesh2D", :mesh2d),
    ExecutableProduct("Radiators", :radiators),
    ExecutableProduct("ViewFactors", :view_factors),
    ExecutableProduct("elmerf90", :elmerf90),
    ExecutableProduct("elmerld", :elmerld),
    ExecutableProduct("matc", :matc),
]

# Dependencies that must be installed before this package can be built.
# We require CompilerSupportLibraries for the user to have e.g. libgfortran after
# installing this package.
# In addition, we use LLVM OpenMP on BSD systems (OpenBSD & MacOS).
dependencies = [
    Dependency(
        PackageSpec(;
            name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"
        ),
    ),
    Dependency(
        PackageSpec(; name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e");
        platforms=filter(Sys.isbsd, platforms),
    ),
    Dependency(
        PackageSpec(;
            name="libblastrampoline_jll", uuid="8e850b90-86db-534c-a0d3-1478176c7d93"
        );
        compat="5.4",
    ),
]

# ElmerSolver and other binaries need to find the items under X/share/elmerfem,
# where X is the install root.
# The installation root is embedded into the binary during compilation, however this isn't
# the correct path at runtime. Hence we instead ensure that ELMER_HOME is set when we try
# to run the binaries.
init_block = raw"""ENV["ELMER_HOME"] = artifact_dir"""

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(
    ARGS,
    name,
    version,
    sources,
    script,
    platforms,
    products,
    dependencies;
    julia_compat="1.9",
    preferred_gcc_version=v"10",
    init_block,
)
