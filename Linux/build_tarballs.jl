using BinaryBuilder

name = "Linux"
version = v"4.15-rc2"
# Collection of sources required to build linux
sources = [
    "https://github.com/torvalds/linux/archive/v4.18.tar.gz" =>
    "c2492ea441fd95171b4def9b5a045489b28259130066aae8f07900231b2751b7",
    "./sources",
]

script = raw"""
for tool in LD AS AR CC CXX FC RANLIB READELF STRIP OBJDUMP OBJCOPY NM LIPO LIBTOOL; do
    unset ${tool}
    unset "HOST${tool}"
    unset "BUILD_${tool}"
    unset "${tool}_FOR_BUILD"
done
cd ${WORKSPACE}/srcdir/linux-*/
export PATH=/usr/bin:$PATH
mv ../linuxkernel.config arch/x86/configs/binarybuilder_defconfig
apk add gcc openssl-dev libelf-dev musl-dev bc linux-headers
make binarybuilder_defconfig
make -j${nproc}
cp vmlinux $prefix
cp arch/x86/boot/bzImage $prefix
"""

products = prefix -> [
    ExecutableProduct(joinpath(prefix, "vmlinux"), :vmlinux)
]

# These are the platforms built inside the wizard
platforms = [
    Linux(:x86_64, :glibc)
]

dependencies = [
]

# Build the given platforms using the given sources
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

