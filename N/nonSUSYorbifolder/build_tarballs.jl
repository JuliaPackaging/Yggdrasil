# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "nonSUSYorbifolder"
version = v"1.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/StringsIFUNAM/nonSUSYorbifolder.git",
              "c917adea59b788872ac00bc41239dd791afc4ff1"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/nonSUSYorbifolder

# configure.ac calls AX_PATH_GSL, normally provided by autoconf-archive; ship it directly
cp "${WORKSPACE}/srcdir/m4/ax_path_gsl.m4" m4/

autoreconf -fi

CPPFLAGS="-I${prefix}/include" LDFLAGS="-L${prefix}/lib" \
    ./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}

# `nonSUSYorbifolder` is noinst_PROGRAMS; install it and Geometry/ together
# manually so an executable-relative lookup finds both.
mkdir -p "${prefix}/bin"
cp nonSUSYorbifolder "${prefix}/bin/"
cp -r Geometry "${prefix}/bin/Geometry"

install_license COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(; exclude=p -> Sys.iswindows(p) || Sys.isapple(p)))

# The products that we will ensure are always built
products = [
    ExecutableProduct("nonSUSYorbifolder", :nonSUSYorbifolder),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="GSL_jll", uuid="1b77fbbe-d8ee-58f0-85f9-836ddc23a7a4")),
    Dependency(PackageSpec(name="boost_jll", uuid="28df3c45-c428-5900-9ff8-a3135698ca75")),
    Dependency(PackageSpec(name="Readline_jll", uuid="05236dd9-4125-5232-aa7c-9ec0c9b2c25a")),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"9")
