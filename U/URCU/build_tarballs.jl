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
cd $WORKSPACE/srcdir/userspace-rcu/
./bootstrap 
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(!Sys.iswindows, supported_platforms(; experimental=true))

# The products that we will ensure are always built
products = [
    LibraryProduct("liburcu-memb", :liburcu_memb),
    LibraryProduct("liburcu-mb", :liburcu_mb),
    LibraryProduct("liburcu-qsbr", :liburcu_qsbr),
    LibraryProduct("liburcu-signal", :liburcu_signal),
    LibraryProduct("liburcu-cds", :liburcu_cds),
    LibraryProduct("liburcu", :liburcu),
    LibraryProduct("liburcu-common", :liburcu_common),
    LibraryProduct("liburcu-bp", :liburcu_bp)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"5")
