# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "difmap"
# difmap version is 2.5q, mapped here to numerical value of 2.5.17
version = v"2.5.17"

sources = [
    ArchiveSource("ftp://ftp.astro.caltech.edu/pub/difmap/difmap2.5q.tar.gz", "18f61641a56d41624e603bf64794c9f1b072eea320a0c1e0a22ac0ca4d3cef95"),
    DirectorySource("./bundled"),
]

script = raw"""
cd $WORKSPACE/srcdir/uvf_difmap*

for f in ../patch*; do
    atomic_patch -p0 "${f}"
done

if [[ ${target} == *apple* ]]; then
    # disable GUI support: X11 jlls not available for this platform
    sed -i 's|^PGPLOT_LIB="-lpgplot -lX11"$|PGPLOT_LIB="-lpgplot"|' configure
    CC=gcc CXX=g++ CCOMPL=gcc ./configure arm-osx-gcc
else
    ./configure linux-i486-gcc
fi
./makeall
install difmap "${bindir}/difmap"
install_license ./README
"""

platforms = [
    Platform("x86_64", "linux"; libc="musl"),
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("i686", "linux"; libc="glibc"),
    Platform("aarch64", "macos"),
]
platforms = expand_gfortran_versions(platforms)

products = [ExecutableProduct("difmap", :difmap)]

dependencies = [
    Dependency(PackageSpec(name="PGPLOT_jll", uuid="b11e30b1-63be-5002-9df0-88ee0fe906ff"))
    Dependency(PackageSpec(name="Xorg_libX11_jll", uuid="4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"))
    Dependency(PackageSpec(name="Ncurses_jll", uuid="68e3532b-a499-55ff-9963-d1c0c0748b3a"))
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, julia_compat="1.6")
