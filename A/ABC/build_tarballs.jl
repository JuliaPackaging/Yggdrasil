using BinaryBuilder, Pkg

# abc
name = "ABC"
version = v"1.01.1"
ABC_ver = "1.01.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/berkeley-abc/abc.git", "08d25f39f2ee717b688529e61acb695cec0deeed")
]

# ABC is setup for native builds (the arch_flags program and running the
# shell to get other flags), so we need to manually add the arch flags
# here.  Also, the combo of BinaryBuilder and ABC's Makefile always seems
# to override rather than extend CFLAGS, so I've included the whole mess
# here.  Even though we use ABC_USE_STDINT_H=1 it doesn't work as
# expected, so we only use it here to prevent the Makefile from running
# the arch_flags executable, which will always fail when cross compiling.
# Note that neither -DLIN nor -DLIN64 actually appear to be used anymore but
# still set here anyway

# Bash recipe for building across all platforms
script = raw"""

EXFLGS="-Wall -Wno-unused-function -Wno-write-strings -Wno-sign-compare -DSIZEOF_INT=4 -DABC_USE_CUDD=1 -DABC_USE_PTHREADS -Wno-unused-but-set-variable -fPIC"

if [[ ${nbits} == 32 ]]; then
    EXFLGS="${EXFLGS} -DSIZEOF_VOID_P=4"
    EXFLGS="${EXFLGS} -DSIZEOF_LONG=4"
    EXFLGS="${EXFLGS} -DLIN"
else
    EXFLGS="${EXFLGS} -DSIZEOF_VOID_P=8"
    EXFLGS="${EXFLGS} -DSIZEOF_LONG=8"
    EXFLGS="${EXFLGS} -DLIN64"
fi

# musl doesn't like readline
if [[ ${target} != *"musl"* ]]; then
    EXFLGS="${EXFLGS} -DABC_READLINE"
fi

cd ${WORKSPACE}/srcdir/abc

# it appears necessary to have the file(s) for the FileProduct(s) live in the destdir
cp abc.rc ${prefix}/.

make -j${nproc} ABC_USE_STDINT_H=1 CFLAGS+="${EXFLGS}" libabc.so
# the abc Makefile always makes a .so  Fix that here.
mv libabc.so libabc.${dlext}
mkdir -p "${libdir}"
cp libabc.${dlext} ${libdir}

make -j${nproc} ABC_USE_STDINT_H=1 CFLAGS+="${EXFLGS}"
mkdir -p "${bindir}"
cp abc${exeext} ${bindir}
chmod +x ${bindir}/*
install_license copyright.txt
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(exclude= x -> (Sys.iswindows(x) || Sys.isfreebsd(x)))

# The products that we will ensure are always built
products = [
    ExecutableProduct("abc", :abc),
    LibraryProduct("libabc", :libabc),
    FileProduct("abc.rc", :abc_rc),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Readline_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script,
               platforms, products, dependencies; julia_compat="1.6")
