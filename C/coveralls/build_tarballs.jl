# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "coveralls"
version = v"0.6.15"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/coverallsapp/coverage-reporter.git", "0e1399f945bf132f942565499fa61e9ac41d9e8c"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/coverage-reporter

# Update package database and install Crystal compiler
apk update
apk add --no-cache \
  -X https://dl-cdn.alpinelinux.org/alpine/v3.16/main \
  -X https://dl-cdn.alpinelinux.org/alpine/v3.16/community \
  crystal=1.4.1-r0 shards=0.17.0-r0

# Install development dependencies needed for Crystal compilation
apk add --no-cache \
    build-base \
    openssl-dev \
    openssl-libs-static \
    yaml-dev \
    yaml-static \
    zlib-dev \
    zlib-static \
    pcre2-dev \
    libevent-dev \
    libevent-static \
    gc-dev

# Set environment variables for static linking
export CRYSTAL_CACHE_DIR=${WORKSPACE}/crystal_cache
mkdir -p ${CRYSTAL_CACHE_DIR}

# Install Crystal dependencies
shards install --production

# Build the coveralls binary with static linking
# Using similar approach to the upstream Makefile but simplified for BinaryBuilder
crystal build src/cli.cr \
    --release \
    --static \
    --no-debug \
    -o coveralls \
    --link-flags="-static" \
    || echo "Static build failed, trying without --static flag" && \
crystal build src/cli.cr \
    --release \
    --no-debug \
    -o coveralls

# Install the binary
mkdir -p ${bindir}
install -m 755 coveralls ${bindir}/

# Install license
install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
# The products that we will ensure are always built
products = [
    ExecutableProduct("coveralls", :coveralls),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    # Note: Crystal has its own runtime and standard library,
    # but we may need these for linking
    Dependency("OpenSSL_jll"; compat="3.0.8"),
    Dependency("libevent_jll"),
    Dependency("PCRE2_jll"),
    Dependency("Zlib_jll"),
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("LibYAML_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", compilers=[:c], preferred_gcc_version=v"8")
