# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg


name = "WiringPi"
version = v"3.14"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/WiringPi/WiringPi.git", "4639b7ac45ff87a9c2271a3d44f7fccb618c88ff"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done

cd WiringPi/

cd wiringPi

cp COPYING.LESSER LICENSE

make
make V=1 install||true

install -Dvm 755 "libwiringPi.so.3.14" "${libdir}/libwiringPi.$dlext"

mkdir -p ${prefix}/share/licenses/WiringPi/

cp LICENSE ${prefix}/share/licenses/WiringPi/

exit
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
