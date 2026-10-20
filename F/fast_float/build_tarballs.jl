# Note that this script can accept some limited command-line arguments, such as
# `--register`, `--enable-system-cxx`, `--sanitize`, etc. Run
# `julia build_tarballs.jl --help` to see a full list.
using BinaryBuilder

name = "fast_float"
version = v"8.2.4"

# fast_float ships a pre-generated single-header amalgamation as a release
# asset. We download that directly, plus a FileSource for the upstream
# LICENSE-MIT so that install_license works correctly.
sources = [
    FileSource(
        "https://github.com/fastfloat/fast_float/releases/download/v$(version)/fast_float.h",
        "0055d1c392c2ebd9933146d3efcc9a7b98abb45960ecb90fcaadfc00b9be22e6";
        filename = "fast_float.h",
    ),
    FileSource(
        "https://raw.githubusercontent.com/fastfloat/fast_float/v$(version)/LICENSE-MIT",
        "e562f3f974ced7e69dd1db77b820b36bcf8f30377f1aa105723fba449c53c4e6",
        filename = "LICENSE-MIT",
    ),
]

# This is a header-only C++17 library; there is nothing to compile.
# We simply install the single-header file under include/fast_float/ so
# downstream packages can #include "fast_float/fast_float.h" as documented.
script = raw"""
install -Dvm 644 "${WORKSPACE}/srcdir/fast_float.h" "${includedir}/fast_float/fast_float.h"

install_license "${WORKSPACE}/srcdir/LICENSE-MIT"
"""

# Header-only → a single AnyPlatform tarball works for every target.
platforms = [AnyPlatform()]

# FileProduct performs no binary audit, which is correct for a header file.
products = [
    FileProduct("include/fast_float/fast_float.h", :fast_float_h),
]

# No compile-time or runtime dependencies.
dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat = "1.6")
