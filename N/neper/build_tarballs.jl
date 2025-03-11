using BinaryBuilder, Pkg

name = "neper"
version = v"4.8.2"

sources = [
    GitSource("https://github.com/neperfepx/neper", "bdf117bb71755abcac19f33deb498343f1c8fdda")
]

script = raw"""
cd $WORKSPACE/srcdir/neper
mkdir build && cd build
CXXFLAGS="-lz -std=c++11"
cmake -DCMAKE_INSTALL_PREFIX=$prefix \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_CXX_FLAGS="${CXXFLAGS}" \
      -DCMAKE_INSTALL_PREFIX_COMPLETION_FULL=$prefix/share/completion \
      ../src
make -j${nproc}
make install
"""

function exclude(p)
    if libc(p) == "musl" || Sys.isfreebsd(p)
        # src/contrib/ut/src/ut_print/ut_print.c:1685:38: error: parameter 1 (‘beg_time’) has incomplete type
        #  1685 | ut_print_elapsedtime (struct timeval beg_time, struct timeval end_time)
        #       |                       ~~~~~~~~~~~~~~~^~~~~~~~
        return true
    elseif Sys.iswindows(p)
        # In file included from /workspace/srcdir/neper-4.5.0/src/contrib/scotch/src/libscotch/library_error_exit.c:62:0:
        # /workspace/srcdir/neper-4.5.0/src/contrib/scotch/src/libscotch/common.h:130:71: fatal error: sys/wait.h: No such file or directory
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
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="GSL_jll", uuid="1b77fbbe-d8ee-58f0-85f9-836ddc23a7a4"); compat="~2.7.2"),
    Dependency(PackageSpec(name="NLopt_jll", uuid="079eb43e-fd8e-5478-9966-2cf3e3edb778"); compat="2.6.2 - 2.9"),
    Dependency(PackageSpec(name="SCOTCH_jll", uuid="a8d0f55d-b80e-548d-aff6-1a04c175f0f9"); compat="6.1.3"),
    RuntimeDependency(PackageSpec(name="gmsh_jll", uuid="630162c2-fc9b-58b3-9910-8442a8a132e6")),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"5")
