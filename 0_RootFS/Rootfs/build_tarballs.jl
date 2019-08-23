using Pkg, BinaryBuilder, SHA, Dates
if !isdefined(Pkg, :Artifacts)
    error("This must be run with Julia 1.3+!")
end
using Pkg.Artifacts, Pkg.PlatformEngines, Pkg.BinaryPlatforms

include("../common.jl")

# Metadata
name = "Rootfs"
version = VersionNumber("$(year(today())).$(month(today())).$(day(today()))")
verbose = "--verbose" in ARGS

# We begin by downloading the alpine rootfs and using THAT as a bootstrap rootfs.
rootfs_url = "https://github.com/gliderlabs/docker-alpine/raw/6e9a4b00609e29210ff3f545acd389bb7e89e9c0/versions/library-3.9/x86_64/rootfs.tar.xz"
rootfs_hash = "9eafcb389d03266f31ac64b4ccd9e9f42f86510811360cd4d4d6acbd519b2dc4"
mkpath(joinpath(@__DIR__, "build"))
mkpath(joinpath(@__DIR__, "products"))
rootfs_tarxz_path = joinpath(@__DIR__, "build", "rootfs.tar.xz")
download_verify(rootfs_url, rootfs_hash, rootfs_tarxz_path; verbose=verbose, force=true)

# Unpack the rootfs (using `tar` on the local machine), then pack it up again (again using tools on the local machine) and squashify it:
rootfs_extracted = joinpath(@__DIR__, "build", "rootfs_extracted")
rm(rootfs_extracted; recursive=true, force=true)
mkpath(rootfs_extracted)
success(`tar -C $(rootfs_extracted) -Jxf $(rootfs_tarxz_path)`)

# In order to launch our rootfs, we need at bare minimum, a sandbox/docker entrypoint.  Ensure those exist.
# We check in `sandbox`, but if it gets modified, we would like it to be updated.  In general, we hope
# to build it inside of BB, but in the worst case, where we've made an incompatible change and the last
# checked-in version of `sandbox` won't do, we need to be able to build it and build it now.  So if
# we're on a compatible platform, and `sandbox` is outdated, build it.
sandbox_path = joinpath(@__DIR__, "bundled", "utils", "sandbox") 
if is_outdated(sandbox_path, "$(sandbox_path).c")
    try
        build_platform = platform_key_abi(String(read(`gcc -dumpmachine`)))
        @assert isa(build_platform, Linux)
        @assert arch(build_platform) == :x86_64
        verbose && @info("Rebuilding sandbox for initial bootstrap...")
        success(`gcc -static -static-libgcc -o $(sandbox_path) $(sandbox_path).c`)
    catch
        if isfile(sandbox_path)
            @warn("Sandbox outdated and we can't build it, continuing, but be warned, initial bootstrap might fail!")
        else
            error("Sandbox missing and we can't build it!  Build it somewhere else via `gcc -static -static-libgcc -o sandbox sandbox.c`")
        end
    end
end

# Copy in `sandbox` and `docker_entrypoint.sh` since we need those just to get up in the morning.
# Also set up a DNS resolver, since that's important too.  Yes, this work is repeated below, but
# we need a tiny world to set up our slightly larger world inside of.
verbose && @info("Constructing barebones bootstrap RootFS shard...")
mkpath(joinpath(rootfs_extracted, "overlay_workdir"))
cp(sandbox_path, joinpath(rootfs_extracted, "sandbox"); force=true)
cp(joinpath(@__DIR__, "bundled", "utils", "docker_entrypoint.sh"), joinpath(rootfs_extracted, "docker_entrypoint.sh"); force=true)
open(joinpath(rootfs_extracted, "etc", "resolv.conf"), "w") do io
    for resolver in ["8.8.8.8", "8.8.4.4", "4.4.4.4", "1.1.1.1"]
        println(io, "nameserver $(resolver)")
    end
end

