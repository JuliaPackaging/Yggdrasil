using BinaryBuilder, HTTP
#import Sockets

name = "GCC"

# We'll build this version of GCC
version_idx = findfirst(x -> startswith(x, "--gcc-version"), ARGS)
if version_idx == nothing
    error("This is not a typical build_tarballs.jl!  Must provide gcc version; e.g. --gcc-version 7.3.0")
end
version = VersionNumber(ARGS[version_idx+1])
deleteat!(ARGS, (version_idx, version_idx+1))

compiler_target = triplet(platform_key(ARGS[end]))
if compiler_target == "unknown-unknown-unknown"
    error("This is not a typical build_tarballs.jl!  Must provide exactly one platform as the last argument!")
end

# Since we can build a variety of GCC versions, track them and their hashes here.
# We download GCC, MPFR, MPC, ISL and GMP.
gcc_version_sources = Dict(
    v"4.8.5" => [
        "https://mirrors.kernel.org/gnu/gcc/gcc-4.8.5/gcc-4.8.5.tar.bz2" =>
        "22fb1e7e0f68a63cee631d85b20461d1ea6bda162f03096350e38c8d427ecf23",
        "https://mirrors.kernel.org/gnu/mpfr/mpfr-2.4.2.tar.xz" =>
        "d7271bbfbc9ddf387d3919df8318cd7192c67b232919bfa1cb3202d07843da1b",
        "https://gcc.gnu.org/pub/gcc/infrastructure/mpc-0.8.1.tar.gz" =>
        "e664603757251fd8a352848276497a4c79b7f8b21fd8aedd5cc0598a38fee3e4",
        "https://mirrors.kernel.org/gnu/gmp/gmp-4.3.2.tar.bz2" =>
        "936162c0312886c21581002b79932829aa048cfaf9937c6265aeaa14f1cd1775",
    ],
    v"4.9.4" => [
        "https://mirrors.kernel.org/gnu/gcc/gcc-4.9.4/gcc-4.9.4.tar.bz2" =>
        "6c11d292cd01b294f9f84c9a59c230d80e9e4a47e5c6355f046bb36d4f358092",
        "https://mirrors.kernel.org/gnu/mpfr/mpfr-2.4.2.tar.xz" =>
        "d7271bbfbc9ddf387d3919df8318cd7192c67b232919bfa1cb3202d07843da1b",
        "https://gcc.gnu.org/pub/gcc/infrastructure/mpc-0.8.1.tar.gz" =>
        "e664603757251fd8a352848276497a4c79b7f8b21fd8aedd5cc0598a38fee3e4",
        "https://mirrors.kernel.org/gnu/gmp/gmp-4.3.2.tar.bz2" =>
        "936162c0312886c21581002b79932829aa048cfaf9937c6265aeaa14f1cd1775",
        "https://gcc.gnu.org/pub/gcc/infrastructure/isl-0.12.2.tar.bz2" =>
        "f4b3dbee9712850006e44f0db2103441ab3d13b406f77996d1df19ee89d11fb4",
        "https://gcc.gnu.org/pub/gcc/infrastructure/cloog-0.18.1.tar.gz" =>
        "02500a4edd14875f94fe84cbeda4290425cb0c1c2474c6f75d75a303d64b4196",
    ],
    v"6.1.0" => [
        "https://mirrors.kernel.org/gnu/gcc/gcc-6.1.0/gcc-6.1.0.tar.bz2" =>
        "09c4c85cabebb971b1de732a0219609f93fc0af5f86f6e437fd8d7f832f1a351",
        "https://mirrors.kernel.org/gnu/mpfr/mpfr-2.4.2.tar.xz" =>
        "d7271bbfbc9ddf387d3919df8318cd7192c67b232919bfa1cb3202d07843da1b",
        "https://gcc.gnu.org/pub/gcc/infrastructure/mpc-0.8.1.tar.gz" =>
        "e664603757251fd8a352848276497a4c79b7f8b21fd8aedd5cc0598a38fee3e4",
        "https://mirrors.kernel.org/gnu/gmp/gmp-4.3.2.tar.bz2" =>
        "936162c0312886c21581002b79932829aa048cfaf9937c6265aeaa14f1cd1775",
        "https://gcc.gnu.org/pub/gcc/infrastructure/isl-0.15.tar.bz2" =>
        "8ceebbf4d9a81afa2b4449113cee4b7cb14a687d7a549a963deb5e2a41458b6b",
    ],
    v"6.4.0" => [
        "https://mirrors.kernel.org/gnu/gcc/gcc-6.4.0/gcc-6.4.0.tar.xz" =>
        "850bf21eafdfe5cd5f6827148184c08c4a0852a37ccf36ce69855334d2c914d4",
        "https://mirrors.kernel.org/gnu/mpfr/mpfr-2.4.2.tar.xz" =>
        "d7271bbfbc9ddf387d3919df8318cd7192c67b232919bfa1cb3202d07843da1b",
        "https://gcc.gnu.org/pub/gcc/infrastructure/mpc-0.8.1.tar.gz" =>
        "e664603757251fd8a352848276497a4c79b7f8b21fd8aedd5cc0598a38fee3e4",
        "https://mirrors.kernel.org/gnu/gmp/gmp-4.3.2.tar.bz2" =>
        "936162c0312886c21581002b79932829aa048cfaf9937c6265aeaa14f1cd1775",
        "https://gcc.gnu.org/pub/gcc/infrastructure/isl-0.15.tar.bz2" =>
        "8ceebbf4d9a81afa2b4449113cee4b7cb14a687d7a549a963deb5e2a41458b6b",
    ],
    v"7.1.0" => [
        "https://mirrors.kernel.org/gnu/gcc/gcc-7.1.0/gcc-7.1.0.tar.bz2" =>
        "8a8136c235f64c6fef69cac0d73a46a1a09bb250776a050aec8f9fc880bebc17",
        "https://mirrors.kernel.org/gnu/mpfr/mpfr-3.1.4.tar.xz" =>
        "761413b16d749c53e2bfd2b1dfaa3b027b0e793e404b90b5fbaeef60af6517f5",
        "https://mirrors.kernel.org/gnu/mpc/mpc-1.0.3.tar.gz" =>
        "617decc6ea09889fb08ede330917a00b16809b8db88c29c31bfbb49cbf88ecc3",
        "https://gcc.gnu.org/pub/gcc/infrastructure/isl-0.16.1.tar.bz2" =>
        "412538bb65c799ac98e17e8cfcdacbb257a57362acfaaff254b0fcae970126d2",
        "https://mirrors.kernel.org/gnu/gmp/gmp-6.1.0.tar.xz" =>
        "68dadacce515b0f8a54f510edf07c1b636492bcdb8e8d54c56eb216225d16989",
    ],
    v"7.3.0" => [
        "https://mirrors.kernel.org/gnu/gcc/gcc-7.3.0/gcc-7.3.0.tar.xz" =>
        "832ca6ae04636adbb430e865a1451adf6979ab44ca1c8374f61fba65645ce15c",
        "https://mirrors.kernel.org/gnu/mpfr/mpfr-3.1.4.tar.xz" =>
        "761413b16d749c53e2bfd2b1dfaa3b027b0e793e404b90b5fbaeef60af6517f5",
        "https://mirrors.kernel.org/gnu/mpc/mpc-1.0.3.tar.gz" =>
        "617decc6ea09889fb08ede330917a00b16809b8db88c29c31bfbb49cbf88ecc3",
        "https://gcc.gnu.org/pub/gcc/infrastructure/isl-0.16.1.tar.bz2" =>
        "412538bb65c799ac98e17e8cfcdacbb257a57362acfaaff254b0fcae970126d2",
        "https://mirrors.kernel.org/gnu/gmp/gmp-6.1.0.tar.xz" =>
        "68dadacce515b0f8a54f510edf07c1b636492bcdb8e8d54c56eb216225d16989",
    ],
    v"8.1.0" => [
        "https://mirrors.kernel.org/gnu/gcc/gcc-8.1.0/gcc-8.1.0.tar.xz" =>
        "1d1866f992626e61349a1ccd0b8d5253816222cdc13390dcfaa74b093aa2b153",
        "https://mirrors.kernel.org/gnu/mpfr/mpfr-4.0.1.tar.xz" =>
        "67874a60826303ee2fb6affc6dc0ddd3e749e9bfcb4c8655e3953d0458a6e16e",
        "https://mirrors.kernel.org/gnu/mpc/mpc-1.1.0.tar.gz" =>
        "6985c538143c1208dcb1ac42cedad6ff52e267b47e5f970183a3e75125b43c2e",
        "https://gcc.gnu.org/pub/gcc/infrastructure/isl-0.18.tar.bz2" =>
        "6b8b0fd7f81d0a957beb3679c81bbb34ccc7568d5682844d8924424a0dadcb1b",
        "https://mirrors.kernel.org/gnu/gmp/gmp-6.1.2.tar.xz" =>
        "87b565e89a9a684fe4ebeeddb8399dce2599f9c9049854ca8c0dfbdea0e21912",
    ],
)

