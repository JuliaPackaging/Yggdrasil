using BinaryBuilder2

name = "UserNSSandbox"
version = v"2026.11.26"

# Sandbox.jl's user namespace launcher and its overlayfs probe, from `deps/`
sources = [
    GitSource("https://github.com/JuliaContainerization/Sandbox.jl.git",
              "11e7828e792e767a93842d0e47bba372a4718ad9"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/Sandbox.jl/deps
make -j${nproc}
install -Dvm 755 userns_sandbox ${bindir}/sandbox
install -Dvm 755 userns_overlay_probe ${bindir}/overlay_probe
install_license ${WORKSPACE}/srcdir/Sandbox.jl/LICENSE.md
"""

# User namespaces and overlayfs are Linux-only
platforms = filter(Sys.islinux, supported_platforms())

# Sandbox.jl looks the binaries up by these names
products = [
    ExecutableProduct("sandbox", :sandbox),
    ExecutableProduct("overlay_probe", :overlay_probe),
]

build_tarballs(;
    src_name = name,
    src_version = version,
    sources,
    script,
    platforms,
    products,
    julia_compat = "1.6",
)