# we really like bash, and it's annoying to have to polymorphise, so just lie for the stage 1 bootstrap
cp(joinpath(@__DIR__, "bundled", "utils", "fake_bash.sh"), joinpath(rootfs_extracted, "bin", "bash"); force=true)
cp(joinpath(@__DIR__, "bundled", "utils", "profile"), joinpath(rootfs_extracted, "etc", "profile"); force=true)
cp(joinpath(@__DIR__, "bundled", "utils", "profile.d"), joinpath(rootfs_extracted, "etc", "profile.d"); force=true)
rootfs_unpacked_hash, rootfs_squashfs_hash = generate_artifacts(rootfs_extracted, name, version)

# Slip these barebones rootfs images into our BB install location, overwriting whatever Rootfs shard would be chosen:
verbose && @info("Binding barebones bootstrap RootFS shards...")

#cp(rootfs_targz_path,  BinaryBuilder.download_path(targz_shard); force=true)
#cp(rootfs_squash_path, BinaryBuilder.download_path(squash_shard); force=true)

# Insert them into the compiler shard hashtable.  From this point on; BB will use this shard as the RootFS shard,
# because we set `bootstrap=true`.  We also opt-out of any binutils, GCC or clang shards getting mounted.
#BinaryBuilder.shard_hash_table[targz_shard] = bytes2hex(open(SHA.sha256, rootfs_targz_path))
#BinaryBuilder.shard_hash_table[squash_shard] = bytes2hex(open(SHA.sha256, rootfs_squash_path))

insert_compiler_shard(name, version, rootfs_unpacked_hash, :unpacked)
insert_compiler_shard(name, version, rootfs_squashfs_hash, :squashfs)
Core.eval(BinaryBuilder, :(bootstrap_list = Symbol[:rootfs]))

#if verbose
#    @info("Unmounting all shards...")
#end
#BinaryBuilder.unmount.(keys(BinaryBuilder.shard_hash_table); verbose=verbose)
#rm(BinaryBuilder.mount_path(targz_shard); recursive=true, force=true)

# PHWEW.  Okay.  Now, we do some of the same steps over again, but within BinaryBuilder, where
# we can actulaly run tools inside of the rootfs (e.g. if we're building on OSX through docker)


# Sources we build from
sources = [
    "https://github.com/gliderlabs/docker-alpine/raw/6e9a4b00609e29210ff3f545acd389bb7e89e9c0/versions/library-3.9/x86_64/rootfs.tar.xz" =>
    "9eafcb389d03266f31ac64b4ccd9e9f42f86510811360cd4d4d6acbd519b2dc4",
    # Objconv is very useful
    "https://github.com/staticfloat/objconv/archive/v2.49.tar.gz" =>
    "5fcdf0eda828fbaf4b3d31ba89b5011f649df3a7ef0cc7520d08fe481cac4e9f",
    # As is patchelf
    "https://github.com/NixOS/patchelf.git" =>
    "e1e39f3639e39360ceebb2f7ed533cede4623070",
    "./bundled",
]

