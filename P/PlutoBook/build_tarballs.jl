# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "PlutoBook"
version = v"0.9.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/plutoprint/plutobook.git", "d18e317a76da51816240c203253bfabb72208011"),
    # We need C++20
    FileSource("https://github.com/alexey-lysiuk/macos-sdk/releases/download/14.5/MacOSX14.5.tar.xz",
               "f6acc6209db9d56b67fcaf91ec1defe48722e9eb13dc21fb91cfeceb1489e57e"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/plutobook/

if [[ "${target}" == *-apple-darwin* ]]; then
    rm -rf /opt/${target}/${target}/sys-root/System /opt/${target}/${target}/sys-root/usr/include/libxml2
    tar --extract --file=${WORKSPACE}/srcdir/MacOSX14.5.tar.xz --directory="/opt/${target}/${target}/sys-root/." --strip-components=1 MacOSX14.5.sdk/System MacOSX14.5.sdk/usr
    export MACOSX_DEPLOYMENT_TARGET=14.5
fi

mkdir build
cd build/
meson setup .. --cross-file=${MESON_TARGET_TOOLCHAIN} --buildtype=release
ninja -j${nproc}
ninja install

install_license ${WORKSPACE}/srcdir/plutobook/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("powerpc64le", "linux"; libc = "glibc"),
    Platform("riscv64", "linux"; libc = "glibc"),
    Platform("x86_64", "macos"; ),
    Platform("aarch64", "macos"; ),
    Platform("i686", "windows"; ),
    Platform("x86_64", "windows"; )
]
platforms = expand_cxxstring_abis(platforms)
filter!(p -> cxxstring_abi(p) == "cxx11", platforms)


# The products that we will ensure are always built
products = Product[
	LibraryProduct("libplutobook", :libplutobook),
	ExecutableProduct("html2pdf", :html2pdf), 
	ExecutableProduct("html2png", :html2png)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Cairo_jll", uuid="83423d85-b0ee-5818-9007-b63ccbeb887a"); compat="1.18.5")
    Dependency(PackageSpec(name="FreeType2_jll", uuid="d7e528f0-a631-5988-bf34-fe36492bcfd7"))
    Dependency(PackageSpec(name="Fontconfig_jll", uuid="a3f928ae-7b40-5064-980b-68af3947d34b"))
    Dependency(PackageSpec(name="HarfBuzz_jll", uuid="2e76f6c2-a576-52d4-95c1-20adfe4de566"); compat="8.5.1")
    Dependency(PackageSpec(name="Expat_jll", uuid="2e619515-83b5-522b-bb60-26c02a35a201"))
    Dependency(PackageSpec(name="ICU_jll", uuid="a51ab1cf-af8e-5615-a023-bc2c838bba6b"); compat="76.2")
    Dependency(PackageSpec(name="LibCURL_jll", uuid="deac9b47-8bc7-5906-a0fe-35ac56dc84c0"); compat="7.73,8")
    Dependency(PackageSpec(name="JpegTurbo_jll", uuid="aacddb02-875f-59d6-b918-886e6ef4fbf8"))
    Dependency(PackageSpec(name="libwebp_jll", uuid="c5f90fcd-3b7e-5836-afba-fc50a0988cb2"))
    BuildDependency(PackageSpec(name="Xorg_xproto_jll", uuid="46797783-dccc-5433-be59-056c4bde8513"))
    BuildDependency(PackageSpec(name="Xorg_kbproto_jll", uuid="060dd47b-79ec-5ba1-a7b2-f4f2f7dcdd0f"))
    BuildDependency(PackageSpec(name="Xorg_xextproto_jll", uuid="d13bc2ba-d276-5c6f-8a1c-29ed04aab5d0"))
    BuildDependency(PackageSpec(name="Xorg_renderproto_jll", uuid="21e99dc2-7dba-5609-a726-b181bd3bbb6c"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", preferred_gcc_version = v"12.1.0", dont_dlopen=true, clang_use_lld = false)
