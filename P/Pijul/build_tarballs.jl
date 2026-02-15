# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Pijul"
true_upstream_version = v"1.0.0-beta.11"
# Upstream version is a beta, but BinaryBuilder requires `major.minor.patch`
version = v"1.0.0"

# Collection of sources required to complete build
sources = [
    FileSource("https://crates.io/api/v1/crates/pijul/$(true_upstream_version)/download", "8a4fc27aa81ee061310d57fce2df9cc45f3149ddb00bdfab2b816beb0359b13d")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
tar xzvf download
cd pijul-*

# Ensure that the `openssl-sys` crate picks up the intended OpenSSL library and headers
# https://docs.rs/openssl/0.10.75/openssl/#manual
export OPENSSL_LIB_DIR="$libdir"
export OPENSSL_INCLUDE_DIR="$includedir"
if [[ "${target}" == "x86_64-w64-mingw32" ]]; then
  export OPENSSL_LIBS="libssl-3-x64:libcrypto-3-x64"
elif [[ "${target}" == "i686-w64-mingw32" ]]; then
  export OPENSSL_LIBS="libssl-3:libcrypto-3"
fi

# Ensure that the `libsodium-sys` crate picks up the intended libsodium library
# https://github.com/sodiumoxide/sodiumoxide/blob/master/README.md#extended-usage
if [[ "${target}" == *-mingw* ]]; then
  export SODIUM_LIB_DIR="$libdir"
  export SODIUM_SHARED=1
else
  export SODIUM_USE_PKG_CONFIG=1
fi

# Build Pijul
cargo build --release

# Install the Pijul binary into the prefix
cargo install --locked --root "$prefix" --path .

# Pijul is licensed under: GPL-2.0
# But the tarball from crates.io doesn't include a copy
# Download a copy of GPL-2.0
curl -L -O https://www.gnu.org/licenses/old-licenses/gpl-2.0.txt
# Install the license into place:
install_license ./gpl-2.0.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    # Linux:
    # Platform("i686", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("powerpc64le", "linux"; libc = "glibc"),

    # macOS:
    Platform("x86_64", "macos"; ),
    Platform("aarch64", "macos"; ),

    # FreeBSD:
    # Platform("x86_64", "freebsd"; ),

    # Windows:
    # Platform("i686", "windows"; ),
    Platform("x86_64", "windows"; ),
]

# The products that we will ensure are always built
products = [
    ExecutableProduct("pijul", :pijul),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="OpenSSL_jll", uuid="458c3c95-2e84-50aa-8efc-19380b2a3a95")),
    Dependency(PackageSpec(name="libsodium_jll", uuid="a9144af2-ca23-56d9-984f-0d03f7b5ccf8")),
]

if Sys.islinux()
  # Dbus is only needed on Linux
  push!(dependencies, Dependency(PackageSpec(name="Dbus_jll", uuid="ee1fde0b-3d02-5ea6-8484-8dfef6360eab")))
end

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", compilers = [:rust, :c])
