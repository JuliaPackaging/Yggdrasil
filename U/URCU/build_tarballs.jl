# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "URCU"
version = v"0.13.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://git.lttng.org/userspace-rcu.git", "c19d74445b6ed2e6840038afc2f974e3e098334b")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd userspace-rcu/
./bootstrap 
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("powerpc64le", "linux"; libc = "glibc"),
    Platform("i686", "linux"; libc = "musl"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl"),
    Platform("x86_64", "macos"; ),
    Platform("x86_64", "freebsd"; )
]


# The products that we will ensure are always built
products = [
    LibraryProduct("liburcu-memb", :urcu_memb),
    LibraryProduct("liburcu-mb", :urcu_mb),
    LibraryProduct("liburcu-qsbr", :urcu_qsbr),
    LibraryProduct("liburcu-signal", :urcu_signal),
    LibraryProduct("liburcu-cds", :urcu_cds),
    LibraryProduct("liburcu", :urcu),
    LibraryProduct("liburcu-common", :urcu_common),
    LibraryProduct("liburcu-bp", :urcu_bp)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
