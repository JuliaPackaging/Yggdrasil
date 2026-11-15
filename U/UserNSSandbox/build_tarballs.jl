using BinaryBuilder

name = "UserNSSandbox"
version = v"2026.11.06"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/JuliaContainerization/Sandbox.jl.git",
              "1828a3f1fbeb26f9d4d00045204c8d7702c319c7"),
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
