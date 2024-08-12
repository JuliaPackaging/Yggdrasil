### Instructions for adding a new version
#
# * Update the bits you want to update, for example:
#   * version of the Alpine RootFS: visit https://github.com/alpinelinux/docker-alpine,
#     select the branch corresponding to the version of Alpine you want to use, browse to
#     the directory `x86_64` and obtain the permanent link of the image (press `Y`).  NOTE:
#     if you upgrade version of Alpine Linux, makes sure to use the same version of Musl
#     libc as upstream (see below), otherwise system applications may not work
#   * version of Meson (https://github.com/mesonbuild/meson/releases)
#   * version of patchelf (https://github.com/NixOS/patchelf/releases/)
#   * version of CSL in `bundled/libs/csl/download_csls.sh`
#     (https://github.com/JuliaBinaryWrappers/CompilerSupportLibraries_jll.jl/releases)
#   * version of C libraries in `bundled/libs/libc/download_libcs.sh`
#     (https://github.com/JuliaBinaryWrappers/Musl_jll.jl/releases and
#     https://github.com/JuliaBinaryWrappers/Glibc_jll.jl/releases)
#   * etc...
# * to build and deploy the new image:
#
#     - Ensure you are using the development version of `BinaryBuilderBase`:
#         `]develop BinaryBuilderBase`
#       Also ensure you are at the tip of the `master` branch.
#     - Run: `julia build_tarballs.jl --debug --verbose --deploy`
#     - This will update the file `Artifacts.toml` in `BinaryBuilderBase`.
#       Create a pull request for these changes.

using Pkg, BinaryBuilder, SHA, Dates
if !isdefined(Pkg, :Artifacts)
    error("This must be run with Julia 1.3+!")
end
using Pkg.Artifacts, Pkg.PlatformEngines

include("../common.jl")

# Metadata
name = "Rootfs"
version = VersionNumber("$(year(today())).$(month(today())).$(day(today()))")
verbose = "--verbose" in ARGS

# We begin by downloading the alpine rootfs and using THAT as a bootstrap rootfs.
rootfs_url = "https://github.com/alpinelinux/docker-alpine/raw/818c831891a18d2453ad6458011ea8cbff74d0e1/x86_64/alpine-minirootfs-3.15.0-x86_64.tar.gz"
rootfs_hash = "ec7ec80a96500f13c189a6125f2dbe8600ef593b87fc4670fe959dc02db727a2"
mkpath(joinpath(@__DIR__, "build"))
mkpath(joinpath(@__DIR__, "products"))
rootfs_targz_path = joinpath(@__DIR__, "build", "rootfs.tar.gz")
Pkg.PlatformEngines.download_verify(rootfs_url, rootfs_hash, rootfs_targz_path; verbose=verbose, force=true)

# Unpack the rootfs (using `tar` on the local machine), then pack it up again (again using tools on the local machine) and squashify it:
rootfs_extracted = joinpath(@__DIR__, "build", "rootfs_extracted")
rm(rootfs_extracted; recursive=true, force=true)
mkpath(rootfs_extracted)
success(`tar -C $(rootfs_extracted) -zxf $(rootfs_targz_path)`)

# In order to launch our rootfs, we need at bare minimum, a sandbox/docker entrypoint.  Ensure those exist.
# We check in `sandbox`, but if it gets modified, we would like it to be updated.  In general, we hope
# to build it inside of BB, but in the worst case, where we've made an incompatible change and the last
# checked-in version of `sandbox` won't do, we need to be able to build it and build it now.  So if
# we're on a compatible platform, and `sandbox` is outdated, build it.
sandbox_path = joinpath(@__DIR__, "bundled", "utils", "sandbox") 
if is_outdated(sandbox_path, "$(sandbox_path).c")
    try
        build_platform = platform_key_abi(String(read(`gcc -dumpmachine`)))
        @assert Sys.islinux(build_platform)
        @assert arch(build_platform) == :x86_64
        verbose && @info("Rebuilding sandbox for initial bootstrap...")
        success(`gcc -O2 -static -static-libgcc -o $(sandbox_path) $(sandbox_path).c`)
    catch
        if isfile(sandbox_path)
            @warn("Sandbox outdated and we can't build it, continuing, but be warned, initial bootstrap might fail!")
        else
            error("Sandbox missing and we can't build it!  Build it somewhere else via `gcc -O2 -static -static-libgcc -o sandbox sandbox.c`")
        end
    end
