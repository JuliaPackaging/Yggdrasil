# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "PMIx"
version = v"4.2.7"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/openpmix/openpmix/releases/download/v$(version)/pmix-$(version).tar.bz2",
                  "145f05a6c621bfb3fc434776b615d7e6d53260cc9ba340a01f55b383e07c842e")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd pmix-*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    --enable-shared \
    --with-libevent=${prefix} \
    --with-hwloc=${prefix} \
    --with-zlib=${prefix} \
    --without-tests-examples \
    --disable-man-pages
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
# platforms = [
#     Platform("i686", "linux"; libc = "glibc"),
#     Platform("x86_64", "linux"; libc = "glibc"),
#     Platform("aarch64", "linux"; libc = "glibc"),
#     Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
#     Platform("powerpc64le", "linux"; libc = "glibc"),
#     Platform("i686", "linux"; libc = "musl"),
#     Platform("x86_64", "linux"; libc = "musl"),
#     Platform("aarch64", "linux"; libc = "musl"),
#     Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl"),
#     Platform("x86_64", "macos"; ),
#     Platform("aarch64", "macos"; )
# ]

# # TODO: Configure fails on Windows with:
# ```
# checking for library containing event_config_new... no
# checking for event_getcode4name in -levent... no
# checking will libevent support be built... no
# configure: WARNING: Either libevent or libev support is required, but neither
# configure: WARNING: was found. Please use the configure options to point us
# configure: WARNING: to where we can find one or the other library
# configure: error: Cannot continue
# ```

# The products that we will ensure are always built
products = [
    LibraryProduct("libpmix", :libpmix)
    ExecutableProduct("pmix_info", :pmix_info)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="libevent_jll", uuid="1080aeaf-3a6a-583e-a51c-c537b09f60ec")),
    Dependency(PackageSpec(name="Hwloc_jll", uuid="e33a78d0-f292-5ffc-b300-72abe9b543c8")),
    Dependency("Zlib_jll"),
]

init_block = raw"""
ENV["PMIX_PREFIX"] = artifact_dir
"""

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", init_block=init_block)
