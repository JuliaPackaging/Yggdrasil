using BinaryBuilder

name = "LuaJIT"
# NOTE: LuaJIT has effectively moved to a "rolling release" model where users are
# expected to track either the `v2.1` or `v2.0` branch of the Git repository rather
# than relying on formal releases. We'll translate that to Yggdrasil versioning by
# using the date of the commit passed to `GitSource` as the patch number with the
# upstream version as the major and minor parts of the version. Whenever, if ever,
# Mike Pall decides to make e.g. a v2.1.0 release, we'll have to continue to use this
# system for it rather than reflecting the upstream version.
version = v"2.1.20221221"

# Upstream version, i.e. what the `VERSION` variable in the Makefile in the LuaJIT
# repository root should expand to.
upstream_version = v"2.1.0-beta3"
# The Lua ABI version, i.e. the Lua version targeted for compatibility by this version
# of LuaJIT. Taken from `ABIVER` in the Makefile.
abi_version = "5.1"

sources = [
    # We're using the GitHub mirror because the official source seems to be acting weird
    GitSource("https://github.com/LuaJIT/LuaJIT.git",
              "a04480e311f93d3ceb2f92549cad3fffa38250ef"),
    DirectorySource("./bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/LuaJIT*

if [ -d ${WORKSPACE}/srcdir/patches ]; then
    for file in ${WORKSPACE}/srcdir/patches/*.patch; do
        atomic_patch -p1 ${file}
    done
fi

FLAGS=(
    PREFIX="${prefix}"
    HOST_CC="${CC_BUILD} -m${nbits}"
    TARGET_CC="${CC}"
    HOST_SYS="BinaryBuilder"
)

make -j${nproc} amalg "${FLAGS[@]}"
make install "${FLAGS[@]}"
"""

# PowerPC is not currently supported upstream
platforms = filter!(p -> arch(p) !== :powerpc64le, supported_platforms())

# On some platforms, `luajit` is a symlink to this file, and we need the actual file
products = [
    ExecutableProduct("luajit-$(upstream_version)", :luajit),
    LibraryProduct(["libluajit-$(abi_version)",
                    "libluajit-$(abi_version).$(upstream_version.major)",
                    "lua" * replace(abi_version, "." => "")],
                   :libluajit),
]

dependencies = []

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
