# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "autossh"
version = v"1.4.0" # autossh v1.4f, adapted to the BinaryBuilder requirements

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/Autossh/autossh/releases/download/v1.4f/autossh-1.4f.tgz",
                  "0172e5e1bea40c642e0ef025334be3aadd4ff3b4d62c0b177ed88a8384e2f8f2"),
]

# Bash recipe for building across all platforms
#=
The ac_cv_func_malloc_0_nonnull and ac_cv_func_realloc_0_nonnull is needed
to skipping checking malloc for cross-compilation on aarch64-apple-darwin.
https://github.com/openvenues/libpostal/issues/134

The ac_cv_path_ssh is used to skip the compile-time check on ssh path, to
avoid hard-coding the absolute path (which is /workspace/destdir/bin/ssh)
into the autossh binary. With this, the autossh will always use ssh command
(by searching the PATH variable) in the runtime machine.
This means we prioritize system ssh executable.
If needed, the user can still install OpenSSH_jll and use the AUTOSSH_PATH
variable to change the path of ssh during runtime.
=#
script = raw"""
cd $WORKSPACE/srcdir/autossh*

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    ac_cv_func_malloc_0_nonnull=yes ac_cv_func_realloc_0_nonnull=yes \
    ac_cv_path_ssh=ssh

make -j${nproc}
make install

cat > ${WORKSPACE}/srcdir/LICENSE << EOF
Copyright (c) Carson Harding, 2002-2008.
All rights reserved.
EOF
install_license ${WORKSPACE}/srcdir/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=Sys.iswindows)

# The products that we will ensure are always built
products = [
    ExecutableProduct("autossh", :autossh)
]

# Dependencies that must be installed before this package can be built
dependencies = []

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
