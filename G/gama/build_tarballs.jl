# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "gama"
version = v"2.14.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://gnu.askapache.com/gama/gama-$(version.major).$(version.minor).tar.gz", "96d628272a386f862cef49db668e60c648c1c3f46212ce51add6fa85ef5bb012")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gama-*

if [[ "${target}" == x86_64-linux-musl ]] || [[ "${target}" == x86_64-unknown-freebsd* ]]; then
    export CPPFLAGS="-I${includedir}"
fi

./configure \
--prefix=${prefix} \
--build=${MACHTYPE} \
--host=${target}

make -j${nproc}
make install

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(; experimental = true))


# The products that we will ensure are always built
products = [
    ExecutableProduct("gama-local-xml2txt", :gama_local_xml2txt),
    ExecutableProduct("gama-local-xml2sql", :gama_local_xml2sql),
    ExecutableProduct("gama-local-yaml2gkf", :gama_local_yaml2gkf),
    ExecutableProduct("gama-local", :gama_local),
    ExecutableProduct("gama-local-gkf2yaml", :gama_local_gkf2yaml),
    ExecutableProduct("gama-g3", :gama_g3)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Expat_jll"; compat="2.2.10")
    Dependency("yaml_cpp_jll")
    Dependency("SQLite_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
#needs a c++ 14 compliant compiler
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"6")