# Collection of sources required to build GCC
sources = [
    gcc_version_sources[version]...,
    "./patches",
]


# Dependencies that must be installed before this package can be built
dependencies = Any[
    # We need us some libz goodness
    "https://github.com/bicycle1885/ZlibBuilder/releases/download/v1.0.1/build_Zlib.v1.2.11.jl",
]

# If we're on a -gnu target, we require glibc as well, but the minimum version of glibc
# we require is informed by the target arch
glibc_version = "none"
if occursin("-gnu", compiler_target)
    glibc_arch_version = Dict(
        :x86_64 => v"2.12.2",
        :i686 => v"2.12.2",
        :aarch64 => v"2.17",
        :armv7l => v"2.17",
        :powerpc64le => v"2.25",
    )
    compiler_target_arch = arch(platform_key(compiler_target))
    glibc_version = glibc_arch_version[compiler_target_arch]

    push!(dependencies, "https://github.com/staticfloat/GlibcBuilder/releases/download/v2.27-3/build_Glibc.v$(glibc_version).jl")
end

if occursin("-musl", compiler_target)
    push!(dependencies, "https://github.com/staticfloat/MuslBuilder/releases/download/v1.1.19-0/build_Musl.v1.1.19.jl")
end

if occursin("-mingw", compiler_target)
    push!(dependencies, "https://github.com/staticfloat/MingwBuilder/releases/download/v5.0.4-2/build_Mingw32.v5.0.4.jl")
