# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "capnproto"
version = v"0.8.0"

# Collection of sources required to build capnproto
sources = [
    ArchiveSource("https://capnproto.org/capnproto-c++-$(version).tar.gz",
                  "d1f40e47574c65700f0ec98bf66729378efabe3c72bc0cda795037498541c10d"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/capnproto-*/
(
    # Do native build to get a capnp that we can run
    mkdir build_native && cd build_native
    export CC=${CC_BUILD}
    export CXX=${CXX_BUILD}
    export LD=${LD_BUILD}
    ../configure --host=${MACHTYPE} --with-pic \
        lt_cv_prog_compiler_pic_works=yes \
        lt_cv_prog_compiler_pic_works_CXX=yes
    make -j${nproc}
)
export CAPNP=build_native/capnp
if [[ ${target} == *linux* ]]; then
    export LDFLAGS="-lrt"
fi
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-external-capnp
make -j${nproc}
make install
if [[ "${target}" == *-mingw* ]]; then
    # The build for Windows creates "${bindir}/capnpc" as a broken link to
    # "capnp": let's remove it and copy capnp.exe to capnpc.exe
    rm "${bindir}/capnpc"
    cp "${bindir}/capnp${exeext}" "${bindir}/capnpc${exeext}"
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct(["libcapnp", "libcapnp-$(version.major)-$(version.minor)"], :libcapnp),
    ExecutableProduct("capnp", :capnp)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies,
              preferred_gcc_version=v"5", julia_compat="1.6")
