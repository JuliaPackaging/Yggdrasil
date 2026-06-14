using BinaryBuilder

# Collection of pre-built ShellCheck binaries.
name = "ShellCheck"
shellcheck_ver = "0.11.0"
version = VersionNumber(shellcheck_ver)

url_prefix = "https://github.com/koalaman/shellcheck/releases/download/v$(shellcheck_ver)/shellcheck-v$(shellcheck_ver)"
sources = [
    ArchiveSource("$(url_prefix).linux.x86_64.tar.xz", "8c3be12b05d5c177a04c29e3c78ce89ac86f1595681cab149b65b97c4e227198"; unpack_target = "x86_64-linux-gnu"),
    ArchiveSource("$(url_prefix).linux.aarch64.tar.xz", "12b331c1d2db6b9eb13cfca64306b1b157a86eb69db83023e261eaa7e7c14588"; unpack_target = "aarch64-linux-gnu"),
    ArchiveSource("$(url_prefix).linux.riscv64.tar.xz", "693c987777e7b524dd311d9b8c704885a39c889c9804bb1ef1fd29b48567b0b3"; unpack_target = "riscv64-linux-gnu"),
    ArchiveSource("$(url_prefix).darwin.x86_64.tar.xz", "3c89db4edcab7cf1c27bff178882e0f6f27f7afdf54e859fa041fca10febe4c6"; unpack_target = "x86_64-apple-darwin14"),
    ArchiveSource("$(url_prefix).darwin.aarch64.tar.xz", "56affdd8de5527894dca6dc3d7e0a99a873b0f004d7aabc30ae407d3f48b0a79"; unpack_target = "aarch64-apple-darwin20"),
    ArchiveSource("$(url_prefix).zip", "8a4e35ab0b331c85d73567b12f2a444df187f483e5079ceffa6bda1faa2e740e"; unpack_target = "x86_64-w64-mingw32/shellcheck-v"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/
mkdir -p "${bindir}"
install -m 755 ${target}/shellcheck-v*/shellcheck${exeext} "${bindir}/shellcheck${exeext}"
install_license ${target}/shellcheck-v*/LICENSE.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"),
    Platform("aarch64", "linux"),
    Platform("riscv64", "linux"),
    Platform("x86_64", "macos"),
    Platform("aarch64", "macos"),
    Platform("x86_64", "windows"),
]

# The products that we will ensure are always built
products = [
    ExecutableProduct("shellcheck", :shellcheck),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, julia_compat="1.6")
