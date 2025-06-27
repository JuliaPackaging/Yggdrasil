### Instructions for adding a new version of the OCaml toolchain
#
# * update the `version` variable and `sources`
# * To deploy the shard and automatically update your BinaryBuilderBase's
#   `Artifacts.toml`, use the `--deploy` flag to the `build_tarballs.jl` script.
#   You can build & deploy by running:
#
#      julia build_tarballs.jl --debug --verbose --deploy TARGET
#

using BinaryBuilderBase, BinaryBuilder, Pkg.Artifacts

include("../common.jl")

name = "OCamlBase"
version = v"5.4.0"

sources = [
    GitSource("https://github.com/ocaml/ocaml.git",
              "ff1ab416a5503c8bde9fa3fae5f2bb21c7ddc81e"),  # 5.4.0~alpha1
    DirectorySource("./bundled"),
]

# Check if deploy flag is set
deploy = "--deploy" in ARGS

# These are the targets we support right now:
#   x86_64-w64-mingw32
#   x86_64-apple-darwin
#   aarch64-apple-darwin
#   x86_64-linux-gnu
#   x86_64-linux-musl
#   aarch64-linux-gnu
#   aarch64-linux-musl
#   riscv64-linux-gnu
#   riscv64-linux-musl
#
# Not supported:
#  i686: OCaml 5.0 dropped support for 32-bit platforms
#  freebsd: `POSIX threads are required but not supported on this platform`

# The first thing we're going to do is to install Rust for all targets into a single prefix
script = raw"""
cd ${WORKSPACE}/srcdir/ocaml
git submodule update --init

# Apply patches
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done

# Do a native build of OCaml in $host_prefix (which takes PATH preference over $prefix)
./configure --prefix=${host_prefix} --build=${MACHTYPE} --host=${MACHTYPE} \
            CC="$HOSTCC" CXX="$HOSTCXX" LD="$HOSTLD" STRIP="$HOSTSTRIP" AS="$HOSTAS"
make -j${nproc}
make install
git clean -fxd

# Build the cross-compiler in $prefix
# XXX: we use the target compilers, even though the cross compiler will run on the host,
#      to work around issues with the configure script incorrectly detecting support for
#      certain important features (like shared libraries). this has disadvantages, though,
#      like using exe suffixes for executables on Windows (which isn't too bad since we
#      automatically create symlinks for them).
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${MACHTYPE} --target=${target}
make crossopt -j${nproc}
make installcross

# Fix shebang of ocamlrun scripts to not hardcode a path of the build environment
for bin in $(file ${bindir}/* | grep "a \S*/ocamlrun script" | cut -d: -f1); do
    abspath=$(file ${bin} | grep -oh "a \S*/ocamlrun script" | cut -d' ' -f2)
    sed -i "s?${abspath}?/usr/bin/env ocamlrun?" "${bin}"
done
"""

platforms = Platform[ host_platform ]
products = Product[
    # build with no products since all of our products are for the host, not the target

    # ExecutableProduct("ocamlopt.opt", :ocamlopt),
    # ExecutableProduct("ocamlc.opt", :ocamlc),
    # ExecutableProduct("ocamlrun", :ocamlrun),
]
dependencies = Dependency[]

name = "OCaml"
compiler_target = try
    parse(Platform, ARGS[end])
catch
    error("This is not a typical build_tarballs.jl!  Must provide exactly one platform as the last argument!")
end
deleteat!(ARGS, length(ARGS))

# Build the tarballs
ndARGS, deploy_target = find_deploy_arg(ARGS)
build_info = build_tarballs(ndARGS, name, version, sources, script, Platform[compiler_target], products, dependencies;
                            skip_audit=true, julia_compat="1.6", preferred_gcc_version=v"5")

build_info = Dict(host_platform => first(values(build_info)))

# Upload the artifacts (if requested)
if deploy_target !== nothing
    upload_and_insert_shards(deploy_target, name, version, build_info; target=compiler_target)
end
