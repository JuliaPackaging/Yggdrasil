using BinaryBuilder2

name = "BBJobserver"
version = v"0.2.0"

# `bb_jobserver` limits how many compiler processes run at once across all the
# BinaryBuilder2 builds on a machine: it is the jobserver daemon, the session BinaryBuilder2
# keeps open during each build, and the `run` front end that BinaryBuilderToolchains'
# compiler wrappers start their tools through (see the comment at the top of
# `bundled/bb_jobserver.c`).
sources = [
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms.  It is linked statically because every
# compiler invocation execs it, and a static binary starts noticeably faster.
script = raw"""
cd ${WORKSPACE}/srcdir
mkdir -p ${bindir}
${CC} -std=c99 -O2 -Wall -static -o ${bindir}/bb_jobserver bb_jobserver.c
install_license LICENSE
"""

# It runs inside the build sandbox and on the build host, both Linux, and uses Linux-only
# APIs (epoll, pidfds, SO_PEERCRED)
platforms = filter(Sys.islinux, supported_platforms())

# The products that we will ensure are always built
products = [
    ExecutableProduct("bb_jobserver", :bb_jobserver),
]

# Build the tarballs
build_tarballs(;
    src_name = name,
    src_version = version,
    sources,
    script,
    platforms,
    products,
)