end

if occursin("-freebsd", compiler_target)
    push!(dependencies, "https://github.com/staticfloat/FreeBSDLibcBuilder/releases/download/v11.1-0/build_FreeBSDLibc.v11.1.0.jl")
end

# Bash recipe for building across all platforms
script = """
cd \$WORKSPACE/srcdir/gcc-*/

# Temporary measure until we get a new rootfs
apk add patchutils

# Patch has the almost unbelievable failure mode that it will partially apply
# a patch.  This is really bad if you want to just ignore patch return codes,
# so what we do is we build a new atomic_patch() function that will apply a
# patch if (and only if) the whole thing applies cleanly.
atomic_patch()
{
    if ! patch -f -N -p1 < "\$1"; then
        echo "Patch \$(basename "\$1") could not be applied! Reverting and skipping..." >&2
        for f in \$(lsdiff --strip 1 "\$1"); do
            if [[ -f "\${f}.orig" ]]; then
                mv -v "\${f}.orig" "\${f}"
            fi
        done
    fi
}

# Link dependent packages into gcc build root:
for proj in mpfr mpc isl gmp; do
    if [[ -d \$(echo ../\${proj}-*) ]]; then
        mv ../\${proj}-* \${proj}
    fi
done

# Do not run fixincludes
sed -i 's@\\./fixinc\\.sh@-c true@' gcc/Makefile.in

# Update configure scripts
update_configure_scripts

# Apply patch for OSX linker crash problems
atomic_patch "\${WORKSPACE}/srcdir/patches/gcc810_linker_madness_on_osx.patch"
atomic_patch "\${WORKSPACE}/srcdir/patches/gcc610_ubsan_pointer.patch"

# Musl compatibility
atomic_patch "\${WORKSPACE}/srcdir/patches/gcc485_header_upgrades.patch"
atomic_patch "\${WORKSPACE}/srcdir/patches/gcc494_musl.patch"

# Apply patch to build the 4.8.x line with newer GCC's
atomic_patch "\${WORKSPACE}/srcdir/patches/gcc485_libc_name_p.patch"

# Redirect compiler variables
export MACHTYPE=x86_64-linux-gnu
export CC_FOR_TARGET=\$CC
export CXX_FOR_TARGET=\$CXX
export GFORTRAN_FOR_TARGET=\$FC
export CC=\$HOSTCC
export CXX=\$HOSTCXX
export FC=\$HOSTFC

# Choose compiler target
COMPILER_TARGET="$(compiler_target)"

# Default sysroot for all platforms (except OSX.  sigh.)
sysroot="\${prefix}/\${COMPILER_TARGET}/sys-root"

# Build up optional configuration args
GCC_CONF_ARGS=""

## Platform-dependent arguments
# On OSX, we need to use special `ld` and `as`.  We also want to be able to build obj-c/c++
if [[ "\$COMPILER_TARGET" == *apple* ]]; then
    # Un-do binary builder's typical `LD` and `AS` overrides
    export LD=\$(which \${COMPILER_TARGET}-ld)
    unset LDFLAGS
    export AS=\$(which \${COMPILER_TARGET}-as)

    GCC_CONF_ARGS="\${GCC_CONF_ARGS} --with-ld=\"\${LD}\""
    GCC_CONF_ARGS="\${GCC_CONF_ARGS} --with-as=\${AS}"
	GCC_CONF_ARGS="\${GCC_CONF_ARGS} --enable-languages=c,c++,fortran,objc,obj-c++"

# On Linux, we just enable C/C++/Fortran    
elif [[ "\${COMPILER_TARGET}" == *linux* ]]; then
	GCC_CONF_ARGS="\${GCC_CONF_ARGS} --enable-languages=c,c++,fortran"

# FreeBSD has weird PIE problems.  We can also only build gfortran for now, no GCC :(
elif [[ "\${COMPILER_TARGET}" == *freebsd* ]]; then
    GCC_CONF_ARGS="\${GCC_CONF_ARGS} --enable-languages=fortran"
	GCC_CONF_ARGS="\${GCC_CONF_ARGS} --disable-default-pie"
    
# On mingw32 override native system header directories    
elif [[ "\${COMPILER_TARGET}" == *mingw* ]]; then
	GCC_CONF_ARGS="\${GCC_CONF_ARGS} --enable-languages=c,c++,fortran"
    GCC_CONF_ARGS="\${GCC_CONF_ARGS} --with-native-system-header-dir=/include"

    # We also need to symlink our lib directory specially
    ln -s sys-root/lib \${prefix}/\${COMPILER_TARGET}/lib
fi


## Architecture-dependent arguments
# On arm*hf targets, pass --with-float=hard explicitly, and choose a default arch.
if [[ "\${COMPILER_TARGET}" == arm*hf ]]; then
	GCC_CONF_ARGS="\${GCC_CONF_ARGS} --with-float=hard --with-arch=armv7-a --with-fpu=vfpv3-d16"
fi

## Libc-dependent arguments
# On gnu targets, pass --with-glibc-version
if [[ "\${COMPILER_TARGET}" == *-gnu* ]]; then
    GCC_CONF_ARGS="\${GCC_CONF_ARGS} --with-glibc-version=\$(echo "$glibc_version" | cut -d '.' -f 1-2)"
    
# On musl targets, disable a bunch of things we don't want
elif [[ "\${COMPILER_TARGET}" == *musl* ]]; then
	GCC_CONF_ARGS="\${GCC_CONF_ARGS} --disable-libssp --disable-libmpx"
	GCC_CONF_ARGS="\${GCC_CONF_ARGS} --disable-libmudflap --disable-libsanitizer"
	GCC_CONF_ARGS="\${GCC_CONF_ARGS} --disable-symvers"
	export libat_cv_have_ifunc=no
	export ac_cv_have_decl__builtin_ffs=yes
fi

# On many platforms (Glibc, mingw32, etc...) we need to symlink sys-include
if [[ -d \${prefix}/\${COMPILER_TARGET}/sys-root/include ]]; then
    ln -s sys-root/include \${prefix}/\${COMPILER_TARGET}/sys-include
fi

# GCC won't build (crti.o: no such file or directory) unless these directories exist.
# They can be empty though.
mkdir -p \${prefix}/\${COMPILER_TARGET}/sys-root/{lib,usr/lib}

# Build in a separate directory
mkdir -p \$WORKSPACE/srcdir/gcc_build
cd \$WORKSPACE/srcdir/gcc_build

# Configure GCC (Don't need to bootstrap as we already have glibc installed)
\$WORKSPACE/srcdir/gcc-*/configure \\
	--prefix="\${prefix}" \\
    --target="\${COMPILER_TARGET}" \\
	--host="\${MACHTYPE}" \\
	--build="\${MACHTYPE}" \\
	--disable-multilib \\
	--disable-werror \\
	--enable-host-shared \\
	--enable-threads=posix \\
    --disable-bootstrap \\
    --with-sysroot="\${sysroot}" \\
	\${GCC_CONF_ARGS}

# Build, build, build!
make -j \$((\${nproc}+1))
make install

# Cleanup our manually made symlink from above
rm -f \${prefix}/\${COMPILER_TARGET}/sys-include

# This is needed for any glibc older than 2.14, which includes the following commit
# https://sourceware.org/git/?p=glibc.git;a=commit;h=95f5a9a866695da4e038aa4e6ccbbfd5d9cf63b7
ln -vs libgcc.a \$(\${COMPILER_TARGET}-gcc -print-libgcc-file-name | sed 's/libgcc/&_eh/') || true

# Finally, create a bunch of symlinks stripping out the target so that
# things like `gcc` "just work", as long as we've got our path set properly
# We don't worry about failure to create these symlinks, as sometimes there are files
# named ridiculous things like \${COMPILER_TARGET}-\${COMPILER_TARGET}-foo, which screws this up
for f in \${prefix}/bin/\${COMPILER_TARGET}-*; do
    fbase=\$(basename \$f)
    ln -s \$f "\${prefix}/bin/\${fbase#\${COMPILER_TARGET}-}" || true
done
"""

# We only build for Linux x86_64
platforms = [
    Linux(:x86_64, :glibc),
]

# The products that we will ensure are always built
products(prefix) = [
    ExecutableProduct(prefix, "gcc", :gcc),
]


# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
