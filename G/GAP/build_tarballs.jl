# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

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
upstream_version = v"4.12.0-dev"
version = v"400.1191.001"

julia_versions = [v"1.6.0", v"1.7.0", v"1.8.0"]

# Collection of sources required to complete build
sources = [
    # snapshot of GAP master branch leading up to GAP 4.12:
    GitSource("https://github.com/gap-system/gap.git", "401c797476b787e748a3890be4ce95ae4e5d52ae"),
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

# must run autogen.sh if compiling from git snapshot and/or if configure was patched;
# it doesn't hurt otherwise, too, so just always do it
./autogen.sh

# compile a native version of GAP to generate c_oper1.c and c_type1.c
mkdir native-build
cd native-build
rm ${host_libdir}/*.la  # delete *.la, they hardcode libdir='/workspace/destdir/lib'
../configure --build=${MACHTYPE} --host=${MACHTYPE} \
    --with-gmp=${host_prefix} \
    --without-readline \
    --with-zlib=${host_prefix} \
    CC=${CC_BUILD} CXX=${CXX_BUILD}
make -j${nproc}
cp build/c_*.c ../src/
cd ..

# remove the native build, it has done its job
rm -rf native-build

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

include("../../L/libjulia/common.jl")
platforms = vcat(libjulia_platforms.(julia_versions)...)
filter!(!Sys.iswindows, platforms)

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
    # for the "native" build that generates c_oper1.c and c_type1.c
    HostBuildDependency("GMP_jll"),
    HostBuildDependency("Zlib_jll"),

    Dependency("GMP_jll"),
    Dependency("Readline_jll"),
    Dependency("Zlib_jll"),
    BuildDependency("libjulia_jll"),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"7", julia_compat="1.6", init_block="""

    sym = dlsym(libgap_handle, :GAP_InitJuliaMemoryInterface)
    ccall(sym, Nothing, (Any, Ptr{Nothing}), @__MODULE__, C_NULL)
""")

