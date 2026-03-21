# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "WiringPi"
version = v"3.16"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/WiringPi/WiringPi.git", "b2af17eea92238fa99dae5bf174b3cdf81b78656"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done

cd WiringPi/wiringPi


make -j${nproc}
# Override the installation location, and don't let it run ldconfig (it doesn't work for us)
make DESTDIR=${prefix} PREFIX="" LDCONFIG="" V=1 install


install_license COPYING.LESSER

"""


# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("aarch64", "linux"; libc = "glibc")
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libwiringPi", :wiringPi)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"8.1.0")