# Bash recipe for building across all platforms
script = raw"""
# Get build tools ready. Note that they do not pollute the eventual Rootfs image;
# they are only within this currently-running, ephemeral, pocket universe
apk add build-base curl autoconf automake linux-headers

# $prefix is our chroot under construction
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
MISC_TOOLS="python sudo file libintl patchutils grep"
FILE_TOOLS="tar zip unzip xz findutils squashfs-tools unrar rsync"
INTERACTIVE_TOOLS="bash gdb vim nano tmux strace"
BUILD_TOOLS="make patch gawk autoconf automake libtool bison flex pkgconfig cmake ninja ccache"
apk add --update --root $prefix ${NET_TOOLS} ${MISC_TOOLS} ${FILE_TOOLS} ${INTERACTIVE_TOOLS} ${BUILD_TOOLS}

# chgrp and chown should be no-ops since we run in a single-user mode
rm -f ./bin/{chown,chgrp}
touch ./bin/{chown,chgrp}
chmod +x ./bin/{chown,chgrp}

# usr/libexec/git-core takes up a LOT of space because it uses hardlinks; convert to symlinks:
echo "Replacing hardlink versions of git helper commands with symlinks..."
sha() { sha256sum "$1" | awk '{ print $1 }'; }
GIT_SHA=$(sha ./usr/libexec/git-core/git)
for f in ./usr/libexec/git-core/*; do
    if [[ -f "${f}" ]] && [[ "$(basename ${f})" != "git" ]] && [[ $(sha "${f}") == ${GIT_SHA} ]]; then
        ln -svf git "${f}"
    fi
done

# Install utilities we'll use.  Many of these are compatibility shims, look at
# the files themselves to discover why we use them.
mkdir -p ./usr/local/bin ./usr/local/share/configure_scripts
cp $WORKSPACE/srcdir/utils/tar_wrapper.sh ./usr/local/bin/tar
cp $WORKSPACE/srcdir/utils/update_configure_scripts.sh ./usr/local/bin/update_configure_scripts
cp $WORKSPACE/srcdir/utils/fake_uname.sh ./usr/local/bin/uname
cp $WORKSPACE/srcdir/utils/fake_sha512sum.sh ./usr/local/bin/sha512sum
cp $WORKSPACE/srcdir/utils/dual_libc_ldd.sh ./usr/bin/ldd
cp $WORKSPACE/srcdir/utils/atomic_patch.sh ./usr/local/bin/atomic_patch
cp $WORKSPACE/srcdir/utils/config.* ./usr/local/share/configure_scripts/
chmod +x ./usr/local/bin/*

# Deploy configuration
cp $WORKSPACE/srcdir/conf/nsswitch.conf ./etc/nsswitch.conf
cp $WORKSPACE/srcdir/utils/profile ${prefix}/etc/
cp -d $WORKSPACE/srcdir/utils/profile.d/* ${prefix}/etc/profile.d/

# Put sandbox and docker entrypoint into the root, to be used as `init` replacements.
gcc -static -static-libgcc -o ${prefix}/sandbox $WORKSPACE/srcdir/utils/sandbox.c
cp $WORKSPACE/srcdir/utils/docker_entrypoint.sh ${prefix}/docker_entrypoint.sh

# Extract a recent libstdc++.so.6 (currently the one you get from GCC 8.1.0) to /lib64
# as well so that we can run things that were built with GCC within this environment
mkdir -p ${prefix}/lib ${prefix}/lib64
cp -d $WORKSPACE/srcdir/libs/libstdc++.so* ${prefix}/lib64

# Install Glibc
cd ${WORKSPACE}/srcdir
curl -L 'https://github.com/sgerrand/docker-glibc-builder/releases/download/2.29-0/glibc-bin-2.29-0-x86_64.tar.gz' | tar zx
mv usr/glibc-compat/lib/* ${prefix}/lib

# Build/install objconv
cd ${WORKSPACE}/srcdir/objconv*/
g++ -O2 -o ${prefix}/usr/bin/objconv src/*.cpp

# Build/install patchelf
cd ${WORKSPACE}/srcdir/patchelf*/
./bootstrap.sh
./configure --prefix=${prefix}/usr
make -j${nproc}
make install

# Create mount points for future bindmounts
mkdir -p ${prefix}/overlay_workdir ${prefix}/meta


## Cleanup
# We can never extract these files, because they are too fancy  :(
rm -rf ${prefix}/usr/share/terminfo

# Cleanup .pyc/.pyo files as they're not redistributable
find ${prefix}/usr -type f -name "*.py[co]" -delete -or -type d -name "__pycache__" -delete
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [host_platform]

# The products that we will ensure are always built
products = Product[
    ExecutableProduct("sandbox", :sandbox, "./"),
    ExecutableProduct("bash", :bash),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarball
verbose && @info("Building full RootfS shard...")
build_info = build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; skip_audit=true)

# Upload the shards
upload_and_insert_shards("JuliaPackaging/Yggdrasil", name, version, build_info)
