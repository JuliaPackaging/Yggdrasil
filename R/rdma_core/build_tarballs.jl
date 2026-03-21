# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "rdma_core"
version = v"58.0.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/linux-rdma/rdma-core/releases/download/v$(version.major).$(version.minor)/rdma-core-$(version.major).$(version.minor).tar.gz", "88d67897b793f42d2004eec2629ab8464e425e058f22afabd29faac0a2f54ce4"),
	DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd rdma-core-*
# Apply patches
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
	atomic_patch -p1 ${f}
done
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DNO_MAN_PAGES=ON
make -j
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("powerpc64le", "linux"; libc="glibc"),
    Platform("i686", "linux"; libc="musl"),
    Platform("x86_64", "linux"; libc="musl"),
    Platform("aarch64", "linux"; libc="musl")
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libibverbs", :libibverbs),
    LibraryProduct("librdmacm", :lbrdmacm)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="libnl_jll", uuid="7c700954-19d3-5208-81e2-8fa5fe7c0bd8"))
]

init_block = raw"""
if !haskey(ENV, "JULIA_IBV_CONFIG_DIR")
        ENV["JULIA_IBV_CONFIG_DIR"] = joinpath(artifact_dir, "etc", "libibverbs.d")
    end
"""

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"5.2.0", init_block)