end
libc_paths = [joinpath(@__DIR__, "bundled", "libs", "libc", "$(libc)-$(arch)") for libc in ("musl", "glibc") for arch in ("i686", "x86_64")]
download_libcs = joinpath(@__DIR__, "bundled", "libs", "libc", "download_libcs.sh")
if any(is_outdated.(libc_paths, download_libcs))
    success(`$download_libcs`)
end

csl_paths = [joinpath(@__DIR__, "bundled", "libs", "csl", "$(libc)-$(arch)") for libc in ("musl", "glibc") for arch in ("i686", "x86_64")]
download_csls = joinpath(@__DIR__, "bundled", "libs", "csl", "download_csls.sh")
if any(is_outdated.(csl_paths, download_csls))
    success(`$download_csls`)
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
cp(joinpath(@__DIR__, "bundled", "conf", "profile"), joinpath(rootfs_extracted, "etc", "profile"); force=true)
cp(joinpath(@__DIR__, "bundled", "conf", "profile.d"), joinpath(rootfs_extracted, "etc", "profile.d"); force=true)
rootfs_unpacked_hash, rootfs_squashfs_hash = generate_artifacts(rootfs_extracted, name, version)

# Slip these barebones rootfs images into our BB install location, overwriting whatever Rootfs shard would be chosen:
verbose && @info("Binding barebones bootstrap RootFS shards...")

insert_compiler_shard(name, version, rootfs_unpacked_hash, :unpacked)
insert_compiler_shard(name, version, rootfs_squashfs_hash, :squashfs)
@eval BinaryBuilder.BinaryBuilderBase empty!(bootstrap_list)
@eval BinaryBuilder.BinaryBuilderBase push!(bootstrap_list, :rootfs)

# PHWEW.  Okay.  Now, we do some of the same steps over again, but within BinaryBuilder, where
# we can actulaly run tools inside of the rootfs (e.g. if we're building on OSX through docker)


