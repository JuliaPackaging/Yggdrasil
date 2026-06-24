using BinaryBuilder

name = "uconfig"
version = v"0.34.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/skeeto/u-config/releases/download/v$(version)/u-config-$(version).tar.gz",
                  "c6dfbc1b9488e5fdd4a499a3c5f7b968c7d891352f9be754c90ab9eaa805ae3e"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/u-config*

case ${target} in
    # These specific main files do not work
    # aarch64-linux*) cc -Os -o pkg-config${exeext} main_linux_aarch64.c;;
    # x86_64-linux*)  cc -Os -o pkg-config${exeext} main_linux_amd64.c;;
    # i686-linux*)    cc -Os -o pkg-config${exeext} main_linux_i686.c;;
    *-w64-*)        cc -Os -nostartfiles -o pkg-config${exeext} main_windows.c;;
    *)              cc -Os -o pkg-config${exeext} main_posix.c;;
esac

install -Dvm 755 pkg-config${exeext} ${bindir}/pkg-config${exeext}

install_license UNLICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("pkg-config", :pkg_config),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"5")
