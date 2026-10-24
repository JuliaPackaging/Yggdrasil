using BinaryBuilder

name = "PrimalSolver"
version = v"0.1.4"

sources = [
    GitSource("https://github.com/c-vision/Primal.git",
              "6ee5f000a05b01cdd0b0fb34896d34e343e05b8a"),
]

# The library is the 11 solver translation units plus every primal_*.c (the
# LIBSRCS of the upstream Makefile, which only builds the static archive).
# Plain C99; pthread for the parallel branch-and-bound workers.
script = raw"""
cd ${WORKSPACE}/srcdir/Primal
SRCS="linalg.c stdform.c simplex.c ipm.c socp.c sdp.c expcone.c mpsio.c cbf.c scaling.c presolve.c $(ls primal_*.c)"
mkdir -p ${libdir}
${CC} -std=c99 -O2 -fPIC -I. -shared -o ${libdir}/libprimal.${dlext} ${SRCS} -lm -lpthread
install -Dvm 644 primal.h ${includedir}/primal.h
install_license LICENSE
"""

platforms = supported_platforms()

products = [
    LibraryProduct("libprimal", :libprimal),
]

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
