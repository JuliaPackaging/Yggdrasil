# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "HOHQMesh"
version = v"1.5.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/trixi-framework/HOHQMesh/releases/download/v$(version)/HOHQMesh-v$(version).tar.gz", "c90930b63178d6a519b6e9680bc4e4ffe1f909bcf6e97d65a956dfa4e2da3eca"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/HOHQMesh-*

# Build HOHQMesh
make -j${nproc} F90=$FC

# Copy executable to binary directory
mkdir -p ${bindir}
if [[ "${bb_full_target}" == *-w64-mingw32-libgfortran[34]* ]]; then
  # For some reason, on i686 with libgfortran3 or libgfortran4,
  # the executable is created without the `.exe` extension
  cp HOHQMesh ${bindir}/HOHQMesh${exeext}
else
  cp HOHQMesh${exeext} ${bindir}
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("powerpc64le", "linux"; libc = "glibc"),
    Platform("i686", "linux"; libc = "musl"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("x86_64", "macos"; ),
    Platform("x86_64", "freebsd"; ),
    Platform("i686", "windows"; ),
    Platform("x86_64", "windows"; ),
    Platform("aarch64", "macos"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "glibc"),
]

platforms = expand_gfortran_versions(platforms)


# The products that we will ensure are always built
products = [
    ExecutableProduct("HOHQMesh", :HOHQMesh)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"9.1.0", julia_compat="1.6")
