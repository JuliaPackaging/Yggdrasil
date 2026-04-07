# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SimpleBLE"
version = v"0.12.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/simpleble/simpleble.git", "d1b7110644f0f9cb850d6ab43f7d461ca9d4031e"),
    ArchiveSource("https://github.com/simpleble/simpleble/releases/download/v$(version)/libsimplecble_windows-x64.zip", "d6aa05c6a8f0ea710419dc82ea00c4ebbcd37a4d9644f70d79b94b6baf03c888"; unpack_target="windllx64"),
    ArchiveSource("https://github.com/simpleble/simpleble/releases/download/v$(version)/libsimplecble_windows-x86.zip", "1be89fda486cdcecfeda78b1c78ed1c3e502544f6d9fbbd4362b9844cfb435c2"; unpack_target="windllx32"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
install_license simpleble/LICENSE.md
# Currently building for windows does not work I suspect 
# because we need MinGW 14 to have access to the right winrt
# header files, so we download perbuilt binaries and use those
if [[ ${target} == *mingw* ]]; then
    if [[ ${target} == i686* ]]; then
        cd windllx32/shared/bin/
    else
        cd windllx64/shared/bin/
    fi
    ln simpleble.dll libsimpleble.dll
    ln simplecble.dll libsimplecble.dll
    chmod +x simpleble.dll simplecble.dll
    mkdir ${prefix}/bin || echo "Its fine"
    cp -a simpleble.dll libsimpleble.dll simplecble.dll libsimplecble.dll ${prefix}/bin
else
    cd simpleble/
    cmake -S simplecble -B build_simplecble -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=TRUE
    cmake --build build_simplecble --parallel ${nproc}
    cd build_simplecble/
    make install
    cd ${prefix}
    cd lib
    ln libsimpleble.so simpleble.so
    ln libsimplecble.so simplecble.so
fi
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
    Platform("riscv64", "linux"; libc = "glibc"),
    Platform("i686", "linux"; libc = "musl"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("aarch64", "linux"; libc = "musl"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "musl"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl"),
    Platform("x86_64", "freebsd"; ),
    Platform("aarch64", "freebsd"; ),
    Platform("i686", "windows"; ),
    Platform("x86_64", "windows"; )
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
# There are copies of each because windows and linux 
# name the products different things but all products
# must be present
products = [
    LibraryProduct("libsimplecble", :simplecble),
    LibraryProduct("libsimpleble", :simpleble),
    LibraryProduct("simplecble", :simplecble),
    LibraryProduct("simpleble", :simpleble)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Dbus_jll", uuid="ee1fde0b-3d02-5ea6-8484-8dfef6360eab"); platforms=filter(!Sys.iswindows, platforms))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"7.1.0")
