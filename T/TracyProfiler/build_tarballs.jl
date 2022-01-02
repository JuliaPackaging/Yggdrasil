# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "TracyProfiler"
version = v"0.7.8"
sources = [
    ArchiveSource("https://github.com/wolfpld/tracy/archive/refs/tags/v$(version).tar.gz",
		  "4021940a2620570ac767eee84e58d572a3faf1570edfaf5309c609752146e950"),
    DirectorySource("./bundled")
]

script = raw"""
mkdir -vp $bindir
mkdir -vp $libdir

cd ${WORKSPACE}/srcdir/tracy*

# Apply patches to disable forcing -march
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/unix_library_release.patch 
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/unix_common_make.patch

if [[ "${target}" == *-apple-* ]]; then
    CC=gcc
    CXX=g++
fi

# Build / install the library
make -j -C library/unix release
cp -v ./library/unix/libtracy-release* $libdir

# Build / install the profiler GUI
make -j${nproc} -C profiler/build/unix release
cp -v ./profiler/build/unix/Tracy-release* $bindir

# Build / install update utility
make -j${nproc} -C update/build/unix release
cp -v ./update/build/unix/update-release* $bindir

# Build / install capture utility
make -j${nproc} -C capture/build/unix release
cp -v ./capture/build/unix/capture-release* $bindir

# Build / install csvexport utility
make -j${nproc} -C csvexport/build/unix release
cp -v ./csvexport/build/unix/csvexport-release* $bindir

# Build / install import-chrome utility
make -j${nproc} -C import-chrome/build/unix release
cp -v ./import-chrome/build/unix/import-chrome-release* $bindir
"""

# Only supports x86_64 builds for Linux / Unix
# TODO: There are issues with cross compiling the libbacktrace libtracy on MacOS
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
] 

products = Product[
    LibraryProduct("libtracy-release", :libtracy),
    ExecutableProduct("Tracy-release", :tracy_profiler_exe),
    ExecutableProduct("update-release", :tracy_update_exe),
    ExecutableProduct("capture-release", :tracy_capture_exe),
    ExecutableProduct("csvexport-release", :tracy_csvexport_exe),
    ExecutableProduct("import-chrome-release", :tracy_import_chrome_exe),
]

dependencies = [
    Dependency("GLFW_jll"),
    Dependency("FreeType2_jll"),
    Dependency("Capstone_jll"),
    Dependency("GTK3_jll"),
    BuildDependency("Xorg_compositeproto_jll"),
    BuildDependency("Xorg_damageproto_jll"),
    BuildDependency("Xorg_fixesproto_jll"),
    BuildDependency("Xorg_inputproto_jll"),
    BuildDependency("Xorg_kbproto_jll"),
    BuildDependency("Xorg_randrproto_jll"),
    BuildDependency("Xorg_renderproto_jll"),
    BuildDependency("Xorg_xextproto_jll"),
    BuildDependency("Xorg_xineramaproto_jll"),
    BuildDependency("Xorg_xproto_jll"),
]

# requires std-c++17, full support in gcc 7+, clang 8+
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.6",
    preferred_gcc_version=v"8",
)
