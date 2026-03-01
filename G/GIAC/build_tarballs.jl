# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
# inside julia, run once: using Pkg; Pkg.add("BinaryBuilder")
# example of command to build a giac package for one architecture
# julia build_tarballs.jl --verbose --debug x86_64-w64-mingw32
# sha256sum giac-2.0.0.tar.gz must be run and copied as 2nd arg of ArchiveSource below


using BinaryBuilder, Pkg

name = "GIAC"
version = v"2.0.0"

# Collection of sources required to build GIAC
sources = [
  ArchiveSource("https://www-fourier.univ-grenoble-alpes.fr/~parisse/giac/giac-$(version).tar.gz",
    "6abfab95bae0981201498ce0dd6086da65ab0ff45f96ef6dd7d766518f6741f4"
  ),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/giac-*

# Update config.sub/config.guess to recognize newer platforms (musl, etc.)

update_configure_scripts
autoreconf -fi

export CXXFLAGS='-g -Os -fPIC'

if [[ "${target}" == *freebsd* ]] || [[ "${target}" == *-apple-* ]]; then
    export CC=gcc
    export CFLAGS='-g -fPIC'
    export CXX=g++
    export CXXFLAGS='-g -fPIC -DGIAC_JULIA'
fi

# Configure with minimal dependencies
# GMP and MPFR are found automatically in ${prefix}
./configure --prefix=${prefix} \
    --disable-rpath \
    --build=${MACHTYPE} \
    --host=${target} \
    --enable-shared \
    --enable-gettext \
    --disable-libbf \
    --disable-static \
    --disable-gui \
    --disable-fltk \
    --disable-pari \
    --disable-ntl \
    --disable-ecm \
    --disable-cocoa \
    --disable-ao \
    --disable-micropy \
    --disable-quickjs \
    --disable-samplerate \
    --disable-curl \
    --disable-glpk \
    --disable-gsl \
    --disable-lapack \
    --disable-png

GIAC_CXXFLAGS="-g -fPIC -DGIAC_JULIA -U_GLIBCXX_ASSERTIONS -DUSE_OBJET_BIDON -fno-strict-aliasing -DGIAC_GENERIC_CONSTANTS -DTIMEOUT"

GIAC_OBJS="input_lexer.o sym2poly.o gausspol.o threaded.o moyal.o maple.o ti89.o mathml.o misc.o permu.o quater.o desolve.o input_parser.o symbolic.o index.o modpoly.o modfactor.o ezgcd.o derive.o solve.o intg.o intgab.o risch.o lin.o series.o subst.o vecteur.o sparse.o csturm.o tex.o global.o ifactor.o alg_ext.o gauss.o isom.o plot.o plot3d.o rpn.o prog.o pari.o cocoa.o unary.o usual.o identificateur.o gen.o tinymt32.o first.o TmpLESystemSolver.o TmpFGLM.o help.o lpsolve.o optimization.o signalprocessing.o graphe.o graphtheory.o nautywrapper.o markup.o kdisplay.o kadd.o caseval.o cutils.o graphic.o libbf.o libregexp.o libunicode.o qjsgiac.o quickjs.o quickjs-libc.o js.o qrcodegen.o"

XCAS_OBJS="History.o Input.o Xcas1.o Equation.o Print.o Tableur.o Editeur.o Graph.o Graph3d.o Help1.o Cfg.o Flv_CStyle.o Flve_Check_Button.o Flve_Input.o Flv_Style.o Flv_Data_Source.o Flve_Combo.o Flv_List.o Flv_Table.o gl2ps.o Python.o"

# Set platform-specific link flags
LINK_LIBS="-lintl -lpthread -lm -lmpfr -lgmp"
if [[ "${target}" != *mingw* ]]; then
  LINK_LIBS="-ldl ${LINK_LIBS}"
fi
if [[ "${target}" != *-apple-* ]] && [[ "${target}" != *mingw* ]]; then
  LINK_LIBS="-lrt ${LINK_LIBS}"
fi
if [[ "${target}" == *-apple-* ]]; then
  LINK_LIBS="-L${libdir} -lopenblas ${LINK_LIBS}"
fi
if [[ "${target}" == *mingw* ]]; then
  MAKE_LDFLAGS="-no-undefined ${LDFLAGS}"
fi

# Build object files (same for all platforms)
cd src
make ${MAKE_LDFLAGS:+LDFLAGS="$MAKE_LDFLAGS"} -j${nproc} libgiac.la libxcas.la icas.o xcas.o aide.o
cd .libs

# Build and install shared libraries (naming differs per platform)
if [[ "${target}" == *-apple-* ]]; then
  g++ ${GIAC_CXXFLAGS} -dynamiclib -o libgiac.0.dylib ${GIAC_OBJS} ${LINK_LIBS} \
    -install_name ${prefix}/lib/libgiac.0.dylib -current_version 0.0.0 -compatibility_version 0.0.0
  g++ ${GIAC_CXXFLAGS} -dynamiclib -o libxcas.0.dylib ${XCAS_OBJS} -L. -lgiac ${LINK_LIBS} \
    -install_name ${prefix}/lib/libxcas.0.dylib -current_version 0.0.0 -compatibility_version 0.0.0
  /usr/bin/install -c libgiac.0.dylib ${libdir}/libgiac.0.dylib
  (cd ${libdir} && ln -sf libgiac.0.dylib libgiac.dylib)
  /usr/bin/install -c libxcas.0.dylib ${libdir}/libxcas.0.dylib
  (cd ${libdir} && ln -sf libxcas.0.dylib libxcas.dylib)
elif [[ "${target}" == *mingw* ]]; then
  g++ ${GIAC_CXXFLAGS} -shared -o libgiac-0.dll ${GIAC_OBJS} ${LINK_LIBS} -Wl,--out-implib,libgiac.dll.a
  g++ ${GIAC_CXXFLAGS} -shared -o libxcas-0.dll ${XCAS_OBJS} -L. -lgiac ${LINK_LIBS} -Wl,--out-implib,libxcas.dll.a
  /usr/bin/install -c libgiac-0.dll ${libdir}/libgiac-0.dll
  /usr/bin/install -c libgiac.dll.a ${libdir}/libgiac.dll.a
  /usr/bin/install -c libxcas-0.dll ${libdir}/libxcas-0.dll
  /usr/bin/install -c libxcas.dll.a ${libdir}/libxcas.dll.a
else
  # Linux and FreeBSD
  g++ ${GIAC_CXXFLAGS} -shared -o libgiac.so.0.0.0 ${GIAC_OBJS} ${LINK_LIBS}
  g++ ${GIAC_CXXFLAGS} -shared -o libxcas.so.0.0.0 ${XCAS_OBJS} -L. -lgiac ${LINK_LIBS}
  /usr/bin/install -c libgiac.so.0.0.0 ${libdir}/libgiac.so.0.0.0
  (cd ${libdir} && ln -sf libgiac.so.0.0.0 libgiac.so.0 && ln -sf libgiac.so.0.0.0 libgiac.so)
  /usr/bin/install -c libxcas.so.0.0.0 ${libdir}/libxcas.so.0.0.0
  (cd ${libdir} && ln -sf libxcas.so.0.0.0 libxcas.so.0 && ln -sf libxcas.so.0.0.0 libxcas.so)
fi

cd ..

# Build and install executables (unified for all platforms)
EXE_EXT=""
if [[ "${target}" == *mingw* ]]; then
  EXE_EXT=".exe"
fi
g++ ${GIAC_CXXFLAGS} -o icas${EXE_EXT} icas.o -L.libs -lgiac -lxcas ${LINK_LIBS}
g++ ${GIAC_CXXFLAGS} -o xcas${EXE_EXT} xcas.o -L.libs -lgiac -lxcas ${LINK_LIBS}
g++ ${GIAC_CXXFLAGS} -o aide${EXE_EXT} aide.o -L.libs -lgiac -lxcas ${LINK_LIBS}
/usr/bin/install -c icas${EXE_EXT} xcas${EXE_EXT} aide${EXE_EXT} ${bindir}/

cd ..

# Install aide_cas
mkdir -p ${prefix}/share/giac
cp -r doc/aide_cas ${prefix}/share/giac/

install_license COPYING
"""

# Build for all supported platforms
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libgiac", :libgiac),
    LibraryProduct("libxcas", :libxcas),
    ExecutableProduct("icas", :icas),
    ExecutableProduct("xcas", :xcas),
    ExecutableProduct("aide", :aide),
    FileProduct("share/giac/aide_cas", :aide_cas),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency("Gettext_jll"),
    Dependency("GettextRuntime_jll"),
    Dependency("GMP_jll", v"6.3.0"),
    Dependency("MPFR_jll", v"4.1.1"),
    Dependency("OpenBLAS32_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
# Use GCC 7+ for C++17 support
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
  preferred_gcc_version=v"7", julia_compat="1.6")
