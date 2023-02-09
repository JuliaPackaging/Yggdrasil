# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MadGraph"
version = v"3.4.2"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://launchpad.net/mg5amcnlo/3.0/3.4.x/+download/MG5_aMC_v$(version).tar.gz", "ca8631e10cc384f9d05a4d3311f6cb101eeaa57cb39ab7325ee5d1aec1fe218f")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
python3 -O -m compileall -qf "MG5_aMC_v3_4_2/" 2>&1 1>/dev/null
tmpfile=$(mktemp)
echo "exit" > $tmpfile
python3 MG5_aMC_v3_4_2/bin/mg5_aMC $tmpfile 1>/dev/null
rm $tmpfile
mkdir $prefix/madgraph
cp -a "MG5_aMC_v3_4_2/." "$prefix/madgraph/"
ln -s $prefix/madgraph/bin/mg5_aMC $prefix/bin/mg5_aMC
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
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl")
]


# The products that we will ensure are always built
products = Product[
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Perl_jll", uuid="83958c19-0796-5285-893e-a1267f8ec499"))
    Dependency(PackageSpec(name="Python_jll", uuid="93d3a430-8e7c-50da-8e8d-3dfcfb3baf05"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
