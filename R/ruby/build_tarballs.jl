# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ruby"
version = v"2.7.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource(
        "https://cache.ruby-lang.org/pub/ruby/2.7/ruby-2.7.1.tar.gz",
        "d418483bdd0000576c1370571121a6eb24582116db0b7bb2005e90e250eae418",
    ),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/ruby-*/
# otherwise readline and therefore ruby is held back
apk del python
# living on the edge...
sed -i -e 's/v[[:digit:]]\..*\//edge\//g' /etc/apk/repositories
apk update
# these return an error code, but work anyways ¯\_(ツ)_/¯
apk upgrade --update-cache --available --latest || true
apk add ruby-full || true
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-baseruby=/usr/bin/ruby --enable-shared
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter(
    i -> (i isa Linux && i.libc === :glibc) || i isa FreeBSD,
    supported_platforms(),
)

# The products that we will ensure are always built
products = [
    LibraryProduct("libruby", :libruby),
    ExecutableProduct("ruby", :ruby),
    ExecutableProduct("erb", :erb),
    ExecutableProduct("gem", :gem),
    ExecutableProduct("irb", :irb),
    ExecutableProduct("rake", :rake),
    ExecutableProduct("rdoc", :rdoc),
    ExecutableProduct("ri", :ri),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("Libiconv_jll"),
    Dependency("OpenSSL_jll"),
    Dependency("Readline_jll"),
    Dependency("Zlib_jll"),
    Dependency("Gdbm_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies,
    # also to not hold back ruby
    preferred_gcc_version=v"9")
