using BinaryBuilder

name = "cuQuantum"
version_string = "0.1.0.30"
version = let
    maj, min, patch, extra = parse.(Int, split(version_string, '.'))
    VersionNumber(maj, min, patch * 100 + extra)
end

sources = [
    ArchiveSource("https://developer.download.nvidia.com/compute/cuquantum/redist/cuquantum/linux-x86_64/cuquantum-linux-x86_64-0.1.0.30-archive.tar.xz",
                  "8ad8e98f14275ffe0de02574be5c86224af1c657c41baf02c16440301ffe0aae";
                  unpack_target="x86_64-linux-gnu"),
    ArchiveSource("https://developer.download.nvidia.com/compute/cuquantum/redist/cuquantum/linux-sbsa/cuquantum-linux-sbsa-0.1.0.30-archive.tar.xz",
                  "3dd04cf08f1323318e0e63a7e28bc904c426ced3367aca809fba7e7beef94063";
                  unpack_target="aarch64-linux-gnu"),
    ArchiveSource("https://developer.download.nvidia.com/compute/cuquantum/redist/cuquantum/linux-ppc64le/cuquantum-linux-ppc64le-0.1.0.30-archive.tar.xz",
                  "0eb84eef619a1cfab5870fb585200a9869a197866685252e4ca8187322809554";
                  unpack_target="powerpc64le-linux-gnu"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/${target}/cuquantum-*

mkdir -p ${prefix}
cp -var lib/ include/ ${prefix}/.
cp -var pkg-config/ ${prefix}/lib/.

# Fixup pkg-config files
sed -i \
    -e "s?^cudaroot=.*?cudaroot=${prefix}?" \
    -e "s?^libdir=.*?libdir=${libdir}?" \
    -e "s?^includedir=.*?includedir=${includedir}?" \
    ${prefix}/lib/pkg-config/*.pc

# Remove static libraries
rm ${libdir}/*.a

# Install license files
install_license LICENSE docs/*
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("powerpc64le", "linux"; libc="glibc"),
]

# The products that we will ensure are always built
products = [
    LibraryProduct("libcustatevec", :libcustatevec; dont_dlopen=true),
    LibraryProduct("libcutensornet", :libcutensornet; dont_dlopen=true),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
