# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
#
# NCBIDatasets_jll repackages NCBI's official prebuilt `datasets` and
# `dataformat` command-line tools. We do NOT build from source: `dataformat`
# has no public source, and `datasets` requires a Java OpenAPI codegen step
# that the BinaryBuilder toolchain cannot run. The binaries are public-domain
# "United States Government Work" (redistribution unrestricted). Same approach
# as Deno_jll / Kaleido_jll.
using BinaryBuilder

name = "NCBIDatasets"
version = v"18.30.0"

# Official release assets (each zip contains both `datasets` and `dataformat`),
# plus the source tarball solely to obtain LICENSE.md (the binary zips bundle
# no license).
release = "https://github.com/ncbi/datasets/releases/download/v$(version)"
sources = [
    ArchiveSource("$release/linux-amd64.cli.package.zip",
                  "dae5e530ed76d02043d44da87083bf114a8865a8899ebaba089c3deedc8a5358"; unpack_target = "linux-amd64"),
    ArchiveSource("$release/linux-arm64.cli.package.zip",
                  "3b2ecac56db1210d992ad0bd017b11a4f05a431c6a686c0d272a47004f9ff4ef"; unpack_target = "linux-arm64"),
    ArchiveSource("$release/linux-arm.cli.package.zip",
                  "1895a6e97343b013261176dae03042ee22cd407c62336032698895f452ac408d"; unpack_target = "linux-arm"),
    ArchiveSource("$release/darwin-universal.cli.package.zip",
                  "5d0e6982326e8851022e65fb88a6bd1fd2197d28c97df7c40595bbd0b7cc86ed"; unpack_target = "darwin-universal"),
    ArchiveSource("$release/windows-amd64.cli.package.zip",
                  "56807e4de16f86fffd7ac9f7a5dda6ab036ad631b7d254ca073993b908efebdb"; unpack_target = "windows-amd64"),
    # Source clone solely to obtain LICENSE.md. We pin the v18.30.0 commit via
    # GitSource because GitHub's auto-generated tarballs have unstable checksums.
    GitSource("https://github.com/ncbi/datasets.git",
              "c292d8f58e5cb6e27385385fc5d52f59a3409068"),
]

# Bash recipe for installing across all platforms.
# All Linux binaries are fully static (CGO-disabled Go), so the same x86_64 /
# aarch64 builds serve both glibc and musl targets. macOS ships one universal
# Mach-O that runs natively on Intel and Apple-silicon Macs.
script = raw"""
case "${target}" in
    x86_64-linux-*)   pkg="linux-amd64"      ;;
    aarch64-linux-*)  pkg="linux-arm64"      ;;
    arm*-linux-*)     pkg="linux-arm"        ;;
    *-apple-darwin*)  pkg="darwin-universal" ;;
    *-mingw32)        pkg="windows-amd64"    ;;
    *) echo "Unsupported target: ${target}" >&2; exit 1 ;;
esac

install -Dvm 755 "${WORKSPACE}/srcdir/${pkg}/datasets${exeext}"   "${bindir}/datasets${exeext}"
install -Dvm 755 "${WORKSPACE}/srcdir/${pkg}/dataformat${exeext}" "${bindir}/dataformat${exeext}"

install_license ${WORKSPACE}/srcdir/datasets/LICENSE.md
"""

# Platforms NCBI publishes prebuilt binaries for. musl entries reuse the static
# Linux binaries (validated: musl tarball is byte-identical to glibc). armv7l
# is the hard-float EABI tag and passes audit with no ISA mismatch.
platforms = [
    Platform("x86_64",  "linux";   libc = "glibc"),
    Platform("x86_64",  "linux";   libc = "musl"),
    Platform("aarch64", "linux";   libc = "glibc"),
    Platform("aarch64", "linux";   libc = "musl"),
    Platform("armv7l",  "linux";   libc = "glibc"),
    Platform("x86_64",  "macos"),
    Platform("aarch64", "macos"),
    Platform("x86_64",  "windows"),
]

# The products that we will ensure are always built.
products = [
    ExecutableProduct("datasets",   :datasets),
    ExecutableProduct("dataformat", :dataformat),
]

# No dependencies (static binaries).
dependencies = Dependency[]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat = "1.6")
