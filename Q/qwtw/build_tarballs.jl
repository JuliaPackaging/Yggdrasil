# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "qwtw"
version = v"2.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/ig-or/qwtw.git", "b9451c91004de517e97429cd762caaad206f6014")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd qwtw
mkdir build
cd build
export LD_LIBRARY_PATH=/workspace/srcdir/qwtw/build:$LD_LIBRARY_PATH
ln -s /lib64/libc.so.6 libc.so
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ../.
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:x86_64, libc=:glibc)
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libqwtw", :qwtw),
    ExecutableProduct("qwproc", :qwproc)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Libglvnd_jll", uuid="7e76a0d4-f3c7-5321-8279-8d96eeed0f29"))
    Dependency(PackageSpec(name="boost_jll", uuid="28df3c45-c428-5900-9ff8-a3135698ca75"))
    Dependency(PackageSpec(name="Qt_jll", uuid="ede63266-ebff-546c-83e0-1c6fb6d0efc8"))
    Dependency(PackageSpec(name="qwt_jll", uuid="ed0789fa-10db-50b3-94da-03266d70be0f"))
]

Pkg.add("Qt_jll")
using Qt_jll
ENV["QT_PLUGIN_PATH"]=Qt_jll.artifact_dir*"/plugins"
ENV["LD_LIBRARY_PATH"] = string(Qt_jll.LIBPATH) * ":" * ENV["LD_LIBRARY_PATH"]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"5.2.0")
