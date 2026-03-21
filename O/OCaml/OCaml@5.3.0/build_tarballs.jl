# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "OCaml"
version = v"5.3.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/ocaml/ocaml.git", "1ccb919e35f8378834060c503ae953897fe0fb7f"),
    DirectorySource("./bundled"),

    ArchiveSource("https://github.com/topolarity/ocaml/releases/download/5.3.0-1/ocaml-5.3.0-1-aarch64-apple-darwin.tar.xz",
                  "647f44614b9f4df7cdd46092079169303d8f56f7ce970a290f6182c10d22c5be",
                  ; unpack_target = "ocaml-5.3.0-aarch64-apple-darwin20"),
    ArchiveSource("https://github.com/topolarity/ocaml/releases/download/5.3.0-1/ocaml-5.3.0-1-x86_64-apple-darwin.tar.xz",
                  "4dff08159d03c1a28394093f101d8cf616a726d93d2ba4ababf9881dc19a5e40",
                  ; unpack_target = "ocaml-5.3.0-x86_64-apple-darwin14"),
    ArchiveSource("https://github.com/topolarity/ocaml/releases/download/5.3.0-1/ocaml-5.3.0-1-x86_64-w64-mingw32.tar.xz",
                  "4ba847ad57d47b32c873fdcd07e2e9e955459a34fd8e8bb85573589c005552a6",
                  ; unpack_target = "ocaml-5.3.0-x86_64-w64-mingw32"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

if [[ "${target}" == *-darwin* ]] || [[ "${target}" == *-mingw* ]]; then
    # For Windows / macOS just use the prebuilt library
    cp -r ocaml-5.3.0-${target}/*/* ${prefix}/.
    cd ocaml
    install_license LICENSE
else
    # Otherwise, do a proper build
    cd ocaml
    for f in ${WORKSPACE}/srcdir/patches/*.patch; do
        atomic_patch -p1 ${f}
    done
    ./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
    make -j${nproc}
    make install
fi

for bin in $(file ${bindir}/* | grep "a \S*/ocamlrun script" | cut -d: -f1); do
    # Fix shebang of ocamlrun scripts to not hardcode
    # a path of the build environment
    abspath=$(file ${bin} | grep -oh "a \S*/ocamlrun script" | cut -d' ' -f2)
    sed -i "s?${abspath}?/usr/bin/env ocamlrun?" "${bin}"
done
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="musl"),
    Platform("x86_64", "windows"),
    Platform("x86_64", "macos"),
    Platform("aarch64", "macos"),
]


# The products that we will ensure are always built
products = [
    ExecutableProduct("ocamlopt.opt", :ocamlopt),
    ExecutableProduct("ocamlc.opt", :ocamlc),
    ExecutableProduct("ocamlrun", :ocamlrun),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"5")
