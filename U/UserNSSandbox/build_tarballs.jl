using BinaryBuilder

name = "UserNSSandbox"
version = v"2023.03.27"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/staticfloat/Sandbox.jl.git",
              "2893e0d917da00546a1b8e08e4929d775f746488"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/Sandbox.jl/deps
mkdir -p ${bindir}
make -j$(nproc)
install -Dvm 755 userns_sandbox ${bindir}/userns_sandbox
install -Dvm 755 userns_overlay_probe ${bindir}/userns_overlay_probe
install_license /usr/share/licenses/MIT
"""

# We only build for Linux
platforms = filter(p -> Sys.islinux(p), supported_platforms())

# The products that we will ensure are always built
products = [
    ExecutableProduct("userns_sandbox", :sandbox),
    ExecutableProduct("userns_overlay_probe", :overlay_probe),
]

# Dependencies that must be installed before this package can be built
build_tarballs(ARGS, name, version, sources, script, platforms, products, Dependency[]; julia_compat="1.6")
