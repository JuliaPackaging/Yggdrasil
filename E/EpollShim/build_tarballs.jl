# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "EpollShim"
version = v"0.0.20230411"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/jiixyj/epoll-shim.git",
              "538cf422ee062eca456c5455f666ae5c41c3c519"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/epoll-shim
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_PREFIX_PATH=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} .. || true
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_TESTING=OFF \
    -DALLOWS_ONESHOT_TIMERS_WITH_TIMEOUT_ZERO_EXITCODE=0 HAVE_POLLRDHUP_RUN_RESULT=0 \
    ..

sed -i 's/PLEASE_FILL_OUT-NOTFOUND/0x2000/' install-include/sys/epoll.h
cmake --build . -j${nproc} --target install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter(Sys.isfreebsd, supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libepoll-shim", :libepoll_shim),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version = v"8", lock_microarchitecture=false)
# Build trigger: 1
