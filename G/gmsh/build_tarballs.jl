# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "gmsh"
version = v"4.11.1"

# Collection of sources required to build Gmsh
sources = [
    ArchiveSource("https://gmsh.info/src/gmsh-$(version)-source.tgz",
                  "c5fe1b7cbd403888a814929f2fd0f5d69e27600222a18c786db5b76e8005b365"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/gmsh-*
if [[ "${target}" == *linux* ]] || [[ "${target}" == *freebsd* ]]; then
    OPENGL_FLAGS="-DOpenGL_GL_PREFERENCE=LEGACY"
fi
mkdir build
cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_BUILD_DYNAMIC=1 \
    -DDEFAULT=1 \
    ${OPENGL_FLAGS}
make -j${nproc}
make install
mv ${prefix}/lib/gmsh.jl ${prefix}/lib/gmsh.jl.bak
sed ${prefix}/lib/gmsh.jl.bak \
  -e 's/^\(import Libdl\)/#\1/g' \
  -e 's/^\(const lib.*\)/#\1/g' \
  -e 's/^\(module gmsh\)$/\1\nusing gmsh_jll: libgmsh\nconst lib = libgmsh/g' \
  > ${prefix}/lib/gmsh.jl
install_license ../LICENSE.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct(["libgmsh", "gmsh"], :libgmsh),
    ExecutableProduct("gmsh", :gmsh),
    FileProduct("lib/gmsh.jl", :gmsh_api)
]

# Some dependencies are needed or available only on certain platforms
x11_platforms = filter(p -> Sys.islinux(p) || Sys.isfreebsd(p), platforms)
hdf5_platforms = [
    Platform("x86_64", "linux"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("x86_64", "macos"),
    Platform("aarch64", "macos"),
    Platform("x86_64", "windows"),
    Platform("i686", "windows")
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_xorgproto_jll"; platforms=x11_platforms),
    Dependency("Cairo_jll"),
    Dependency("CompilerSupportLibraries_jll"; platforms=filter(!Sys.isbsd, platforms)),
    Dependency("FLTK_jll"),
    Dependency("FreeType2_jll"; compat="2.10.4"),
    Dependency("GLU_jll"; platforms=x11_platforms),
    Dependency("GMP_jll"; compat="6.2"),
    # Updating to a newer HDF5 version requires rebuilding this package
    Dependency("HDF5_jll"; platforms=hdf5_platforms, compat="~1.12.1"),
    Dependency("JpegTurbo_jll"),
    Dependency("Libglvnd_jll"; platforms=x11_platforms),
    Dependency("libpng_jll"),
    Dependency("LLVMOpenMP_jll"; platforms=filter(Sys.isbsd, platforms)),
    Dependency("METIS_jll"),
    Dependency("MMG_jll"),
    Dependency("OCCT_jll"),
    Dependency("Xorg_libX11_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXext_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXfixes_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXft_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXinerama_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXrender_jll"; platforms=x11_platforms),
    Dependency("Zlib_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"9")
