# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "lttng_tools"
version = v"2.12.4"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://lttng.org/files/lttng-tools/lttng-tools-$(version).tar.bz2",
                  "d729f8c2373a41194f171aeb0da0a9bb35ac181f31afa7e260786d19a500dea1")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/lttng-tools-*
export CPPFLAGS="-I${includedir}"
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-man-pages
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(Sys.islinux, supported_platforms())


# The products that we will ensure are always built
products = [
    LibraryProduct("liblttng-ctl", :liblttng_ctl),
    ExecutableProduct("lttng-sessiond", :lttng_sessiond),
    ExecutableProduct("lttng-consumerd", :lttng_consumerd, "lib/lttng/libexec"),
    ExecutableProduct("lttng-crash", :lttng_crash),
    ExecutableProduct("lttng-relayd", :lttng_relayd),
    ExecutableProduct("lttng", :lttng)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="URCU_jll", uuid="aa747835-a391-587f-982f-064ff03f7d29"))
    Dependency(PackageSpec(name="Popt_jll", uuid="e80236cf-ab1d-5f5d-8534-1d1285fe49e8"))
    # We had to restrict compat with XML2 because of ABI breakage:
    # https://github.com/JuliaPackaging/Yggdrasil/pull/10965#issuecomment-2798501268
    # Updating to `compat="~2.14.1"` is likely possible without problems but requires rebuilding this package
    Dependency(PackageSpec(name="XML2_jll", uuid="02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"); compat="~2.13.6")
    Dependency(PackageSpec(name="lttng_ust_jll", uuid="a2826780-45ff-53db-9dda-fd961bc58de1"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"5")
