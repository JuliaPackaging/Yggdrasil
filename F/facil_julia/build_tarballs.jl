using BinaryBuilder, Pkg

name = "facil_julia"
# The version of Facil.jl at the commit below. It has no tag yet: Facil.jl is
# registered and tagged only once this JLL exists.
version = v"0.1.0"

# The C library of Facil.jl: its shim (deps/shim) compiled together with
# facil.io 0.7 at the commit Facil.jl pins, with Facil.jl's patch series
# (deps/patches) applied. Facil.jl applies the same series when it builds the
# library locally, so the patches live in its repository, not in bundled/.
sources = [
    GitSource("https://github.com/aryan-juliahub/Facil.jl.git", "7bdde94d6a1f9efd97e7d485210de190a719b0b8"),
    GitSource("https://github.com/boazsegev/facil.io.git", "5128747363055201d3ecf0e29bf0a961703c9fa0"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/facil.io
facil_jl=${WORKSPACE}/srcdir/Facil.jl
for p in $(cat ${facil_jl}/deps/patches/series); do
    atomic_patch -p1 ${facil_jl}/deps/patches/${p}
done

# facil.io's makefile builds only its own sources and sets feature macros from
# probes that run test programs. The shim and facil.io are one library, so both
# are compiled with a single command, as Facil.jl's deps/build_local.jl does.
FLAGS=(-std=gnu11 -O2 -fPIC -DNDEBUG -DHAVE_OPENSSL -DFIO_TLS_FOUND)
if [[ "${target}" == *-linux-* ]]; then
    # http.c assumes tm_zone only on BSD systems unless told
    FLAGS+=(-DHAVE_TM_TM_ZONE=1)
fi
if [[ "${target}" == *-musl* ]]; then
    # musl declares sendfile64 only with this macro
    FLAGS+=(-D_LARGEFILE64_SOURCE)
fi
F=lib/facil
mkdir -vp ${libdir}
${CC} -shared "${FLAGS[@]}" \
    -DFJL_BUILD_ID='"facil.io-'$(git rev-parse --short=8 HEAD)'-jll"' \
    -I${F} -I${F}/fiobj -I${F}/http -I${F}/http/parsers -I${F}/cli -I${F}/tls -I${F}/redis \
    -I${facil_jl}/deps/shim -I${includedir} \
    $(find ${F} -name '*.c' -not -path '*/legacy/*') ${facil_jl}/deps/shim/*.c \
    -o ${libdir}/libfacil_julia.${dlext} \
    -L${libdir} -lssl -lcrypto -lz -lpthread -lm

install_license ${facil_jl}/LICENSE
install -Dvm 644 LICENSE ${prefix}/share/licenses/facil_julia/LICENSE.facil.io
"""

platforms = supported_platforms()
# facil.io has no Windows port, and the shim's timer thread exists for Linux
# (timerfd) and macOS (kqueue) only: fjl_timer.c stops with #error elsewhere.
filter!(p -> Sys.islinux(p) || Sys.isapple(p), platforms)
# Zlib_jll 1.2.13 has no riscv64 build
filter!(p -> arch(p) != "riscv64", platforms)

products = [
    LibraryProduct("libfacil_julia", :libfacil_julia),
]

dependencies = [
    Dependency("OpenSSL_jll"; compat="3.0.16"),
    Dependency("Zlib_jll"; compat="1.2.13"),
]

# The shim uses C11 atomics: GCC 4.8 has no stdatomic.h
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", preferred_gcc_version=v"5")
