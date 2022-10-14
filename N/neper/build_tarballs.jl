using BinaryBuilder, Pkg

name = "neper"
version = v"4.5.0"

sources = [
    ArchiveSource("https://github.com/neperfepx/neper/archive/refs/tags/v$(version).tar.gz", "db80dd89e02207e9b056b05fb9fbe493199ce7c3736b2039104c595b4dcd02a9")
]

script = raw"""
cd $WORKSPACE/srcdir/neper-*
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ../src
make -j${nproc}
make install
"""

function exclude(p)
    if get(p.tags, "libc", nothing) == "musl"
        # src/contrib/ut/src/ut_print/ut_print.c:1685:38: error: parameter 1 (‘beg_time’) has incomplete type
        #  1685 | ut_print_elapsedtime (struct timeval beg_time, struct timeval end_time)
        #       |                       ~~~~~~~~~~~~~~~^~~~~~~~
        return true
    elseif get(p.tags, "os", nothing) == "windows" && get(p.tags, "arch", nothing) == "i686"
        # CMake Error at CMakeLists.txt:262 (install):
        #  install FILES given no DESTINATION!
        return true
    elseif get(p.tags, "os", nothing) == "windows" && get(p.tags, "arch", nothing) == "x86_64"
        # CMake Error at CMakeLists.txt:262 (install):
        #  install FILES given no DESTINATION!
        return true
    elseif get(p.tags, "os", nothing) == "freebsd"
        # CMake Error at CMakeLists.txt:262 (install):
        #  install FILES given no DESTINATION!
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
    Dependency(PackageSpec(name="GSL_jll", uuid="1b77fbbe-d8ee-58f0-85f9-836ddc23a7a4")),
    Dependency(PackageSpec(name="NLopt_jll", uuid="079eb43e-fd8e-5478-9966-2cf3e3edb778")),
    # /opt/aarch64-linux-gnu/bin/../lib/gcc/aarch64-linux-gnu/12.1.0/../../../../aarch64-linux-gnu/bin/ld: /opt/aarch64-linux-gnu/aarch64-linux-gnu/sys-root/usr/local/lib/libscotch.so: undefined reference to `gzwrite'
    # Dependency(PackageSpec(name="SCOTCH_jll", uuid="a8d0f55d-b80e-548d-aff6-1a04c175f0f9")),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"12.1.0")
