using BinaryBuilder

compiler_target = triplet(platform_key(ARGS[end]))
if compiler_target == "unknown-unknown-unknown"
    error("This is not a typical build_tarballs.jl!  Must provide exactly one platform as the last argument!")
end
deleteat!(ARGS, length(ARGS))

# Encode the compiler target into the name
name = "Binutils-$(compiler_target)"
version = v"2.24"

# Collection of sources required to build Binutils
sources = [
    "https://ftp.gnu.org/gnu/binutils/binutils-2.24.tar.bz2" =>
	"e5e8c5be9664e7f7f96e0d09919110ab5ad597794f5b1809871177a0f0f14137",
    "https://github.com/tpoechtrager/apple-libtapi.git" =>
    "e56673694db395e25b31808b4fbb9a7005e6875f",
    "https://github.com/tpoechtrager/cctools-port.git" =>
    "ecb84d757b6f011543504967193375305ffa3b2f",
    "./bundled",
]

# Bash recipe for building across all platforms
script = """
# FreeBSD build system for binutils apparently requires that uname sit in /usr/bin/
ln -sf \$(which uname) /usr/bin/uname

# On MacOS, we don't actually install Binutils.  We install libtapi and cctools.  Le sigh.
if [[ $(compiler_target) == *apple* ]]; then
    mkdir -p \${WORKSPACE}/srcdir/apple-libtapi/build
    cd \${WORKSPACE}/srcdir/apple-libtapi/build

    # Install libtapi
    cmake ../src/apple-llvm/src \\
        -DLLVM_INCLUDE_TESTS=OFF \\
        -DCMAKE_BUILD_TYPE=RELEASE \\
        -DCMAKE_INSTALL_PREFIX=\${prefix}
    make -j\${nproc} VERBOSE=1
    make install

    # Install cctools.  Someday, try this without disabling the clang assembler!
    cd \${WORKSPACE}/srcdir/cctools-port/cctools
    ./configure --prefix=\${prefix} \\
        --target=$(compiler_target) \\
        --host=\${MACHTYPE} \\
        --with-libtapi=\${prefix}
    make -j\${nproc}
    make install
else
    cd \${WORKSPACE}/srcdir/binutils-*/

    #atomic_patch -p1 "\${WORKSPACE}/srcdir/patches/binutils_COFF_bfd.patch"
    update_configure_scripts

    ./configure --prefix=\${prefix} \\
        --target=$(compiler_target) \\
        --host=\${MACHTYPE} \\
        --with-sysroot="\${prefix}/$(compiler_target)/sys-root" \\
        --enable-multilib \\
        --disable-werror

    make -j\${nproc}
    make install
fi

# Finally, create a bunch of symlinks stripping out the target so that
# things like `nm` "just work", as long as we've got our path set properly.
for f in \${prefix}/bin/$(compiler_target)-*; do
    fbase=\$(basename \$f)
    ln -s \$fbase \${prefix}/bin/\${fbase#$(compiler_target)-}
done
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [Linux(:x86_64)]

# The products that we will ensure are always built
products = prefix -> [
    ExecutableProduct(prefix, "$(compiler_target)-as", :as),
    ExecutableProduct(prefix, "$(compiler_target)-nm", :nm),
    ExecutableProduct(prefix, "$(compiler_target)-ld", :ld),
    ExecutableProduct(prefix, "$(compiler_target)-strip", :strip),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "https://github.com/staticfloat/KernelHeadersBuilder/releases/download/v4.12.0-0/build_KernelHeaders.v4.12.0.jl",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; skip_audit=true)
