# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "AWSCRT"
version = v"0.1.3"

# Collection of sources required to complete build
sources = [
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/awscrt
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
	-DCMAKE_PREFIX_PATH=${prefix} \
	-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
	-DCMAKE_BUILD_TYPE=Release \
	..
cmake --build . -j${nproc} --target install

install_license /usr/share/licenses/APL2
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
filter!(p -> !(Sys.iswindows(p) && arch(p) == "i686"), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libawscrt", :libawscrt),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("aws_c_auth_jll"; compat="0.7.3"),
    Dependency("aws_c_cal_jll"; compat="0.6.2"),
    Dependency("aws_c_event_stream_jll"; compat="0.3.2"),
    Dependency("aws_c_http_jll"; compat="0.7.12"),
    Dependency("aws_c_iot_jll"; compat="0.1.17"),
    Dependency("aws_c_mqtt_jll"; compat="0.8.12"),
    Dependency("aws_c_s3_jll"; compat="0.3.17"),
    Dependency("aws_checksums_jll"; compat="0.1.17"),
    BuildDependency("aws_lc_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"5")
