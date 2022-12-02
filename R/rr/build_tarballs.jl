# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "rr"
version = v"5.5"

# Collection of sources required to build rr
sources = [
    GitSource("https://github.com/Keno/rr.git",
              "fa6a8da4ecdb20909af13ac8380b7a1d804c71e2")
]

# Bash recipe for building across all platforms
script = raw"""
pip3 install pexpect
cd ${WORKSPACE}/srcdir/rr/

mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DBUILD_TESTS=OFF -DWILL_RUN_TESTS=OFF -Dstaticlibs=ON ..
make -j${nproc}
make install
"""

augment_platform_block = """
    using Base.BinaryPlatforms

    function augment_platform!(platform::Platform)
        if Sys.islinux()
            real_arch = chomp(read(`uname -m`, String))
            remaining_tags = copy(tags(platform))
            delete!(remaining_tags, "arch")
            delete!(remaining_tags, "os")
            Platform(String(real_arch), os(platform), remaining_tags)
        end
    end"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# rr only supports Linux
platforms = [
    Platform("x86_64", "linux", libc="glibc"),
    Platform("aarch64", "linux", libc="glibc")
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("rr", :rr),
]

# Dependencies that must be installed before this package can be built
# This is really a build dependency
dependencies = [
    # For the capnp generator executable
    HostBuildDependency("capnproto_jll"),
    # For the capnp static support library
    BuildDependency("capnproto_jll"),
    Dependency("Zlib_jll"),
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.6", preferred_gcc_version=v"10")
