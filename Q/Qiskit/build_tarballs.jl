# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "Qiskit"
version = v"2.3.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/Qiskit/qiskit.git", "1619be07b9cc3c14832fe8f946e22fbee400ef38")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/qiskit
export PYO3_PYTHON=${host_bindir}/python3
export PYO3_CROSS_LIB_DIR=$WORKSPACE/destdir/lib
export RUSTFLAGS="-L ${libdir}"

# not enough space in /tmp
export TMPDIR=$WORKSPACE/tmp
mkdir $TMPDIR

# avoid 'cannot create cdylib' error on musl targets
# see https://github.com/rust-lang/cargo/issues/8607
#     https://github.com/rust-lang/rust/issues/59302
if [[ "${target}" == *-musl* ]]; then
    export RUSTFLAGS="${RUSTFLAGS} -C target-feature=-crt-static"
fi

# The current Qiskit C API build instructions say to use a Makefile that is
# improperly formed and not suitable for cross compilation.  So, instead,
# we invoke Cargo directly and copy the handful of files that result to their
# proper location.
cargo rustc --release --crate-type cdylib -p qiskit-cext
install -Dvm 755 "target/${rust_target}/release/libqiskit_cext.${dlext}" "${libdir}/libqiskit.${dlext}"
mkdir -p "${includedir}/qiskit"
cp -v target/qiskit.h "${includedir}"
cp -vr crates/cext/include/qiskit/* "${includedir}/qiskit"
install_license LICENSE.txt
"""

# Install a newer SDK which contains `__ZNSt3__120__libcpp_atomic_waitEPVKvx`
# and related symbols on x86_64-apple-darwin
sources, script = require_macos_sdk("11.0", sources, script)

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "musl"),
    Platform("aarch64", "macos"),
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libqiskit", :libqiskit)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="cbindgen_jll", uuid="a52b955f-5256-5bb0-8795-313e28591558"))
    # libpython is required at run time until
    # https://github.com/Qiskit/qiskit/issues/14240 is fixed, which is
    # currently targeted for Qiskit 2.4.0.
    Dependency(PackageSpec(name="Python_jll", uuid="93d3a430-8e7c-50da-8e8d-3dfcfb3baf05"))
    # Python 3.10 or higher is required by the build process, but at the moment
    # only Python 3.9 is available in the base image, hence the following requirement.
    HostBuildDependency(PackageSpec(name="Python_jll", uuid="93d3a430-8e7c-50da-8e8d-3dfcfb3baf05"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", compilers = [:rust, :c])
