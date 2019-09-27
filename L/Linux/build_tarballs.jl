using BinaryBuilder, Pkg.BinaryPlatforms

name = "Linux"
version = v"5.3"
# Collection of sources required to build linux
sources = [
    "https://gitlab.com/virtio-fs/linux.git" =>
    "980bfa3c485ad975383f1f36fef25eafb8eb2ec7",
    "./sources",
]

script = raw"""
# Disable a lot of this stuff, since kernel building is weird
for tool in LD AS AR CC CXX FC RANLIB READELF STRIP OBJDUMP OBJCOPY NM LIPO LIBTOOL; do
    unset ${tool}
    unset "HOST${tool}"
    unset "BUILD_${tool}"
    unset "${tool}_FOR_BUILD"
done

cd ${WORKSPACE}/srcdir/linux/
export PATH=/usr/bin:$PATH

# Use our generated config
mv ../linuxkernel.config arch/x86/configs/binarybuilder_defconfig

# Add necessary packages
apk add gcc openssl-dev libelf-dev musl-dev bc linux-headers

# Build it
make binarybuilder_defconfig
make -j${nproc}

# Copy out the stuff we care about
cp vmlinux $prefix
cp arch/x86/boot/bzImage $prefix
"""

products = [
    ExecutableProduct("vmlinux", :vmlinux, ".")
]

platforms = [
    Linux(:x86_64; libc=:glibc)
]

dependencies = [
]

# Build the given platforms using the given sources
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

