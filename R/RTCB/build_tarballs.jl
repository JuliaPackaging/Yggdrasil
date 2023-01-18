# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "RTCB"
version = v"0.91.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://bitbucket.org/planetarysystemresearch/rtcb_public.git", "c32b8d558a2f0b6cf9759ccdd19f872c0df0f5e5"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done
cd ${WORKSPACE}/srcdir/rtcb_public/
mkdir -p obj mod ${bindir} 
make sphere
make plane
make planeHM
install_license LICENSE.txt 
mv rtcb* ${bindir}/
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("i686", "linux"; libc = "musl"),
    Platform("x86_64", "linux"; libc = "musl")
]
platforms = expand_gfortran_versions(platforms)


# The products that we will ensure are always built
products = [
    ExecutableProduct("rtcbPlaneHM", :rtcbPlaneHM),
    ExecutableProduct("rtcbSphere", :rtcbSphere),
    ExecutableProduct("rtcbPlane", :rtcbPlane)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
