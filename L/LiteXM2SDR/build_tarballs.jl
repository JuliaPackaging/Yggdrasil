# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LiteXM2SDR"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/zsoerenm/litex_m2sdr.git", "21713734ee7ea4658b5cef320ec30393d690dcc1")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/litex_m2sdr/litex_m2sdr/software/user

# Build only the shared memory streaming executables
# These only work on Linux (require /dev/m2sdr* device access)
# Add -std=gnu99 for C99 compatibility with older GCC in BinaryBuilder
make INTERFACE=USE_LITEPCIE CFLAGS="-O2 -Wall -g -I../kernel -Ilibliteeth -Iliblitepcie -Ilibm2sdr -Iad9361 -MMD -fPIC -std=gnu99 -DUSE_LITEPCIE" LDFLAGS="-g -lrt" m2sdr_rx_stream_shm m2sdr_tx_stream_shm

# Install executables
install -Dvm 755 m2sdr_rx_stream_shm ${bindir}/m2sdr_rx_stream_shm${exeext}
install -Dvm 755 m2sdr_tx_stream_shm ${bindir}/m2sdr_tx_stream_shm${exeext}
"""

# These are the platforms we will build for by default, unless further
# temporary platforms are passed in on the command line.
# Only Linux is supported (requires PCIe device access)
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="musl"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="musl"),
]

# The products that we will ensure are always built
products = [
    ExecutableProduct("m2sdr_rx_stream_shm", :m2sdr_rx_stream_shm),
    ExecutableProduct("m2sdr_tx_stream_shm", :m2sdr_tx_stream_shm),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
