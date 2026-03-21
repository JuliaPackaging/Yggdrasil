using BinaryBuilder
using Pkg

name = "RuNNer"
version = v"2.0.0"

sources = [
    GitSource("https://gitlab.com/runner-suite/runner2.git",
        "b23bfb7b514071cb0d18c3854f0ed68be678a057"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/runner2

sed -i 's/\[ -z \$FCTYPE\]/[ -z "$FCTYPE" ]/' configure
sed -i 's/\$FC -l\$1/$FC $LDFLAGS -l$1/g' configure

export CPPFLAGS="-I${includedir}"
export LDFLAGS="-L${libdir}"
export LIBRARY_PATH="${libdir}:${LIBRARY_PATH}"
export LD_LIBRARY_PATH="${libdir}:${LD_LIBRARY_PATH}"

if [[ "${target}" == *mingw* ]]; then
    python - <<'PY'
p = "src/utils/sys.f90"

with open(p, "r") as f:
    s = f.read()

s = s.replace('        stat = gethostname(cstr_hostname, lenstr)\n',
              '        stat = 0\n')
s = s.replace('        hname = c2fstring(cstr_hostname)\n',
              '        hname = "windows"\n')

with open(p, "w") as f:
    f.write(s)
PY
fi

./configure \
    FC=${FC} \
    FCTYPE=GNU \
    MKL=OFF \
    MPI=OFF \
    ACCELERATE=OFF \
    STATIC=OFF

if [[ "${target}" == *apple* ]]; then
    sed -i 's/$(call RUN, AR) -- \$@ \$^/$(call RUN, AR) $(ARFLAGS) $@ $^/g' GNUmakefile
    make ARCH= AR=ar ARFLAGS=rv RANLIB=ranlib -j${nproc}
    make ARCH= AR=ar ARFLAGS=rv RANLIB=ranlib libRuNNer.so
else
    make ARCH= -j${nproc}
    make ARCH= libRuNNer.so
fi

mkdir -p ${bindir} ${libdir}
cp RuNNer.x ${bindir}/
if [[ "${target}" == *mingw* ]]; then
    # executable
    if [ -f RuNNer.x.exe ]; then
        cp RuNNer.x.exe ${bindir}/RuNNer.x.exe
    elif [ -f RuNNer.exe ]; then
        cp RuNNer.exe ${bindir}/RuNNer.x.exe
    elif [ -f RuNNer.x ]; then
        cp RuNNer.x ${bindir}/RuNNer.x.exe
    fi

    # shared library
    if [ -f libRuNNer.dll ]; then
        cp libRuNNer.dll ${bindir}/libRuNNer.dll
    elif [ -f libRuNNer.so ]; then
        cp libRuNNer.so ${bindir}/libRuNNer.dll
    fi
elif [[ "${target}" == *apple* ]]; then
    cp RuNNer.x ${bindir}/
    cp libRuNNer.so ${libdir}/libRuNNer.dylib
    cp libRuNNer.so ${libdir}/
else
    cp RuNNer.x ${bindir}/
    cp libRuNNer.so ${libdir}/
fi

"""

platforms = [
    Platform("x86_64", "linux"; libc="glibc", libgfortran_version=v"5.0.0"),
    Platform("x86_64", "linux"; libc="musl", libgfortran_version=v"5.0.0"),
    Platform("x86_64", "macos"; libgfortran_version=v"5.0.0"),
    Platform("aarch64", "macos"; libgfortran_version=v"5.0.0"),
    Platform("x86_64", "windows"; libgfortran_version=v"5.0.0"),
    #Platform("aarch64", "linux"; libc="glibc"),  no quadmath support in glibc for aarch64
    #Platform("aarch64", "linux"; libc="musl"), no quadmath support in musl
]

#platforms = expand_gfortran_versions(platforms)

products = [
    LibraryProduct("libRuNNer", :libRuNNer),
    ExecutableProduct("RuNNer.x", :RuNNer_x),
]

dependencies = [
    Dependency("OpenBLAS32_jll"),
    Dependency(Pkg.PackageSpec(name="CompilerSupportLibraries_jll",
                       uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

@show platforms
#build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
build_tarballs(
    ARGS, name, version, sources, script, platforms, products, dependencies;
    compilers=[:c, :fortran],
    preferred_gcc_version=v"10",
    julia_compat="1.6",
)