# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

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
# FIXME: do we need to nuke fem/tests/cmakelists? We were doing this internally.
# NOTE: 
#   - setting CMAKE_TOOLCHAIN_FILE is important for us to pick up the correct
#       version of gfortran within cmake.
#   - setting HOMEBREW_PREFIX is a workaround for building on MacOS. The CMakeFile insists that
#       either macports or homebrew is present, but this is only depended on for finding opencascade.
#       This in turn is only used by ElmerGUI, which we aren't building.
#   - -Wno-dev suppresses warnings about the CMakeLists wanting CMake 2, whereas we are using CMake 3.
#       So far nothing is actually broken, so won't try to do anything about it here.
script = raw"""
echo "" > elmerfem/fem/tests/CMakeLists.txt
mkdir build && cd build
cmake ../elmerfem \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DWITH_CONTRIB=ON \
    -DWITH_LUA=ON \
    -DWITH_OpenMP=ON \
    -DWITH_MPI=OFF \
    -DBLAS_LIBRARIES="-L${libdir} -lblastrampoline" \
    -DLAPACK_LIBRARIES="-L${libdir} -lblastrampoline" \
    -DHOMEBREW_PREFIX="unused" \
    -Wno-dev
make -j${nproc}
make install

install_license ../elmerfem/LICENSE.md
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.
# NOTE: Elmer only supports gfortran>=7, which implies libgfortran>=4.
# XXX: builds failing on MacOS right now, so skipping these builds
# XXX: builds failing on Linux armv6l & armv7l -- skip for now
platforms = [
    p for p in expand_gfortran_versions(supported_platforms()) if
    # (libgfortran_version(p) >= v"4" && !Sys.isapple(p))
    (libgfortran_version(p) >= v"5" && !Sys.isapple(p) && !(arch(p) in ("armv6l", "armv7l")))
]

for x in platforms
    println(x)
end

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
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("LLVMOpenMP_jll"; platforms=filter(Sys.isbsd, platforms)),
    Dependency("libblastrampoline_jll"),
]

# ElmerSolver and other binaries need to find the items under X/share/elmerfem,
# where X is the install root.
# The installation root is embedded into the binary during compilation
# TODO: is it possible to embed this within the executables?
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
    julia_compat="1.6",
    preferred_gcc_version=v"10",
    init_block,
)
