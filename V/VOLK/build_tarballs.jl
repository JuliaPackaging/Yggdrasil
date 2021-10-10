# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "VOLK"
version = v"2.5.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/gnuradio/volk/releases/download/v$(version)/volk-$(version).tar.gz", "d9183b9f86a32cdbb8698cbbeb15de574962c05200ccf445c1058629073521f8"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/volk-*

if [[ ${target} == *-freebsd* ]]; then
    #this is not in 0.6.0 release, but has been added on master, can probably remove after next release
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/add-freebsd-macros.patch"
elif [[ ${target} == x86_64-w64-mingw* ]]; then
    #disable avx512 on x86_64-mingw to avoid "Error: invalid register for .seh_savexmm". This is not needed on i686-mingw for some reason?
    #copied from https://github.com/xianyi/OpenBLAS/issues/1801 
    export CFLAGS="${CFLAGS} -fno-asynchronous-unwind-tables"
fi

mkdir build
cd build/

pip install mako

cmake .. \
-DCMAKE_INSTALL_PREFIX=${prefix} \
-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
-DCMAKE_BUILD_TYPE=Release \
-DCROSSCOMPILE_MULTILIB=true \
-DENABLE_TESTING=OFF \
-DENABLE_MODTOOL=OFF


make -j${nproc}
make install

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())


#volk by default builds with -D_GLIBCXX_USE_CXX11_ABI=1 see: https://github.com/gnuradio/volk/blob/2ff7b768a4b2174379a1f2e9214051677082f14b/CMakeLists.txt#L53
filter!(x -> cxxstring_abi(x) != "cxx03", platforms)


# The products that we will ensure are always built
products = [
    LibraryProduct("libvolk", :libvolk),
    ExecutableProduct("volk-config-info", :volk_config_info),
    ExecutableProduct("volk_profile", :volk_profile),
    ExecutableProduct("list_cpu_features", :list_cpu_features)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("boost_jll"; compat="=1.76.0")
    HostBuildDependency(PackageSpec(name="ORC_jll", uuid="fb41591b-4dee-5dae-bf56-d83afd04fbc0"))
]

# Build the tarballs, and possibly a `build.jl` as well.
#need at least gcc5 for Wincompatible-pointer-type flag for cpu_features, needs at least gcc6 to avoid std::inf errors on musl see: https://github.com/gnuradio/volk/issues/375
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"6")
