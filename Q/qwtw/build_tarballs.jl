# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "qwtw"
version = v"2.0.4"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/ig-or/qwtw.git", "b8119478c38050cd55e01711c8b5867a1932c990")
]

# Bash recipe for building across all platforms
script = raw"""
apk add g++
cd $WORKSPACE/srcdir
cd qwtw
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ../.
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line

platforms = [
    Platform("x86_64", "windows"),
    Platform("x86_64", "linux"; libc="glibc"),

]



# The products that we will ensure are always built
products = [
    LibraryProduct("libqwtw", :qwtw),
    ExecutableProduct("qwproc", :qwproc),
    ExecutableProduct("qttest", :qttest)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Libglvnd_jll", uuid="7e76a0d4-f3c7-5321-8279-8d96eeed0f29"))
    Dependency(PackageSpec(name="boost_jll", uuid="28df3c45-c428-5900-9ff8-a3135698ca75"))
    Dependency(PackageSpec(name="Qt_jll", uuid="ede63266-ebff-546c-83e0-1c6fb6d0efc8"))
    Dependency(PackageSpec(name="qwt_jll", uuid="ed0789fa-10db-50b3-94da-03266d70be0f"))
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
    Dependency(PackageSpec(name="FreeType2_jll", uuid="d7e528f0-a631-5988-bf34-fe36492bcfd7"))
]


# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"8.1.0")
