# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "PAPI"
version = v"6.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://bitbucket.org/icl/papi.git", "05a4d383eea251db990ab668ca4a13a74427a152")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd papi/src
if [[ "${target}" == *-musl* ]]; then
    CFLAGS="-D_GNU_SOURCE"
fi
export CFLAGS
bash ./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-ffsll --with-perf-events --with-walltimer=gettimeofday --with-tls=__thread --with-virtualtimer=times --with-nativecc=${CC_FOR_BUILD}
make -j ${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("powerpc64le", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("aarch64", "linux"; libc = "musl"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl")
]


# The products that we will ensure are always built
products = [
 #    LibraryProduct("libpfm", :libpfm),
    LibraryProduct("libpapi", :libpapi)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
