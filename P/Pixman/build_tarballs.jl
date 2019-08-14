using BinaryBuilder

# Collection of sources required to build Pixman
name = "Pixman"
version = v"0.36.0"
sources = [
    "https://www.cairographics.org/releases/pixman-$(version).tar.gz" =>
    "1ca19c8d4d37682adfbc42741d24977903fec1169b4153ec05bb690d4acf9fae",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/pixman-*/

# Apply patch for compilation with clang
#patch < $WORKSPACE/srcdir/patches/clang.patch

# Apply patch for arm on musl
#patch -p1 < $WORKSPACE/srcdir/patches/arm_musl.patch

./configure --prefix=$prefix --host=$target
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# ARM support is broken on GCC 4, so we manually set it to build gcc7 instead.
function workaround_arm(p)
    if arch(p) == :armv7l
        return typeof(p)(arch(p); libc=libc(p), call_abi=call_abi(p), compiler_abi=CompilerABI(:gcc7, BinaryProvider.compiler_abi(p).cxx_abi))
    end
    return p
end
function unworkaround_arm(p)
    if arch(p) == :armv7l
        return typeof(p)(arch(p), libc(p), call_abi(p))
    end
    return p
end

platforms = workaround_arm.(platforms)

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libpixman", :libpixman)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
product_hashes = build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

# Jump through some hoops to create a new build.jl that lists our ARM tarball as not actually gcc7.
for (t, (fname, hash)) in copy(product_hashes)
    p = platform_key_abi(t)
    if arch(p) == :armv7l
        new_t = triplet(unworkaround_arm(p))
        new_fname = "$(name).v$(version).$(new_t).tar.gz"
        @info("Moving $(fname) => $(new_fname)")
        mv(joinpath("products", basename(fname)), joinpath("products", new_fname))
        product_hashes[new_t] = (new_fname, hash)
        delete!(product_hashes, t)
    end
end

repo = BinaryBuilder.get_repo_name()
tag = BinaryBuilder.get_tag_name()
bin_path = "https://github.com/$(repo)/releases/download/$(tag)"
BinaryBuilder.print_buildjl(pwd(), name, version, products(Prefix(pwd())), product_hashes, bin_path)
