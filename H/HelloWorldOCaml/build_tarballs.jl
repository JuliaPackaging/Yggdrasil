using BinaryBuilder

name = "HelloWorldOCaml"
version = v"1.0.0"

# sources generated inline below
sources = [
]

# Bash recipe for building across all platforms
script = raw"""
mkdir -p ${bindir}
echo 'let () = print_endline "hello world"' > hello.ml
ocamlopt -o ${bindir}/hello_world${exeext} hello.ml
install_license /usr/share/licenses/MIT
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# OCaml 5.0 dropped support for 32-bit targets
filter!(p -> nbits(p) != 32, platforms)

# Not yet supported by our OCaml toolchain
filter!(p -> !(Sys.isfreebsd(p)), platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("hello_world", :hello_world),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               compilers=[:c, :ocaml], julia_compat="1.6")
