# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "TracyProfiler"
version = v"0.7.8"
sources = [
    ArchiveSource("https://github.com/wolfpld/tracy/archive/refs/tags/v$(version).tar.gz",
		  "4021940a2620570ac767eee84e58d572a3faf1570edfaf5309c609752146e950"),
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.15.sdk.tar.xz",
                  "2408d07df7f324d3beea818585a6d990ba99587c218a3969f924dfcc4de93b62"),
    DirectorySource("./bundled")
]

script = raw"""
mkdir -vp $bindir
mkdir -vp $libdir

cd ${WORKSPACE}/srcdir/tracy*

# Apply patches to disable forcing -march
atomic_patch -p1 ../patches/unix_library_release.patch
atomic_patch -p1 ../patches/unix_common_make.patch
atomic_patch -p1 ../patches/library_extension.patch

# Need full c++17 support so upgrade min osx version and install newer SDK
if [[ "${target}" == x86_64-apple-darwin* ]]; then
    echo "Installing newer MacOS 10.15 SDK"

    pushd $WORKSPACE/srcdir/MacOSX10.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    cp -ra usr/* "/opt/${target}/${target}/sys-root/usr/."
    cp -ra System "/opt/${target}/${target}/sys-root/."
    popd

    # append flag to mkfile for macos target min version
    echo "CFLAGS += -mmacosx-version-min=10.15" >> common/unix-release.mk
    # Disable link-time optimization, we have some mess in our macOS toolchain.
    sed -i 's/ -flto//' {profiler,update,capture,csvexport,import-chrome}/build/unix/release.mk
fi

# Build / install the library
make -j${nproc} -C library/unix release
cp -v "./library/unix/libtracy-release.${dlext}" ${libdir}

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

install_license LICENSE
"""

# Only supports x86_64 builds for Linux / Unix
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("x86_64", "macos"),
]
platforms = expand_cxxstring_abis(platforms)

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
    # GTK3 is only needed for the system file dialog on Linux
    Dependency("GTK3_jll", platforms=filter(Sys.islinux, platforms)),
    BuildDependency("Xorg_xorgproto_jll"),
]

# requires std-c++17, full support in gcc 7+, clang 8+
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.6",
    preferred_gcc_version=v"8",
)
