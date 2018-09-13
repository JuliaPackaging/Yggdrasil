using BinaryBuilder, SHA

#if Sys.which("mksquashfs") === nothing
#    error("Must install mksquashfs!")
#end

name = "Rootfs"
version = v"2018.08.27"

# Sources we build from
sources = [
    "https://github.com/gliderlabs/docker-alpine/raw/2bfe6510ee31d86cfeb2f37587f4cf866f28ffbc/versions/library-3.8/x86_64/rootfs.tar.xz" =>
    "01970f6f0c4e9e28cf646529e85d99995cb3f35199815829a3183f52e64238c5",
    "https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.28-r0/glibc-2.28-r0.apk" =>
    "f0a00f56fdee9dc888bafec0bf8f54fb188e99b5346032251abb79ef9c99f079",
    "./bundled",
    "../Patchelf/products",
    "../Objconv/products",
    "../Sandbox/products",
]

# Bash recipe for building across all platforms
script = raw"""
# $prefix is our chroot
mv bin dev etc home lib media mnt proc root run sbin srv sys tmp usr var $prefix/
cd $prefix

# Setup DNS resolution
printf '%s\n' \
    "nameserver 8.8.8.8" \
    "nameserver 8.8.4.4" \
    "nameserver 4.4.4.4" \
    > etc/resolv.conf

# Insert system mountpoints
touch ./dev/null
touch ./dev/ptmx
touch ./dev/urandom

# Install utilities we'll use.  Many of these are compatibility shims, look
# at the files themselves to discover why we use them.
mkdir -p ./usr/local/bin ./usr/local/share/configure_scripts
cp $WORKSPACE/srcdir/utils/tar_wrapper.sh ./usr/local/bin/tar
cp $WORKSPACE/srcdir/utils/update_configure_scripts.sh ./usr/local/bin/update_configure_scripts
cp $WORKSPACE/srcdir/utils/fake_uname.sh ./usr/local/bin/uname
cp $WORKSPACE/srcdir/utils/fake_sha512sum.sh ./usr/local/bin/sha512sum
chmod +x ./usr/local/bin/*
cp $WORKSPACE/srcdir/utils/config.* ./usr/local/share/configure_scripts/
cp $WORKSPACE/srcdir/utils/docker_entrypoint.sh ./docker_entrypoint.sh

## Install foundational packages within the chroot
NET_TOOLS="curl wget git openssl ca-certificates"
MISC_TOOLS="python sudo file libintl"
FILE_TOOLS="tar zip unzip xz findutils squashfs-tools unrar"
INTERACTIVE_TOOLS="bash gdb vim nano tmux"
BUILD_TOOLS="make patch gawk autoconf automake libtool bison flex pkgconfig libstdc++ libgcc cmake ninja ccache"

apk add --update --root $prefix ${NET_TOOLS} ${MISC_TOOLS} ${FILE_TOOLS} ${INTERACTIVE_TOOLS} ${BUILD_TOOLS}

# Install glibc compatibility package
cp $WORKSPACE/srcdir/utils/sgerrand.rsa.pub $prefix/etc/apk/keys/sgerrand.rsa.pub
apk add --root $prefix $WORKSPACE/srcdir/*-glibc-*.apk

# Put sandbox as /sandbox
cd $prefix
tar --strip-components=2 -xvf $WORKSPACE/srcdir/Sandbox*.tar.gz ./bin/sandbox

# Extract a very recent libstdc++.so.6 to /usr/local/lib
cp $WORKSPACE/srcdir/libs/libstdc++.so* $prefix/usr/local/lib

# Install patchelf, objconv, etc... to /usr/local/
cd $prefix/usr/local
tar -xvf $WORKSPACE/srcdir/Patchelf*${target}*.tar.gz
tar -xvf $WORKSPACE/srcdir/Objconv*${target}*.tar.gz

# Useful tools
mkdir -p ${prefix}/root
echo "alias ll='ls -la'" >> ${prefix}/root/.bashrc

# Create /overlay_workdir so that we know we can always mount an overlay there.  Same with /meta
mkdir -p ${prefix}/overlay_workdir ${prefix}/meta

# For some reason, we can never extract these files.  :(
rm -rf ${prefix}/usr/share/terminfo
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:x86_64, :glibc)
]

# The products that we will ensure are always built
products(prefix) = Product[
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarball
build_info = build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; skip_audit=true)

# Convert all the tarballs to a .squashfs as well
#for (p, v) in build_info
#    @info("Making $(v[1]) into a squashfs archive...")
#    tarball_path = joinpath("products", v[1])
#    squash_path = joinpath("products", v[1][1:end-7] * ".squashfs")

#    temp_prefix() do p
#        # Extract the tarball into a temporary prefix, and mksquashfs it:
#        unpack(tarball_path, p.path)

#        run(`mksquashfs $(p.path) $(squash_path) -force-uid 0 -force-gid 0 -comp xz -b 1048576 -Xdict-size 100% -noappend`)

#        # Hash it to get the .sha256 file:
#        squash_hash = open(squash_path, "r") do f
#            bytes2hex(sha256(f))
#        end
#        open(squash_path * ".sha256", "w") do f
#            write(f, squash_hash)
#        end
#    end
#end
