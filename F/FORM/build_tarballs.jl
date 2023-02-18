# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "FORM"
version = v"4.3.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/vermaseren/form/releases/download/v$(version)/form-$(version).tar.gz", "b234e0d095f73ecb0904cdc3b0d8d8323a9fa7f46770a52fb22267c624aafbf6")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd form-4.3.0/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --enable-parform
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# platforms = [
#     Platform("x86_64", "linux"; libc = "glibc"),
#     Platform("aarch64", "linux"; libc = "glibc"),
#     Platform("powerpc64le", "linux"; libc = "glibc"),
#     Platform("x86_64", "linux"; libc = "musl"),
#     Platform("aarch64", "linux"; libc = "musl"),
#     Platform("x86_64", "macos"; ),
#     Platform("aarch64", "macos"; ),
#     Platform("x86_64", "freebsd"; )
# ]

platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    ExecutableProduct("parform", :parform),
    ExecutableProduct("tform", :tform),
    ExecutableProduct("form", :form)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="GMP_jll", uuid="781609d7-10c4-51f6-84f2-b8444358ff6d"))
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
    Dependency(PackageSpec(name="MPICH_jll", uuid="7cb0a576-ebde-5e09-9194-50597f1243b4"); platforms=filter(!Sys.iswindows, platforms))
    Dependency(PackageSpec(name="MicrosoftMPI_jll", uuid="9237b28f-5490-5468-be7b-bb81f5f5e6cf"); platforms=filter(Sys.iswindows, platforms))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
