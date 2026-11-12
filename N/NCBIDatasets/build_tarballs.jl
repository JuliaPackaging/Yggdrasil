# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
#
# NCBIDatasets_jll repackages NCBI's official prebuilt `datasets` command-line
# tool. We do NOT build from source: `datasets` requires a Java OpenAPI codegen
# step that the BinaryBuilder toolchain cannot run. The binary itself is
# public-domain "United States Government Work" (redistribution unrestricted);
# its source is open (github.com/ncbi/datasets).
using BinaryBuilder

name = "NCBIDatasets"
version = v"18.37.0"

# The pinned GitSource is solely for LICENSE.md (the binary zips bundle no license).
release = "https://github.com/ncbi/datasets/releases/download/v$(version)"
sources = [
    ArchiveSource("$release/linux-amd64.cli.package.zip",
                  "f553860753712e6628e4f0f45a1388f9ad27e6f9d5d07549d1c87cd208955f4b"; unpack_target = "x86_64-linux-gnu"),
    ArchiveSource("$release/linux-amd64.cli.package.zip",
                  "f553860753712e6628e4f0f45a1388f9ad27e6f9d5d07549d1c87cd208955f4b"; unpack_target = "x86_64-linux-musl"),
    ArchiveSource("$release/linux-arm64.cli.package.zip",
                  "1c8784b02d42d99194f2d82a2636377f934ba8f414d1eb848210b39fb9cc6004"; unpack_target = "aarch64-linux-gnu"),
    ArchiveSource("$release/linux-arm64.cli.package.zip",
                  "1c8784b02d42d99194f2d82a2636377f934ba8f414d1eb848210b39fb9cc6004"; unpack_target = "aarch64-linux-musl"),
    ArchiveSource("$release/linux-arm.cli.package.zip",
                  "4ed2bf905bf8b5d8c9c2d0915c689316fff41ed4cb65b3353924feae59349a31"; unpack_target = "arm-linux-gnueabihf"),
    ArchiveSource("$release/darwin-universal.cli.package.zip",
                  "910668772af3e899334c01775101ffe71b38bca36461a7cb7798ef840c3a782a"; unpack_target = "x86_64-apple-darwin14"),
    ArchiveSource("$release/darwin-universal.cli.package.zip",
                  "910668772af3e899334c01775101ffe71b38bca36461a7cb7798ef840c3a782a"; unpack_target = "aarch64-apple-darwin20"),
    ArchiveSource("$release/windows-amd64.cli.package.zip",
                  "e2f93e3378a37bea8dd5b2dfa8274568b86e2dd6497e8d21aced7a4ce6d4d331"; unpack_target = "x86_64-w64-mingw32"),
    GitSource("https://github.com/ncbi/datasets.git",
              "c292d8f58e5cb6e27385385fc5d52f59a3409068"),
]

script = raw"""
install -Dvm 755 "${WORKSPACE}/srcdir/${target}/datasets${exeext}" "${bindir}/datasets${exeext}"
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
    ExecutableProduct("datasets", :datasets),
]

# No dependencies (static binaries).
dependencies = Dependency[]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat = "1.6")
