# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
include("../common.jl")

gap_version = v"400.1500.0"
name = "zeromqinterface"
upstream_version = "0.17" # when you increment this, reset offset to v"0.0.0"
offset = v"1.0.0" # increment this when rebuilding with unchanged upstream_version, e.g. gap_version changes
version = offset_version(upstream_version, offset)

# Collection of sources required to build this JLL
sources = [
    ArchiveSource("https://github.com/gap-packages/ZeroMQInterface/releases/download/v$(upstream_version)/ZeroMQInterface-$(upstream_version).tar.gz",
                  "d77e979dc3a0b18e95fe2b61f45e5a765cb5661d52507019cf307929f50f65a9"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ZeroMQInterface*

export CPPFLAGS="-I$includedir"  # workaround issue with clang on Linux with musl libc, see https://github.com/JuliaPackaging/Yggdrasil/pull/10000
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-gaproot=${prefix}/lib/gap --with-cddlib=${prefix}
make -j${nproc}

# copy the loadable module
mkdir -p ${prefix}/lib/gap
cp bin/*/*.so ${prefix}/lib/gap/

#install_license LICENSE  # FIXME
"""

name = gap_pkg_name(name)
dependencies = gap_pkg_dependencies(gap_version)
platforms = gap_platforms()

append!(dependencies, [
    Dependency("ZeroMQ_jll"),
])

# The products that we will ensure are always built
products = [
    FileProduct("lib/gap/zeromqinterface.so", :zeromqinterface),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", preferred_gcc_version=v"7")

# rebuild trigger: 1
