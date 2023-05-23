# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "fastp"
version = v"0.23.3"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/OpenGene/fastp.git", "ca559a71feed94e74ea449e7567d0506de48dea4")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/fastp
make -j${nproc}
install -Dvm 755 "fastp${exeext}" "${bindir}/fastp${exeext}"
mkdir -p "${prefix}/share/licenses/fastp/"
cp ./LICENSE "${prefix}/share/licenses/fastp/"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("powerpc64le", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("aarch64", "linux"; libc = "musl"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "musl"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl"),
    Platform("x86_64", "macos"; ),
    Platform("x86_64", "freebsd"; )
]
platforms = expand_cxxstring_abis(platforms)


# The products that we will ensure are always built
products = [
    ExecutableProduct("fastp", :fastp)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="libdeflate_jll", uuid="46979653-d7f6-5232-b59e-dd310c4598de"))
    Dependency(PackageSpec(name="isa_l_jll", uuid="67581813-1eb2-5518-8b74-202629104514"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
