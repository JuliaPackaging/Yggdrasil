# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "sshpass"
version = v"1.10.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://downloads.sourceforge.net/project/sshpass/sshpass/$(version.major).$(version.minor)/sshpass-$(version.major).$(version.minor).tar.gz",
                  "ad1106c203cbb56185ca3bad8c6ccafca3b4064696194da879f81c8d7bdfeeda"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd sshpass-*

# The default configure.ac includes a malloc check that causes failures on
# ARM/OSX/musl: https://github.com/maxmind/libmaxminddb/pull/152
# Submitted upstream: https://sourceforge.net/p/sshpass/patches/16/
atomic_patch -p1 ../patches/configure-ac.patch

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# sshpass support on Windows requires Cygwin so we don't support it
platforms = filter(p -> !Sys.iswindows(p), supported_platforms())

# The products that we will ensure are always built
products = [
    ExecutableProduct("sshpass", :sshpass)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
