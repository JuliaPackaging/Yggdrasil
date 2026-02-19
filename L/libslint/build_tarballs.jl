# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "libslintwrapper"
version = v"0.1.8"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/oheil/Slint.jl.git", "ff7d5fbc6057da9a4160f9963c0615e121a74465")
]

# Adapted from the justfile of the repo
script = raw"""
install_license Slint.jl/LICENSE

# need more space
mkdir opt-x86_64-linux-musl
mkdir opt-x86_64-linux-musl/registry
ln -s /workspace/srcdir/opt-x86_64-linux-musl/registry /opt/x86_64-linux-musl/registry

# need more space
mv /tmp .
ln -s /workspace/srcdir/tmp /tmp

cd Slint.jl/deps/SlintWrapper
cargo build --release 

if [[ "${target}" == *-mingw* ]]; then
	install -Dvm 755 target/${rust_target}/release/slintwrapper.${dlext} "${libdir}/libslintwrapper.${dlext}"
else
	install -Dvm 755 target/${rust_target}/release/libslintwrapper.${dlext} "${libdir}/libslintwrapper.${dlext}"
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
#    Platform("x86_64", "macos"; ),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("x86_64", "windows")
]

# The products that we will ensure are always built
products = [
    LibraryProduct("libslintwrapper", :libslintwrapper),
    #FileProduct("deps/SlintWrapper/include/slintwrapper.h", :slintwrapper_h),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Fontconfig_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :rust])

