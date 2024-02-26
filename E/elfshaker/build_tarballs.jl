using BinaryBuilder, BinaryBuilderBase

name = "elfshaker"
version = v"0.9.1"

# No sources, we're just building the testsuite
sources = [
    GitSource("https://github.com/elfshaker/elfshaker",
              "d8ec61253ef5ebc84de41d54a03b68f91e7dbad8")
]

# Bash recipe for building across all platforms
script = raw"""
cd elfshaker
install_license LICENSE

cargo build --release --bin elfshaker

install -Dvm 755 "target/${rust_target}/release/elfshaker${exeext}" "${bindir}/elfshaker${exeext}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter(supported_platforms()) do p
    !(Sys.iswindows(p)) && proc_family(p) != "power"
end

# The products that we will ensure are always built
products = [
    ExecutableProduct("elfshaker", :elfshaker),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               compilers=[:c, :rust], julia_compat="1.6", lock_microarchitecture=false)
