using BinaryBuilder

name = "Dgraph"
version = v"25.5.1"

sources = [
    GitSource(
        "https://github.com/dgraph-io/dgraph.git",
        "7f7a7e3c533d2ca047bd74af2273ff65aded37f1";
        tag="v$(version)",
    ),
]

script = """
DGRAPH_VERSION=v$(version)
DGRAPH_MAJOR=v$(version.major)
""" * raw"""
cd ${WORKSPACE}/srcdir/dgraph
install_license LICENSE.txt

# Keep Go's scratch dir out of the sandbox's small /tmp so the linker does not hit ENOSPC.
export GOTMPDIR=${WORKSPACE}/gotmp
mkdir -vp ${GOTMPDIR}

BUILD_SHA=$(git rev-parse --short HEAD)
BUILD_DATE=$(git log -1 --format=%ci)
PKG="github.com/dgraph-io/dgraph/${DGRAPH_MAJOR}/x"

# Invoke go build directly instead of dgraph/Makefile, which runs `go mod tidy`
# and downloads/compiles jemalloc with curl. `-s` strips the OS symbol table
# (keeping .gopclntab), preventing riscv64-linux-gnu-objdump from stalling during audit.
cd dgraph
CGO_ENABLED=0 go build \
    -trimpath \
    -ldflags "-s -w -X ${PKG}.dgraphVersion=${DGRAPH_VERSION} -X ${PKG}.dgraphCodename=dgraph -X ${PKG}.lastCommitSHA=${BUILD_SHA} -X '${PKG}.lastCommitTime=${BUILD_DATE}' -X ${PKG}.gitBranch=release" \
    -o "dgraph${exeext}"
install -Dvm 755 "dgraph${exeext}" "${bindir}/dgraph${exeext}"
"""

platforms = supported_platforms()
# posting/list.go uses math.MaxInt64 in int context, which overflows 32-bit int.
filter!(p -> nbits(p) == 64, platforms)

products = [
    ExecutableProduct("dgraph", :dgraph),
]

dependencies = Dependency[]

build_tarballs(
    ARGS,
    name,
    version,
    sources,
    script,
    platforms,
    products,
    dependencies;
    compilers=[:go, :c],
    julia_compat="1.6",
)
