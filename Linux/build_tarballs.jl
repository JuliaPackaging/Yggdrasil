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
cd $WORKSPACE/srcdir
export PATH=/usr/bin:$PATH
cd linux-*/
mv ../linuxkernel.config arch/x86/configs/binarybuilder_defconfig
apk add libelf-dev openssl-dev libelf-dev musl-dev bc gcc linux-headers
make binarybuilder_defconfig
make -j40
cp vmlinux $prefix
cp arch/x86/boot/bzImage $prefix
"""

products = prefix -> [
    ExecutableProduct(prefix,"vmlinux", :vmlinux)
]

# These are the platforms built inside the wizard
platforms = [
    Linux(:x86_64, :glibc)
]

dependencies = []

# Build the given platforms using the given sources
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

