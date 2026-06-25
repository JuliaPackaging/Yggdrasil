# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms

name = "WorldBuilder"
version = v"1.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/GeodynamicWorldBuilder/WorldBuilder.git",
              "9c69743d9ede119939d47e3060f1f2697268250b"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/WorldBuilder*

# GCC (unlike Clang) refuses to constant-fold floating-point arithmetic at
# compile time when `-frounding-math` is active (which WorldBuilder's own
# build flags always pass), since the result can depend on the runtime
# rounding mode. A handful of local `constexpr double` declarations compute
# their value from FP arithmetic and so fail to compile under GCC.
atomic_patch -p1 $WORKSPACE/srcdir/patches/constexpr_rounding_math.patch

# CMakeLists.txt unconditionally links gwb-dat/gwb-grid against WorldBuilder
# wrapped in -Wl,--whole-archive/-force_load, to force-load the whole static
# archive so plugin self-registration (static initializers) runs. That is
# only necessary when WorldBuilder is a static library; with
# BUILD_SHARED_LIBS=ON the apps already get all of libWorldBuilder via normal
# dynamic linking, and whole-archiving the shared library's MinGW import
# library on top of that duplicates libstdc++ template instantiations and
# fails to link.
atomic_patch -p1 $WORKSPACE/srcdir/patches/shared_lib_whole_archive.patch

# parameters.cc explicitly specializes Parameters::get<size_t>/get_vector<size_t>
# and Parameters::get<unsigned int>/get_vector<unsigned int> as distinct
# functions. On 32-bit platforms size_t and unsigned int are the same type,
# so each pair of specializations collides ("redefinition"). Neither size_t
# specialization is actually called anywhere in the codebase, so both are
# simply removed.
atomic_patch -p1 $WORKSPACE/srcdir/patches/remove_dead_get_size_t.patch

mkdir build && cd build

cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DBUILD_SHARED_LIBS=ON \
      -DWB_ENABLE_APPS=ON \
      -DWB_ENABLE_TESTS=OFF \
      -DWB_ENABLE_HELPER_TARGETS=OFF \
      -DWB_ENABLE_PYTHON=OFF \
      -DWB_MAKE_FORTRAN_WRAPPER=OFF \
      -DUSE_MPI=OFF \
      -DWB_USE_ZLIB=OFF \
      -GNinja \
      ..

ninja -j${nproc}

# Upstream's install rules put the WorldBuilder library target in
# ${prefix}/bin, and don't install the gwb-dat/gwb-grid executables at all
# (they're only left in the build tree's own bin/ dir). Install everything
# ourselves into the conventional locations.
install_license ../LICENSE

mkdir -p ${libdir}
find . -name "libWorldBuilder.${dlext}*" -exec install -Dvm 755 {} ${libdir}/ \;

mkdir -p ${bindir}
install -Dvm 755 bin/gwb-dat${exeext} ${bindir}/gwb-dat${exeext}
install -Dvm 755 bin/gwb-grid${exeext} ${bindir}/gwb-grid${exeext}

mkdir -p ${includedir}
cp -r ../include/world_builder ${includedir}/
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.
# i686-w64-mingw32 is excluded: GCC 9 hits an internal compiler error
# (segfault) compiling the template-heavy gwb-grid/main.cc on this platform,
# independent of optimization level. 32-bit Windows is a niche target for
# this package, so we simply don't build it rather than chase a compiler bug.
platforms = filter(p -> !(arch(p) == "i686" && Sys.iswindows(p)), supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libWorldBuilder", :libWorldBuilder)
    ExecutableProduct("gwb-dat", :gwb_dat)
    ExecutableProduct("gwb-grid", :gwb_grid)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# gwb-grid hits a libstdc++ defect in GCC <= ~6 (an explicit std::tuple
# constructor rejecting brace-init that later GCCs accept), so we can't use
# the oldest (cxx11-ABI) compiler shard here; GCC 9 is the oldest that builds
# all three products (libWorldBuilder, gwb-dat, gwb-grid) cleanly.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.9", preferred_gcc_version=v"9")
