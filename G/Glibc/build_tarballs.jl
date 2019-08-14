using BinaryBuilder

name = "Glibc"

# We have to build multiple versions of glibc because we want to use v2.12 for
# x86_64 and i686, but powerpc64le doesn't work on anything older than v2.25.
glibc_version_idx = findfirst(x -> startswith(x, "--glibc-version"), ARGS)
if glibc_version_idx == 0
    error("This is not a typical build_tarballs.jl!  Must provide glibc version; e.g. --glibc-version v2.12.2!")
end
version = VersionNumber(ARGS[glibc_version_idx+1])
deleteat!(ARGS, (glibc_version_idx, glibc_version_idx+1))

# Given a particular version, pull out the url and hash!
glibc_version_sources = Dict(
    # Oldest version for x86_64 and i686
    v"2.12.2" => [
        "https://mirrors.kernel.org/gnu/glibc/glibc-2.12.2.tar.xz" =>
        "0eb4fdf7301a59d3822194f20a2782858955291dd93be264b8b8d4d56f87203f",
    ],
    # Oldest version for arm and aarch64
    v"2.17" => [
        "https://mirrors.kernel.org/gnu/glibc/glibc-2.17.tar.xz" =>
        "6914e337401e0e0ade23694e1b2c52a5f09e4eda3270c67e7c3ba93a89b5b23e",
    ],
    # This is the version we actually use for i686, to match our buildbots
    v"2.19" => [
        "https://mirrors.kernel.org/gnu/glibc/glibc-2.19.tar.xz" =>
        "2d3997f588401ea095a0b27227b1d50cdfdd416236f6567b564549d3b46ea2a2",
    ],
    # Oldest version for ppc64le
    v"2.25" => [
        "https://mirrors.kernel.org/gnu/glibc/glibc-2.25.tar.xz" =>
        "067bd9bb3390e79aa45911537d13c3721f1d9d3769931a30c2681bfee66f23a0",
    ],
    v"2.27" => [
        "https://mirrors.kernel.org/gnu/glibc/glibc-2.27.tar.xz" =>
        "5172de54318ec0b7f2735e5a91d908afe1c9ca291fec16b5374d9faadfc1fc72",
    ],
    # Newest version available
    v"2.28" => [
        "https://mirrors.kernel.org/gnu/glibc/glibc-2.28.tar.xz" =>
        "b1900051afad76f7a4f73e71413df4826dce085ef8ddb785a945b66d7d513082",
    ],
)

# sources to build, such as glibc, linux kernel headers, our patches, etc....
sources = [
    glibc_version_sources[version]...,
    "patches",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/glibc-*/

# We need newer configure scripts
#update_configure_scripts

# patch glibc to keep around libgcc_s_resume on arm
# ref: https://sourceware.org/ml/libc-alpha/2014-05/msg00573.html
atomic_patch -p1 $WORKSPACE/srcdir/patches/glibc_arm_gcc_fix.patch || true

# patch glibc's stupid gcc version check (we don't require this one, as if
# it doesn't apply cleanly, it's probably fine)
atomic_patch -p0 $WORKSPACE/srcdir/patches/glibc_gcc_version.patch || true
atomic_patch -p1 $WORKSPACE/srcdir/patches/glibc_make_version.patch || true

# patch older glibc's 32-bit assembly to withstand __i686 definition of
# newer GCC's.  ref: http://comments.gmane.org/gmane.comp.lib.glibc.user/758
atomic_patch -p1 $WORKSPACE/srcdir/patches/glibc_i686_asm.patch || true

# Patch glibc's sunrpc cross generator to work with musl
# See https://sourceware.org/bugzilla/show_bug.cgi?id=21604
atomic_patch -p0 $WORKSPACE/srcdir/patches/glibc-sunrpc.patch || true

# patch for building old glibc on newer binutils
# These patches don't apply on those versions of glibc where they
# are not needed, but that's ok.
atomic_patch -p0 $WORKSPACE/srcdir/patches/glibc_nocommon.patch || true
atomic_patch -p0 $WORKSPACE/srcdir/patches/glibc_regexp_nocommon.patch || true

# patch for avoiding linking in musl libs for a glibc-linked binary
atomic_patch -p1 $WORKSPACE/srcdir/patches/glibc_musl_rejection.patch || true
atomic_patch -p1 $WORKSPACE/srcdir/patches/glibc_musl_rejection_old.patch || true

sysroot=${prefix}/${target}/sys-root

mkdir -p $WORKSPACE/srcdir/glibc_build
cd $WORKSPACE/srcdir/glibc_build
$WORKSPACE/srcdir/glibc-*/configure --prefix=/usr \
	--host=${target} \
	--with-headers="${sysroot}/usr/include" \
	--disable-multilib \
	--disable-werror \
	libc_cv_forced_unwind=yes \
	libc_cv_c_cleanup=yes

make -j${nproc}

# Install to the main prefix and also to the sysroot.
make install install_root=${sysroot}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, :glibc),
    Linux(:x86_64, :glibc),
]

# The earliest ARM version we support is v2.17
if version >= v"2.17"
	push!(platforms, Linux(:aarch64, :glibc))
	push!(platforms, Linux(:armv7l, :glibc))
end

# The earlest powerpc64le version we support is v2.25
if version >= v"2.25"
    push!(platforms, Linux(:powerpc64le, :glibc))
end


# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libc", :glibc),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "https://github.com/staticfloat/KernelHeadersBuilder/releases/download/v4.12.0-0/build_KernelHeaders.v4.12.0.jl",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; skip_audit=true)
