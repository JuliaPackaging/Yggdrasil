# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "TestU01"
version = v"1.2.3"

# Use unofficial git mirror instead of official URL, as it is unversioned and may be overwritten in the future.
# Manually verified to be bit-for-bit identical (except for a missing empty `bin/` directory) to official v1.2.3 release.
sources = [
    GitSource(
        "https://github.com/blep/TestU01.git",
        "8e39bd74544f2b6d857a59e2787a5f1c87cc4313"
    ),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/TestU01*
update_configure_scripts

MFLAGS=(
    -j${nproc}

    # Always set this since the only executable we build is a host-tool
    # and we don't want to accidentally try to rebuild it.
    EXEEXT=""
)

if [[ "${target}" = *-mingw* ]]; then
  export lt_cv_deplibs_check_method=pass_all
  export LDFLAGS="-lws2_32"
fi

./bootstrap
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}

# Make `tcode` to run on the host, as it's used to bootstrap
make ${MFLAGS[@]} CC="${HOSTCC}" LD="${HOSTLD}" LDFLAGS="" tcode

# libtool is hopeless, I give up
if [[ "${target}" = *-mingw* ]]; then
    cp .libs/tcode tcode
fi

# Make the library we actually want to ship
make ${MFLAGS[@]}
make ${MFLAGS[@]} install

# Compile TestU01extractors shim
make ${MFLAGS[@]} -C ../src/TestU01extractors/ install

# Delete improperly-installed `tcode`
rm ${bindir}/tcode

install_license COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libtestu01", :libtestu01),
    LibraryProduct("libprobdist", :libprobdist),
    LibraryProduct("libtestu01extractors", :libtestu01extractors),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

