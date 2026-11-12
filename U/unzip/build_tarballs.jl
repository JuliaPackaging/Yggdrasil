using BinaryBuilder

name = "unzip"
version = v"6.0.3"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/madler/unzip.git",
              "0b82c20ac7375b522215b567174f370be89a4b12"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/unzip*

MFLAGS=(
    CC_CPU_OPT=
    prefix=${prefix}
)

if [[ ${target} == *mingw* ]]; then
    if [[ ${target} == x86_64* ]]; then
        MFLAGS+=( APPLY_ASMCRC=0 )
    fi
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/cr_to_xcr.patch"
    cp win32/Makefile.gcc Makefile
    make ${MFLAGS[@]} -j${nproc}
    mkdir -p ${bindir}
    mv *.exe ${bindir}/
else
    cp unix/Makefile Makefile        

    if [[ ${target} == *riscv* ]]; then
       make generic1 ${MFLAGS[@]} -j${nproc}
    elif [[ ${target} == *darwin* ]]; then
       make macosx ${MFLAGS[@]} -j${nproc}
    elif [[ ${target} == *freebsd* ]]; then
       make bsd ${MFLAGS[@]} -j${nproc}
    else
       make generic ${MFLAGS[@]} -j${nproc}
    fi

    make install ${MFLAGS[@]}
fi
install_license LICENSE
install_license WHERE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = [
    ExecutableProduct("unzip", :unzip),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
