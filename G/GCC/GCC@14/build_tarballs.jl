using BinaryBuilder2

include("../common.jl")

name = "GCC"
version = v"14.4.0"

sources = [
    ArchiveSource("https://mirrors.kernel.org/gnu/gcc/gcc-$(version)/gcc-$(version).tar.xz",
                  "752b6f567beac83159c77a7680b1316bdd784738bff9a9d070112c09da90f6d9"),
    ArchiveSource("https://mirrors.kernel.org/gnu/mpfr/mpfr-4.1.0.tar.xz",
                  "0c98a3f1732ff6ca4ea690552079da9c597872d30e96ec28414ee23c95558a7f";
                  target="gcc-$(version)"),
    ArchiveSource("https://mirrors.kernel.org/gnu/mpc/mpc-1.2.1.tar.gz",
                  "17503d2c395dfcf106b622dc142683c1199431d095367c6aacba6eec30340459";
                  target="gcc-$(version)"),
    ArchiveSource("https://gcc.gnu.org/pub/gcc/infrastructure/isl-0.24.tar.bz2",
                  "fcf78dd9656c10eb8cf9fbd5f59a0b6b01386205fe1934b3b287a0a1898145c0";
                  target="gcc-$(version)"),
    ArchiveSource("https://mirrors.kernel.org/gnu/gmp/gmp-6.2.1.tar.xz",
                  "fd4829912cddd12f84181c3451cc752be224643e87fac497b69edddadc49b4f2";
                  target="gcc-$(version)"),
    DirectorySource("./bundled"; target="bundled"),
]

script = gcc_script()
platforms = [
    gcc_platforms()...,
    # The MemorySanitizer libstdc++ (see `bundled/libstdcxx_sanitized.sh`)
    CrossPlatform(Platform("x86_64", "linux") => Platform("x86_64", "linux"; sanitize="memory")),
]
products = gcc_products

build_tarballs(;
    src_name = name,
    src_version = version,
    sources,
    script,
    platforms,
    products,
    build_spec_generator = gcc_build_spec_generator,
    extract_spec_generator = gcc_extract_spec_generator,
    duplicate_extraction_handling = :ignore_all,
    # Julia < 1.10 breaks ties between matching artifacts by triplet, so on x86_64-linux-gnu
    # it would select the MemorySanitizer libstdc++ over the plain one.
    julia_compat = "1.10",
)
