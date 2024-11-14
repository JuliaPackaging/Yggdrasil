# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "P11Kit"
version = v"0.25.5"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/p11-glue/p11-kit/releases/download/$(version)/p11-kit-$(version).tar.xz",
                  "04d0a86450cdb1be018f26af6699857171a188ac6d5b8c90786a60854e1198e5")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/p11-kit-*

if [[ ${target} = *-mingw32 ]]; then

    # `configure` does not work on Windows

    meson setup --cross-file="${MESON_TARGET_TOOLCHAIN}" --buildtype=release builddir
    meson compile -C builddir
    meson install -C builddir

else

    # Meson is too clever to build for Apple. It produces command line
    # errors when configuring and then misinterprets the result. We're
    # using `configure` instead. The reported error message is
    # `#error "unsupported size of CK_ULONG"`.

    mkdir builddir
    cd builddir
    ../configure --build=${MACHTYPE} --host=${target} --prefix=${prefix}
    make -j${nproc}
    make install

fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()


# The products that we will ensure are always built
products = [
    # p11-kit-client.so is not built on Windows, so we temporarily disable it
    # LibraryProduct("p11-kit-client", :libp11kitclient, "lib/pkcs11"),
    LibraryProduct("libp11-kit", :libp11kit),
    ExecutableProduct("p11-kit", :p11kit)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("Libffi_jll"),
    Dependency("libtasn1_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
# Prefer GCC 6 to define `memcpy@GLIBC_2.14'`
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"6")
