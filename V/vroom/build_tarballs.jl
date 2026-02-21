using BinaryBuilder, Pkg

name = "vroom"
version = v"1.14.0"

# Collection of sources required to complete build
sources = [
    # v1.14.0
    GitSource("https://github.com/VROOM-Project/vroom.git", "1fd711bc8c20326dd8e9538e2c7e4cb1ebd67bdb"),
    # Vroom v1.14.0 does not work with the latest version of ASIO. This is ASIO v1.18.1
    GitSource("https://github.com/chriskohlhoff/asio.git", "b84e6c16b2ea907dbad94206b7510d85aafc0b42"),
]

# Bash recipe for building across all platforms
# ASIO is expected at ../asio (sibling of vroom); add its include path to the makefile
script = raw"""
cd $WORKSPACE/srcdir
# Windows: no pkg-config for OpenSSL; set include/lib paths for ASIO and vroom builds
if [[ ${target} == *-w64-mingw32 ]]; then
    export CPPFLAGS="-I${includedir} ${CPPFLAGS}"
    export LDFLAGS="-L${libdir} ${LDFLAGS}"
fi
cd asio/asio
./autogen.sh
# Windows: --with-openssl adds -I and -L so SSL examples can link; elsewhere pkg-config works
if [[ ${target} == *-w64-mingw32 ]]; then
    ./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-openssl=$(dirname ${includedir})
else
    ./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
fi
make install
cd ../../vroom
git submodule init
git submodule update
if [[ ${target} == *-w64-mingw32 ]]; then
    # There is no pkg-config info for OpenSSL on Windows. The makefile passes -lssl -lcrypto
    # but not -L and does not use LDFLAGS. On Windows libdir=${prefix}/bin (where DLLs live).
    export CPPFLAGS="-I${includedir} ${CPPFLAGS}"
    for f in $(find . \( -name Makefile -o -name makefile -o -name '*.mk' \) -type f); do
        if grep -q 'lssl' "$f" 2>/dev/null; then
            sed -i "s| -lssl| -L${libdir} -lssl|g" "$f"
            sed -i "s| -lcrypto| -L${libdir} -lcrypto -lws2_32 -lmswsock|g" "$f"
        fi
    done
fi
cd src
# Use GCC instead of Clang on macOS: Apple's libc++ lacks std::jthread (vroom#1062, pyvroom#106)
# Override deployment target for GCC compatibility (Runner/default may use 14.5 which GCC rejects).
if [[ "${target}" == *-freebsd* ]] || [[ "${target}" == *-apple-* ]]; then
    export CC=gcc
    export CXX=g++
    export MACOSX_DEPLOYMENT_TARGET=10.15
    export CFLAGS="$(echo " ${CFLAGS}" | sed 's/ -mmacosx-version-min=[^ ]*//g' | sed 's/^ *//')"
    export CXXFLAGS="$(echo " ${CXXFLAGS}" | sed 's/ -mmacosx-version-min=[^ ]*//g' | sed 's/^ *//')"
    export LDFLAGS="$(echo " ${LDFLAGS}" | sed 's/ -Wl,-sdk_version,[^ ]*//g' | sed 's/^ *//')"
fi
make -j${nproc}
cd ..
mv bin/vroom ${bindir}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = Product[
    ExecutableProduct("vroom", :vroom),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="GLPK_jll", uuid="e8aa6df9-e6ca-548a-97ff-1f85fc5b8b98"))
    Dependency(PackageSpec(name="jq_jll", uuid="f8f80db2-c0ba-59e9-a5c3-38d72e3c5ac2"))
    Dependency(PackageSpec(name="OpenSSL_jll", uuid="458c3c95-2e84-50aa-8efc-19380b2a3a95"))
]

# Build the tarballs, and possibly a `build.jl` as well.
# Need GCC 13+ for C++20 <format> and full C++20 support (e.g. `using enum`)
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"13")
