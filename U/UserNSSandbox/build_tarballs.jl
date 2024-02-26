using BinaryBuilder

name = "UserNSSandbox"
version = v"2023.09.26"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/staticfloat/Sandbox.jl.git",
              "a0a0950a06aeef388bbe55abaa2d0dc386c5dbe6"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/Sandbox.jl/deps
mkdir -p ${bindir}
make -j$(nproc)
install -Dvm 755 userns_sandbox ${bindir}/sandbox
install -Dvm 755 userns_overlay_probe ${bindir}/overlay_probe
install_license /usr/share/licenses/MIT
"""

# We only build for Linux
platforms = filter(p -> Sys.islinux(p), supported_platforms())

# The products that we will ensure are always built
products = [
    ExecutableProduct("sandbox", :sandbox),
    ExecutableProduct("overlay_probe", :overlay_probe),
]

# Dependencies that must be installed before this package can be built
build_tarballs(ARGS, name, version, sources, script, platforms, products, Dependency[]; julia_compat="1.6")
