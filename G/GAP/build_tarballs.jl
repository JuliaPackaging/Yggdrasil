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

# See https://github.com/JuliaLang/Pkg.jl/issues/2942
# Once this Pkg issue is resolved, this must be removed
uuid = Base.UUID("a83860b7-747b-57cf-bf1f-3e79990d037f")
delete!(Pkg.Types.get_last_stdlibs(v"1.6.3"), uuid)

name = "GAP"
upstream_version = v"4.14.0"
version = v"400.1400.002"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/gap-system/gap/releases/download/v$(upstream_version)/gap-$(upstream_version)-core.tar.gz",
                  "81ecfc6f6df044739ba34ec306cc25e847967d94f1c645b093cc21749ccc1e49"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/gap*

for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done

# HACK: determine Julia version
cat > version.c <<EOF
#include <stdio.h>
#include "julia/julia_version.h"
int main(int argc, char**argv)
{
    printf("%d.%d", JULIA_VERSION_MAJOR, JULIA_VERSION_MINOR);
    return 0;
}
EOF
${CC_BUILD} -Wall version.c -o julia_version
julia_version=$(./julia_version)

# must run autogen.sh if compiling from git snapshot and/or if configure was patched;
# it doesn't hurt otherwise, too, so just always do it
./autogen.sh

# configure GAP
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    JULIA_VERSION="$julia_version" \
    JULIA_CFLAGS="-I/workspace/destdir/include/julia -fPIC" \
    JULIA_LDFLAGS="-L/workspace/destdir/lib -L/workspace/destdir/lib/julia" \
    JULIA_LIBS="-Wl,-rpath,/workspace/destdir/lib -Wl,-rpath,/workspace/destdir/lib/julia -ljulia" \
    CPPFLAGS="$CPPFLAGS -DUSE_GAP_INSIDE_JULIA=1" \
    --with-gmp=${prefix} \
    --with-readline=${prefix} \
    --with-zlib=${prefix} \
    --with-gc=julia \
    --with-julia

# WORKAROUND: avoid error: /usr/local/include: No such file or directory
export CPPFLAGS="$CPPFLAGS -Wno-missing-include-dirs"

# When building a git snapshot, configure & compile a native version of GAP to
# generate ffdata.{c,h}, c_oper1.c and c_type1.c -- in a GAP release tarball
# this is not necessary.
if [ ! -f src/c_oper1.c ] ; then
    mkdir native-build
    cd native-build
    ../configure --build=${MACHTYPE} --host=${MACHTYPE} \
        --enable-Werror \
        --with-gmp=${host_prefix} \
        --without-readline \
        --with-zlib=${host_prefix} \
        CC=${CC_BUILD} CXX=${CXX_BUILD}
    make -j${nproc}
    cp build/c_*.c build/ffdata.* ../src/
    cd ..

    # remove the native build, it has done its job
    rm -rf native-build
fi

# compile GAP
make -j${nproc}

# install GAP binaries, headers, shared library, sysinfo
make install-bin install-headers install-libgap install-sysinfo

# the license
install_license LICENSE

# We deliberately do NOT install the GAP library, documentation, etc. because
# they are identical across all platforms; instead, we use another platform
# independent artifact to ship them to the user.
"""

include("../../L/libjulia/common.jl")
platforms = vcat(libjulia_platforms.(julia_versions)...)

# we only care about 64bit builds
filter!(p -> nbits(p) == 64, platforms)

# Windows is not supported
filter!(!Sys.iswindows, platforms)

# Exclude aarch64 FreeBSD for the time being
filter!(p -> !(Sys.isfreebsd(p) && arch(p) == "aarch64"), platforms)

# Can't build for riscv64 as long as there is no libjulia_jll for it
filter!(p -> arch(p) != "riscv64", platforms)

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
    Dependency("Readline_jll"; compat="8.2.1"),
    Dependency("Zlib_jll"),
    BuildDependency(PackageSpec(;name="libjulia_jll", version=v"1.10.14")),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"7", julia_compat="1.6", init_block="""

    try
        cglobal(:jl_reinit_foreign_type)
    catch
        # no jl_reinit_foreign_type -> fall back to old behavior
        sym = dlsym(libgap_handle, :GAP_InitJuliaMemoryInterface)
        ccall(sym, Nothing, (Any, Ptr{Nothing}), @__MODULE__, C_NULL)
    end
""")

# rebuild trigger: 1
