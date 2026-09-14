using BinaryBuilder, Pkg

name = "neper"
version = v"5.0.0"

sources = [
    GitSource("https://github.com/neperfepx/neper", "7f58ac9d4e459b4c0b7403d8a903db41aac240f3"),
    DirectorySource("./bundled"),
]

script = raw"""
cd $WORKSPACE/srcdir/neper
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/no-openmp.patch
mkdir build && cd build
CXXFLAGS="-lz -std=c++11"
# A Full install runs the freshly built neper to precompute orispace mesh trees,
# which is impossible when cross-compiling.
CMAKE_FLAGS=(-DCMAKE_INSTALL_PREFIX=$prefix
             -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
             -DCMAKE_BUILD_TYPE=Release
             -DCMAKE_CXX_FLAGS="${CXXFLAGS}"
             -DFORCE_BUILTIN_NLOPT=OFF
             -DCMAKE_INSTALL_TYPE=NoPost)
if [[ "${target}" == *-apple-* ]]; then
    # Multithreading is unsupported on macOS and crashes during meshing,
    # see https://neper.info/doc/introduction.html#installing-neper.
    # ENABLE_OPENMP is the bundled muparser's option.
    CMAKE_FLAGS+=(-DHAVE_OPENMP=OFF -DENABLE_OPENMP=OFF)
fi
cmake "${CMAKE_FLAGS[@]}" ../src
make -j${nproc}
make install
# Developer dotfiles installed alongside the data files
rm -rv ${prefix}/share/neper/dev
"""

function exclude(p)
    if libc(p) == "musl" || Sys.isfreebsd(p)
        # src/contrib/ut/src/ut_print/ut_print.c:1685:38: error: parameter 1 (‘beg_time’) has incomplete type
        #  1685 | ut_print_elapsedtime (struct timeval beg_time, struct timeval end_time)
        #       |                       ~~~~~~~~~~~~~~~^~~~~~~~
        return true
    elseif Sys.iswindows(p)
        # The bundled ut library runs gmsh via fork/waitpid and locates the
        # executable through /proc/self/exe; upstream supports Windows only via WSL
        return true
    end
    return false
end
platforms = supported_platforms(; exclude=exclude)
platforms = expand_cxxstring_abis(platforms)

products = [
    ExecutableProduct("neper", :neper)
]

dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="GSL_jll", uuid="1b77fbbe-d8ee-58f0-85f9-836ddc23a7a4"); compat="~2.8.1"),
    Dependency(PackageSpec(name="NLopt_jll", uuid="079eb43e-fd8e-5478-9966-2cf3e3edb778"); compat="2.7.1 - 2.9"),
    Dependency(PackageSpec(name="SCOTCH_jll", uuid="a8d0f55d-b80e-548d-aff6-1a04c175f0f9"); compat="~7.0.11"),
    RuntimeDependency(PackageSpec(name="gmsh_jll", uuid="630162c2-fc9b-58b3-9910-8442a8a132e6")),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"7") # GCC 5: ambiguous isnan(double&) in neut_odf; GCC 6: ICE on aarch64 in neut_elt