# Sources we build from
sources = [
    ArchiveSource(rootfs_url, rootfs_hash),
    # Objconv is very useful
    GitSource("https://github.com/staticfloat/objconv.git",
              "c68e441d2b93074b01ea193cb17e944ed751750f"), # v2.54
    # As is patchelf
    # We don't want to upgrade patchelf unless there's a compelling and proved reason
    # to do it because of previous problems we experienced with v0.18.0.
    # We encountered the error "ELF load command address/offset not properly aligned" in #7728 and #7729.
    GitSource("https://github.com/NixOS/patchelf.git",
              "bf3f37ec29edcdb3e2a163edaf84aeece39f8c9d"), # v0.14.3
    # We need a very recent version of meson to build gtk stuffs, so let's just grab the latest
    GitSource("https://github.com/mesonbuild/meson.git",
              "eaefe29463a61a311a6b1de6cd539f39500399ff"), # v1.4.0
    # We're going to bundle a version of `ldid` into the rootfs for now.  When we split this up,
    # we'll do this in a nicer way by using JLLs directly, but until then, this is what we've got.
    ArchiveSource("https://github.com/JuliaBinaryWrappers/ldid_jll.jl/releases/download/ldid-v2.1.3%2B0/ldid.v2.1.3.x86_64-linux-musl-cxx11.tar.gz",
                  "d37c2a8f5bfb75c6a4b9fafb97160c8065e1281b9fe85ac51557fe490edad142",
                  unpack_target="ldid"),
    ArchiveSource("https://github.com/JuliaBinaryWrappers/libplist_jll.jl/releases/download/libplist-v2.2.1%2B0/libplist.v2.2.1.x86_64-linux-musl-cxx11.tar.gz",
                  "f881818f288d3a82a1ca98e4a011f44289f2bc8c1ba8cfdafe4f1690af0cf4ae",
                  unpack_target="ldid"),
    # And also our own local patches, utilities, etc...
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
set -x
# Get build tools ready. Note that they do not pollute the eventual Rootfs image;
# they are only within this currently-running, ephemeral, pocket universe
apk add build-base curl autoconf automake linux-headers gawk python3 py3-setuptools bison git

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
touch ./dev/null
touch ./dev/ptmx
touch ./dev/urandom
mkdir ./dev/pts
mkdir ./dev/shm

## Install foundational packages within the chroot
NET_TOOLS="curl wget git openssl ca-certificates"
MISC_TOOLS="python2 python3 py3-pip sudo file libintl patchutils grep zlib"
FILE_TOOLS="tar zip unzip xz findutils squashfs-tools rsync" # TODO: restore `unrar` when it comes back to Alpine Linux
INTERACTIVE_TOOLS="bash gdb vim nano tmux strace"
BUILD_TOOLS="make patch gawk autoconf automake libtool bison flex pkgconfig cmake samurai ccache"
apk add --update --root $prefix ${NET_TOOLS} ${MISC_TOOLS} ${FILE_TOOLS} ${INTERACTIVE_TOOLS} ${BUILD_TOOLS}

# chgrp and chown should be no-ops since we run in a single-user mode
rm -f ./bin/chown ./bin/chgrp
touch ./bin/chown ./bin/chgrp
chmod +x ./bin/chown ./bin/chgrp

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
cp -vd ${WORKSPACE}/srcdir/utils/tar_wrapper.sh ./usr/local/bin/tar
cp -vd ${WORKSPACE}/srcdir/utils/update_configure_scripts.sh ./usr/local/bin/update_configure_scripts
cp -vd ${WORKSPACE}/srcdir/utils/flagon ./usr/local/bin/flagon
cp -vd ${WORKSPACE}/srcdir/utils/fake_uname.sh ./usr/bin/uname
cp -vd ${WORKSPACE}/srcdir/utils/apk_wrapper.sh ./usr/local/bin/apk
mv ./sbin/sysctl ./sbin/_sysctl
cp -vd ${WORKSPACE}/srcdir/utils/fake_sysctl.sh ./sbin/sysctl
cp -vd ${WORKSPACE}/srcdir/utils/fake_sha512sum.sh ./usr/local/bin/sha512sum
cp -vd ${WORKSPACE}/srcdir/utils/dual_libc_ldd.sh ./usr/bin/ldd
cp -vd ${WORKSPACE}/srcdir/utils/atomic_patch.sh ./usr/local/bin/atomic_patch
cp -vd ${WORKSPACE}/srcdir/utils/install_license.sh ./usr/local/bin/install_license
cp -vd ${WORKSPACE}/srcdir/utils/replace_includes.sh ./usr/local/bin/replace_includes
cp -vd ${WORKSPACE}/srcdir/utils/config.* ./usr/local/share/configure_scripts/
cp -vd ${WORKSPACE}/srcdir/ldid/bin/* ./usr/local/bin/
cp -vdr ${WORKSPACE}/srcdir/ldid/lib/* ./usr/local/lib/
chmod +x ./usr/local/bin/*

# Deploy configuration
cp -vd ${WORKSPACE}/srcdir/conf/nsswitch.conf ./etc/nsswitch.conf

# Clear out all previous profile stuff first
rm -f ${prefix}/etc/profile.d/*
cp -vd ${WORKSPACE}/srcdir/conf/profile ${prefix}/etc/
cp -vd ${WORKSPACE}/srcdir/conf/profile.d/* ${prefix}/etc/profile.d/

# Install vim configuration/.vimrc
cp -vd ${WORKSPACE}/srcdir/conf/vimrc ${prefix}/etc/vim/vimrc
mkdir -p ${prefix}/etc/vim/
git clone https://github.com/VundleVim/Vundle.vim ${prefix}/etc/vim/bundle/Vundle.vim
chroot ${prefix} vim -E -u /etc/vim/vimrc -c PluginInstall -c qall
find ${prefix}/etc/vim/bundle -name \*.git | xargs rm -rf

# Put sandbox and docker entrypoint into the root, to be used as `init` replacements.
gcc -g -O2 -static -static-libgcc -o ${prefix}/sandbox $WORKSPACE/srcdir/utils/sandbox.c
cp -vd ${WORKSPACE}/srcdir/utils/docker_entrypoint.sh ${prefix}/docker_entrypoint.sh

# Build the BB service client
gcc -O2 -std=c99 -static -static-libgcc -o ${prefix}/bin/bb $WORKSPACE/srcdir/utils/bb.c

# Move over libc loaders from our bundled directory.  These have very strict location requirements,
# so they MUST exist in /lib and /lib64.  These were generated from the `Glibc` and `Musl` builders
# in this Rootfs directory.  Note that `musl` always goes to `/lib`, not `/lib64`
mkdir -p ${prefix}/lib64 ${prefix}/lib
cp -vd ${WORKSPACE}/srcdir/libs/libc/glibc-x86_64/* ${prefix}/lib64
cp -vd ${WORKSPACE}/srcdir/libs/libc/glibc-i686/* ${prefix}/lib
cp -vd ${WORKSPACE}/srcdir/libs/libc/musl-x86_64/* ${prefix}/lib
cp -vd ${WORKSPACE}/srcdir/libs/libc/musl-i686/* ${prefix}/lib

# Move over Compiler Support Libraries from our bundled directory into separate directories.
# These do not have strict location requirements, so we just store them in descriptive folders
# and BB will add them to `LD_LIBRARY_PATH`.
for arch in x86_64 i686; do
    for libc in glibc musl; do
        mkdir -p ${prefix}/usr/lib/csl-${libc}-${arch}
        cp -vd ${WORKSPACE}/srcdir/libs/csl/${libc}-${arch}/* ${prefix}/usr/lib/csl-${libc}-${arch}
    done
done

# Build/install meson
cd ${WORKSPACE}/srcdir/meson
python3 setup.py build
python3 setup.py install --prefix=/usr --root="${prefix}"

# Build/install objconv
cd ${WORKSPACE}/srcdir/objconv/
g++ -O2 -o ${prefix}/usr/bin/objconv src/*.cpp

# Build/install patchelf
cd ${WORKSPACE}/srcdir/patchelf/
./bootstrap.sh
./configure --prefix=${prefix}/usr
make -j${nproc}
make install

# Create mount points for future bindmounts
mkdir -p ${prefix}/overlay_workdir ${prefix}/meta

# Sneak some test suites into the build environment, so we can do sanity checks easily
cp -vdR ${WORKSPACE}/srcdir/testsuite ${prefix}/usr/share/

# Add some licenses for quick-and-dirty licensing
cp -vdR ${WORKSPACE}/srcdir/licenses ${prefix}/usr/share/

## Cleanup
# We can never extract these files, because they are too fancy  :(
rm -rf ${prefix}/usr/share/terminfo

# These cause case sensitivity errors
rm -rf ${prefix}/usr/share/perl5/core_perl/pod
rm -rf ${prefix}/etc/vim/bundle/vim-colorschemes/colors/darkBlue.vim

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
ndARGS, deploy_target = find_deploy_arg(ARGS)
build_info = build_tarballs(ndARGS, name, version, sources, script, platforms, products, dependencies; skip_audit=true)
if deploy_target !== nothing
    upload_and_insert_shards(deploy_target, name, version, build_info)
end
