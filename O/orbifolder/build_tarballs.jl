# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "orbifolder"
version = v"1.2.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://orbifolder.hepforge.org/source/V1.2.1/orbifolder-1.2.1.tgz",
                  "607c38fc54942e8306abe3919d7928df78c9316b2cb79b7629f8b1dd02b69584"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/orbifolder-1.2.1

update_configure_scripts
CPPFLAGS="-I${prefix}/include" LDFLAGS="-L${prefix}/lib" \
    ./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}

# `make install` does not put the binary under ${prefix}; install it and
# Geometry/ together manually so an executable-relative lookup finds both.
install -Dvm 755 src/orbifolder/orbifolder "${prefix}/bin/orbifolder"
cp -r Geometry "${prefix}/bin/Geometry"

install_license COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(; exclude=p -> Sys.iswindows(p) || Sys.isapple(p)))

# The products that we will ensure are always built
products = [
    ExecutableProduct("orbifolder", :orbifolder),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="GSL_jll", uuid="1b77fbbe-d8ee-58f0-85f9-836ddc23a7a4")),
    Dependency(PackageSpec(name="boost_jll", uuid="28df3c45-c428-5900-9ff8-a3135698ca75")),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"9")
