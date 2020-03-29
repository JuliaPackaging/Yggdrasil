using BinaryBuilder

name = "OpenSSH"
version = v"8.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/PowerShell/openssh-portable.git", "ee11c8e15eb11c48afbe98270080c728243c4300")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/openssh-portable*
export CPPFLAGS="-I${prefix}/include"
autoreconf -vi
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc} ssh${exeext} ssh-add${exeext} ssh-keygen${exeext} ssh-keyscan${exeext} ssh-agent${exeext} scp${exeext}
mkdir -p ${bindir}
for binary in ssh${exeext} ssh-add${exeext} ssh-keygen${exeext} ssh-keyscan${exeext} ssh-agent${exeext} scp${exeext}; do 
    install -c -m 0755 -s $binary ${bindir}/$binary; 
done
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("ssh", :ssh),
    ExecutableProduct("scp", :scp),
    ExecutableProduct("ssh-agent", :ssh_agent),
    ExecutableProduct("ssh-add", :ssh_add),
    ExecutableProduct("ssh-keygen", :ssh_keygen),
    ExecutableProduct("ssh-keyscan", :ssh_keyscan),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Zlib_jll")
    Dependency("OpenSSL_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
