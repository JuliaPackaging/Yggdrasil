# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, BinaryBuilderBase, Pkg

# The version of this JLL is decoupled from the upstream version.
# Whenever we package a new upstream release, we initially map its
# version X.Y.Z to X00.Y00.Z00 (i.e., multiply each component by 100).
# So for example version 2.6.3 would become 200.600.300.
#
# Moreover, all our packages using this JLL use `~` in their compat ranges.
#
# Together, this allows us to increment the patch level of the JLL for minor tweaks.
# If a rebuild of the JLL is needed which keeps the upstream version identical
# but breaks ABI compatibility for any reason, we can increment the minor version
# e.g. go from 200.600.300 to 200.601.300.
# To package prerelease versions, we can also adjust the minor version; e.g. we may
# map a prerelease of 2.7.0 to 200.690.000.
#
# There is currently no plan to change the major version, except when upstream itself
# changes its major version. It simply seemed sensible to apply the same transformation
# to all components.

name = "GAP"
version = v"400.1190.1"
upstream_version = v"4.12.0-dev"

# Collection of sources required to complete build
sources = [
    # snapshot of GAP master branch leading up to GAP 4.12:
    GitSource("https://github.com/gap-system/gap.git", "a9b5db7c1361d336363e2f6bdf6ee83fc248c10b"),
#    ArchiveSource("https://github.com/gap-system/gap/releases/download/v$(upstream_version)/gap-$(upstream_version)-core.tar.gz",
#                  "2b6e2ed90fcae4deb347284136427105361123ac96d30d699db7e97d094685ce"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/gap*

for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done

# run autogen.sh if compiling from it source and/or if configure was patched
./autogen.sh

# provide some generated code
cp ${WORKSPACE}/srcdir/generated/c_*.c src/

# compile GAP
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    --with-gmp=${prefix} \
    --with-readline=${prefix} \
    --with-zlib=${prefix} \
    --with-gc=julia \
    --with-julia
make -j${nproc}

# install GAP binaries
make install-bin install-headers install-libgap

# also install config.h
cp build/config.h ${prefix}/include/gap

# the license
install_license LICENSE

# get rid of *.la files, they just cause trouble
rm ${prefix}/lib/*.la

# get rid of the wrapper shell script, which is useless for us
mv ${prefix}/bin/gap.real ${prefix}/bin/gap

# install gac and sysinfo.gap
mkdir -p ${prefix}/share/gap/
cp gac sysinfo.gap ${prefix}/share/gap/

# We deliberately do NOT install the GAP library, documentation, etc. because
# they are identical across all platforms; instead, we use another platform
# independent artifact to ship them to the user.
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# we only care about 64bit builds
filter!(p -> nbits(p) == 64, platforms)

# Windows is not supported
filter!(!Sys.iswindows, platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("gap", :gap),
    LibraryProduct("libgap", :libgap),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GMP_jll", v"6.1.2"),
    Dependency("Readline_jll", v"8.0.4"),
    Dependency("Zlib_jll"),

    # GAP tries hard to produce a binary that works in all Julia versions,
    # regardless of which version of Julia it was compiled again; so the
    # version restriction below could be dropped or changed if necessary
    BuildDependency(PackageSpec(name="libjulia_jll", version=v"1.5.3")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"7",
               init_block = """

    sym = dlsym(libgap_handle, :GAP_InitJuliaMemoryInterface)
    ccall(sym, Nothing, (Any, Ptr{Nothing}), @__MODULE__, C_NULL)
""")
