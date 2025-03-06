# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, BinaryBuilderBase, Pkg

name = "crun"
version = v"1.18.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/containers/crun",
              "8656b2548509fcc69ea7e8823a870564360a57a1")
]

# Bash recipe for building across all platforms
script = raw"""
cd crun
install_license COPYING

# next to our (outdated) glibc's sched.h, also include the one from the kernel
# in order to pick up more recent definitions (e.g. CLONE_NEWCGROUP)
find src -name '*.c' -exec sed -i '/#include <sched.h>/a #include <linux/sched.h>' {} \;

./autogen.sh
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
            --disable-criu # missing JLL
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
filter!(Sys.islinux, platforms)
filter!(p -> libc(p) == "glibc", platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("crun", :crun)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("YAJL_jll"),
    Dependency("libcap_jll"),
    Dependency("systemd_jll"),
    Dependency("libseccomp_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"5")
