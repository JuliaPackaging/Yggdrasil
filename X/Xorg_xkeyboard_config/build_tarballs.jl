# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_xkeyboard_config"
version = v"2.48"

# Collection of sources required to build xkeyboard_config
sources = [
    ArchiveSource("https://www.x.org/archive/individual/data/xkeyboard-config/xkeyboard-config-$(version.major).$(version.minor).tar.xz",
                  "b77041324f0109f77161ee43743fe04baa485866af8460d31e476ad3f7648fd5"),
]

# Bash recipe for building across all platforms
script = raw"""
# xkeyboard-config >= 2.48 requires Python >= 3.11 while the rootfs
# has 3.9, so use Python_jll. Set LD_LIBRARY_PATH to ensure that
# pyexpat (needed by xml.etree) loads the Python_jll libexpat, not the
# old rootfs one.
mkdir -p ${WORKSPACE}/srcdir/pybin
cat > ${WORKSPACE}/srcdir/pybin/python3 <<EOF
#!/bin/bash
export LD_LIBRARY_PATH=${host_prefix}/lib:\${LD_LIBRARY_PATH}
exec ${host_prefix}/bin/python3 "\$@"
EOF
chmod +x ${WORKSPACE}/srcdir/pybin/python3
# The runner appends host_bindir after /usr/bin, so put ours in front explicitly.
export PATH=${WORKSPACE}/srcdir/pybin:${PATH}

cd $WORKSPACE/srcdir/xkeyboard-config-*
apk update && apk add libxslt
mkdir build && cd build
meson .. --cross-file="${MESON_TARGET_TOOLCHAIN}"
ninja -j${nproc}
ninja install
install_license ../COPYING
"""

# The files are identical for all platforms.
platforms = [AnyPlatform()]

products = Product[
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency("Python_jll"),
    BuildDependency("Xorg_xproto_jll"),
    BuildDependency("Xorg_kbproto_jll"),
    Dependency("Xorg_xkbcomp_jll"),
]

init_block = raw"""
if Sys.islinux() || Sys.isfreebsd()
    ENV["XKB_CONFIG_ROOT"] = get(ENV, "XKB_CONFIG_ROOT", joinpath(artifact_dir, "share", "X11", "xkb"))
end
"""

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", init_block)
