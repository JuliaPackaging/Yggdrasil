using BinaryBuilder, SHA

name = "Rootfs"
version = v"2018.10.23"

# Sources we build from
sources = [
    "https://github.com/gliderlabs/docker-alpine/raw/d19c22b446ddcb16267f351ccbfeac5e6430720a/versions/library-3.8/x86_64/rootfs.tar.xz" =>
    "f4e9f66d945a5db78f092fcdd0c692c5b042e14897cd16c7e16d67a691d1ec82",
    "./bundled",
    "../Patchelf/products",
    "../Objconv/products",
    "../Sandbox/products",
    "../Glibc/products",
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
touch ./dev/{null,ptmx,urandom}
mkdir ./dev/{pts,shm}

## Install foundational packages within the chroot
NET_TOOLS="curl wget git openssl ca-certificates"
MISC_TOOLS="python sudo file libintl patchutils"
FILE_TOOLS="tar zip unzip xz findutils squashfs-tools unrar rsync"
INTERACTIVE_TOOLS="bash gdb vim nano tmux strace"
BUILD_TOOLS="make patch gawk autoconf automake libtool bison flex pkgconfig cmake ninja ccache"
apk add --update --root $prefix ${NET_TOOLS} ${MISC_TOOLS} ${FILE_TOOLS} ${INTERACTIVE_TOOLS} ${BUILD_TOOLS}

# chgrp and chown should be no-ops since we run in a single-user mode
rm -f ./bin/{chown,chgrp}
touch ./bin/{chown,chgrp}
chmod +x ./bin/{chown,chgrp}

# Install utilities we'll use.  Many of these are compatibility shims, look
# at the files themselves to discover why we use them.
mkdir -p ./usr/local/bin ./usr/local/share/configure_scripts
cp $WORKSPACE/srcdir/utils/tar_wrapper.sh ./usr/local/bin/tar
cp $WORKSPACE/srcdir/utils/update_configure_scripts.sh ./usr/local/bin/update_configure_scripts
cp $WORKSPACE/srcdir/utils/fake_uname.sh ./usr/local/bin/uname
cp $WORKSPACE/srcdir/utils/fake_sha512sum.sh ./usr/local/bin/sha512sum
cp $WORKSPACE/srcdir/utils/dual_libc_ldd.sh ./usr/local/bin/ldd
cp $WORKSPACE/srcdir/utils/atomic_patch.sh ./usr/local/bin/atomic_patch
cp $WORKSPACE/srcdir/utils/config.* ./usr/local/share/configure_scripts/
chmod +x ./usr/local/bin/*

# Deploy configuration
cp $WORKSPACE/srcdir/conf/nsswitch.conf ./etc/nsswitch.conf

# Include GlibcBuilder v2.25 output as our official native x86_64-linux-gnu and i686-linux-gnu loaders.
# We use 2.25 because it is the latest version that can be built with GCC 4.8.5
mkdir -p /tmp/glibc_extract ${prefix}/{lib,lib64}
tar -C /tmp/glibc_extract -zxf $WORKSPACE/srcdir/Glibc*2.25*x86_64-linux-gnu.tar.gz
tar -C /tmp/glibc_extract -zxf $WORKSPACE/srcdir/Glibc*2.25*i686-linux-gnu.tar.gz
mv /tmp/glibc_extract/x86_64-linux-gnu/sys-root/lib64/* ${prefix}/lib64/
ls -la ${prefix}/lib
mv /tmp/glibc_extract/i686-linux-gnu/sys-root/lib/* ${prefix}/lib/

# Put sandbox and our docker entrypoint script into the root, to be used as `init` replacements.
tar -C ${prefix} --strip-components=2 -xvf $WORKSPACE/srcdir/Sandbox*.tar.gz ./bin/sandbox
cp $WORKSPACE/srcdir/utils/docker_entrypoint.sh ${prefix}/docker_entrypoint.sh

# Extract a very recent libstdc++.so.6 to /lib64 as well
cp -d $WORKSPACE/srcdir/libs/libstdc++.so* $prefix/lib64

# Install patchelf, objconv, etc... to /usr/local/
tar -C ${prefix}/usr/local -xvf $WORKSPACE/srcdir/Patchelf*${target}*.tar.gz
tar -C ${prefix}/usr/local -xvf $WORKSPACE/srcdir/Objconv*${target}*.tar.gz

# Useful tools
mkdir -p ${prefix}/root
echo "alias ll='ls -la'" >> ${prefix}/root/.bashrc

# Create /overlay_workdir so that we know we can always mount an overlay there.  Same with /meta
mkdir -p ${prefix}/overlay_workdir ${prefix}/meta


## Cleanup
# We can never extract these files, because they are too fancy  :(
rm -rf ${prefix}/usr/share/terminfo

# Cleanup .pyc/.pyo files as they're not redistributable
find ${prefix}/usr -type f -name "*.py[co]" -delete -or -type d -name "__pycache__" -delete
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
