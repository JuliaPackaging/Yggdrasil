using BinaryBuilder, Base.BinaryPlatforms
include("../../fancy_toys.jl")

function binutils_sources(version)
    binutils_version_sources = Dict(
        v"2.24" => [
            ArchiveSource("https://ftp.gnu.org/gnu/binutils/binutils-2.24.tar.bz2",
                          "e5e8c5be9664e7f7f96e0d09919110ab5ad597794f5b1809871177a0f0f14137"),
        ],
        v"2.25.1" => [
            ArchiveSource("https://ftp.gnu.org/gnu/binutils/binutils-2.25.1.tar.bz2",
                          "b5b14added7d78a8d1ca70b5cb75fef57ce2197264f4f5835326b0df22ac9f22"),
        ],
        v"2.26" => [
            ArchiveSource("https://ftp.gnu.org/gnu/binutils/binutils-2.26.tar.bz2",
                          "c2ace41809542f5237afc7e3b8f32bb92bc7bc53c6232a84463c423b0714ecd9"),
        ],
        v"2.27" => [
            ArchiveSource("https://ftp.gnu.org/gnu/binutils/binutils-2.27.tar.bz2",
                          "369737ce51587f92466041a97ab7d2358c6d9e1b6490b3940eb09fb0a9a6ac88"),
        ],
        v"2.31" => [
            ArchiveSource("https://ftp.gnu.org/gnu/binutils/binutils-2.31.tar.bz2",
                          "2c49536b1ca6b8900531b9e34f211a81caf9bf85b1a71f82b81ae32fcd8ffe19"),
        ],
        v"2.33.1" => [
            ArchiveSource("https://ftp.gnu.org/gnu/binutils/binutils-2.33.1.tar.xz",
                          "ab66fc2d1c3ec0359b8e08843c9f33b63e8707efdff5e4cc5c200eae24722cbf"),
        ],
        v"2.34" => [
            ArchiveSource("https://ftp.gnu.org/gnu/binutils/binutils-2.34.tar.xz",
                          "f00b0e8803dc9bab1e2165bd568528135be734df3fabf8d0161828cd56028952"),
        ],
        v"2.35.1" => [
            ArchiveSource("https://ftp.gnu.org/gnu/binutils/binutils-2.35.1.tar.xz",
                          "3ced91db9bf01182b7e420eab68039f2083aed0a214c0424e257eae3ddee8607"),
        ],
        v"2.36" => [
            ArchiveSource("https://ftp.gnu.org/gnu/binutils/binutils-2.36.tar.xz",
                          "5788292cc5bbcca0848545af05986f6b17058b105be59e99ba7d0f9eb5336fb8"),
        ],
    )
    return [
        binutils_version_sources[version]...,
        # We've got a bevvy of patches for binutils, include them in.
        DirectorySource("./bundled"; follow_symlinks=true),
    ]
end

function binutils_script()
    return string(bash_parse_encoded_target_triplet(),
    raw"""
    # FreeBSD build system for binutils apparently requires that uname sit in /usr/bin/
    ln -sf $(which uname) /usr/bin/uname
    cd ${WORKSPACE}/srcdir/binutils-*/

    # Update configure scripts and apply patches
    update_configure_scripts
    for p in ${WORKSPACE}/srcdir/patches/binutils-*.patch; do
        atomic_patch -p1 "${p}"
    done

    ./configure --prefix=${prefix} \
        --target=${encoded_target} \
        --with-sysroot=${prefix}/${encoded_target} \
        --build=${MACHTYPE} \
        --enable-multilib \
        --disable-werror

    make -j${nproc}
    make install
    """)
end

function binutils_platforms()
    # only macOS doesn't use binutils, so collect platforms for everyone else
    platforms = filter(p -> !Sys.isapple(p), supported_platforms(;experimental=true))
    return map(encode_target_platform, platforms)
end

function binutils_products()
    return Product[
        FileProduct("bin", :bindir),
    ]
end

function binutils_dependencies()
    return [
        # We add the `libz` dependency here so that our binutils can read compressed sections
        Dependency("Zlib_jll"),
    ]
end
