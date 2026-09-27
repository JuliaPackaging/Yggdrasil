# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "oneAPI_Support_Headers_LTS"
version = v"2025.3.1"

# Aurora dgpu LTS variant of oneAPI_Support_Headers — currently pinned to the
# Intel oneAPI toolkit version Aurora ships alongside dgpu LTS 2523.40
# (oneAPI 2025.3.1). This package extracts the SYCL/MKL development headers
# from Intel's `onemkl-sycl-include` pip wheel.
#
# When Aurora ticks a new oneAPI toolkit version, refresh the wheel URL/SHA
# and the in-script `2025.3.1` version references — bump in place. The
# corresponding wheel can be located at:
#   https://pypi.org/project/onemkl-sycl-include/<X.Y.Z>/

# Collection of sources required to complete build
sources = [
    # https://pypi.org/project/onemkl-sycl-include/2025.3.1/
    FileSource("https://files.pythonhosted.org/packages/79/70/d64211c4cf78490b273d449a7a4bd62e11a2a61c0b6b8dbef6b7c179c244/onemkl_sycl_include-2025.3.1-py2.py3-none-manylinux_2_28_x86_64.whl",
               "8cf08d257ecf004f71f6c70b49da9793332daef7e556ab062f342071900fe435"; filename="oneapi-headers.whl"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
unzip -d oneapi-headers oneapi-headers.whl
cd oneapi-headers/onemkl_sycl_include-2025.3.1.data/data

mkdir $includedir
cp -r include/oneapi $includedir

install_license $WORKSPACE/srcdir/oneapi-headers/onemkl_sycl_include-2025.3.1.dist-info/LICENSE.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [AnyPlatform()]

# The products that we will ensure are always built
products = [
    FileProduct("include/oneapi/mkl.hpp", :mkl_hpp)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
