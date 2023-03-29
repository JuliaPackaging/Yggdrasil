# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "GiNaC"
version = v"1.8.6"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://www.ginac.de/ginac-$(version).tar.bz2", "00b320b1116cae5b7b43364dbffb7912471d171f484d82764605d715858d975b"),
    GitSource("git://www.ginac.de/cln.git", "d4621667b173aa197a2b23d63f561648c0ee2968")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
mkdir $WORKSPACE/srcdir/cln-build/
cd $WORKSPACE/srcdir/cln-build/
cmake -GNinja     -DCMAKE_CXX_STANDARD=11     -DCMAKE_INSTALL_PREFIX=${prefix}     -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}     -DCMAKE_BUILD_TYPE=Release     $WORKSPACE/srcdir/cln
cmake --build .
cmake --build . -t install
mkdir $WORKSPACE/srcdir/ginac-build
cd $WORKSPACE/srcdir/ginac-build
cmake -DCMAKE_CXX_STANDARD=11     -DCMAKE_INSTALL_PREFIX=${prefix}     -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}     -DCMAKE_BUILD_TYPE=Release \$WORKSPACE/srcdir/ginac-*.*.*
cmake -DCMAKE_CXX_STANDARD=11     -DCMAKE_INSTALL_PREFIX=${prefix}     -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}     -DCMAKE_BUILD_TYPE=Release $WORKSPACE/srcdir/ginac-*.*.*
cat CMakeFiles/CMakeOutput.log 
cmake -DCMAKE_CXX_STANDARD=11     -DCMAKE_INSTALL_PREFIX=${prefix}     -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}     -DCMAKE_BUILD_TYPE=Release $WORKSPACE/srcdir/ginac-*.*.*
which bison
/opt/x86_64-linux-gnu/x86_64-linux-gnu/sys-root/usr/local/bin/bison

/opt/x86_64-linux-gnu/x86_64-linux-gnu/sys-root/usr/local/bin/bison --version
cd ..
ls
cd ginac-1.8.6/
./configure --prefix=$prefix --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("powerpc64le", "linux"; libc = "glibc"),
    Platform("i686", "linux"; libc = "musl"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("aarch64", "linux"; libc = "musl"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "musl"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl"),
    Platform("x86_64", "macos"; ),
    Platform("aarch64", "macos"; ),
    Platform("x86_64", "freebsd"; )
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libginac", :libginac),
    ExecutableProduct("viewgar", :viewgar),
    ExecutableProduct("ginsh", :ginsh)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="GMP_jll", uuid="781609d7-10c4-51f6-84f2-b8444358ff6d"))
    Dependency(PackageSpec(name="Python_jll", uuid="93d3a430-8e7c-50da-8e8d-3dfcfb3baf05"))
    Dependency(PackageSpec(name="Bison_jll", uuid="0f48145f-aea8-549d-8864-7f251ac1e6d0"))
    Dependency(PackageSpec(name="flex_jll", uuid="48a596b8-cc7a-5e48-b182-65f75e8595d0"))
    Dependency(PackageSpec(name="Readline_jll", uuid="05236dd9-4125-5232-aa7c-9ec0c9b2c25a"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"5.2.0")
