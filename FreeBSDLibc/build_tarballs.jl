using BinaryBuilder

name = "FreeBSDLibc"
version = v"11.1"

# sources to build, such as mingw32, our patches, etc....
sources = [
    "https://download.freebsd.org/ftp/releases/amd64/11.1-RELEASE/base.txz" =>
    "62acaee7e7c9df66ee2c0c2d533d1da0ddf67d32833bc4b77d935ddd9fe27dab"
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
sysroot="${prefix}/${target}/sys-root"

mkdir -p "${sysroot}"
mv usr/include "${sysroot}/"
mv usr/lib "${sysroot}/"
mv lib/* "${sysroot}/lib"
mkdir -p "${sysroot}/usr"
ln -sf "${sysroot}/include" "${sysroot}/usr/"
ln -sf "${sysroot}/lib" "${sysroot}/usr/"
ln -sf "libgcc_s.so.1" "${sysroot}/lib/libgcc_s.so"
ln -sf "libcxxrt.so.1" "${sysroot}/lib/libcxxrt.so"

# Many symlinks exist that point to `../../lib/libfoo.so`.
# We need them to point to just `libfoo.so`. :P
for f in $(find "${prefix}/${target}" -xtype l); do
	link_target="$(readlink "$f")"
	if [[ -n $(echo "${link_target}" | grep "^../../lib") ]]; then
		ln -vsf "${link_target#../../lib/}" "${f}"
	fi
done
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    FreeBSD(:x86_64),
]

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libc", :libc),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; skip_audit=true)
