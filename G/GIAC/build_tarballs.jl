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

if [[ "${target}" == *freebsd* ]]; then
    export CC=gcc
    export CFLAGS='-g -fPIC'
    export CXX=g++
    export CXXFLAGS='-g -fPIC -DGIAC_JULIA'
elif [[ "${target}" == *-apple-* ]]; then
    export CC=gcc
    export CFLAGS='-g -fPIC'
    export CXX=g++
    export CXXFLAGS='-g -fPIC -DGIAC_JULIA'
fi

GETTEXT_FLAG="--enable-gettext"
if [[ "${target}" == *freebsd* ]]; then
    # FreeBSD doesn't have libintl available through Gettext_jll
    GETTEXT_FLAG="--disable-gettext"
fi

# Configure with minimal dependencies
# GMP and MPFR are found automatically in ${prefix}
./configure --prefix=${prefix} \
    --disable-rpath \
    --build=${MACHTYPE} \
    --host=${target} \
    --enable-shared \
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
    --disable-png \
    ${GETTEXT_FLAG}

GIAC_CXXFLAGS="-g -fPIC -DGIAC_JULIA -U_GLIBCXX_ASSERTIONS -DUSE_OBJET_BIDON -fno-strict-aliasing -DGIAC_GENERIC_CONSTANTS -DTIMEOUT"

GIAC_OBJS="input_lexer.o sym2poly.o gausspol.o threaded.o moyal.o maple.o ti89.o mathml.o misc.o permu.o quater.o desolve.o input_parser.o symbolic.o index.o modpoly.o modfactor.o ezgcd.o derive.o solve.o intg.o intgab.o risch.o lin.o series.o subst.o vecteur.o sparse.o csturm.o tex.o global.o ifactor.o alg_ext.o gauss.o isom.o plot.o plot3d.o rpn.o prog.o pari.o cocoa.o unary.o usual.o identificateur.o gen.o tinymt32.o first.o TmpLESystemSolver.o TmpFGLM.o help.o lpsolve.o optimization.o signalprocessing.o graphe.o graphtheory.o nautywrapper.o markup.o kdisplay.o kadd.o caseval.o cutils.o graphic.o libbf.o libregexp.o libunicode.o qjsgiac.o quickjs.o quickjs-libc.o js.o qrcodegen.o"

XCAS_OBJS="History.o Input.o Xcas1.o Equation.o Print.o Tableur.o Editeur.o Graph.o Graph3d.o Help1.o Cfg.o Flv_CStyle.o Flve_Check_Button.o Flve_Input.o Flv_Style.o Flv_Data_Source.o Flve_Combo.o Flv_List.o Flv_Table.o gl2ps.o Python.o"

if [[ "${target}" == *freebsd* ]]; then
  cd src
  make -j${nproc} libgiac.la libxcas.la icas.o xcas.o aide.o
  cd .libs
  g++ ${GIAC_CXXFLAGS} -shared -o libgiac.so.0.0.0 ${GIAC_OBJS} -lrt -lpthread -ldl -lm -lmpfr -lgmp
  g++ ${GIAC_CXXFLAGS} -shared -o libxcas.so.0.0.0 ${XCAS_OBJS} -L. -lgiac -lrt -lpthread -ldl -lm -lmpfr -lgmp
  cd ..
  /usr/bin/install -c .libs/libxcas.so.0.0.0 /workspace/destdir/lib/libxcas.so.0.0.0
  (cd /workspace/destdir/lib && { ln -s -f libxcas.so.0.0.0 libxcas.so.0 || { rm -f libxcas.so.0 && ln -s libxcas.so.0.0.0 libxcas.so.0; }; })
  /usr/bin/install -c .libs/libxcas.lai /workspace/destdir/lib/libxcas.la
  g++ ${GIAC_CXXFLAGS} -o icas icas.o -L.libs -lgiac -lxcas -lrt -lpthread -ldl -lm -lmpfr -lgmp
  g++ ${GIAC_CXXFLAGS} -o xcas xcas.o -L.libs -lgiac -lxcas -lrt -lpthread -ldl -lm -lmpfr -lgmp
  g++ ${GIAC_CXXFLAGS} -o aide aide.o -L.libs -lgiac -lxcas -lrt -lpthread -ldl -lm -lmpfr -lgmp
  cd ..
  # make install fails relinking libxcas (already installed manually above), so ignore errors
  make -i install

  # Explicitly install aide_cas for FreeBSD
  mkdir -p ${prefix}/share/giac
  cp -r doc/aide_cas ${prefix}/share/giac/

elif [[ "${target}" == x86_64-apple-* ]]; then
  cd src
  make -j${nproc} libgiac.la libxcas.la icas.o xcas.o aide.o
  cd .libs
  # GIAC has unguarded LAPACK symbols in vecteur.o; macOS ld is strict about missing symbols.
  # Use -framework Accelerate to satisfy them (provides BLAS/LAPACK).
  g++ ${GIAC_CXXFLAGS} -dynamiclib -o libgiac.0.dylib ${GIAC_OBJS} -lintl -lpthread -lm -lmpfr -lgmp -framework Accelerate -install_name ${prefix}/lib/libgiac.0.dylib -current_version 0.0.0 -compatibility_version 0.0.0
  g++ ${GIAC_CXXFLAGS} -dynamiclib -o libxcas.0.dylib ${XCAS_OBJS} -L. -lgiac -lintl -lpthread -lm -lmpfr -lgmp -install_name ${prefix}/lib/libxcas.0.dylib -current_version 0.0.0 -compatibility_version 0.0.0
  cd ..
  /usr/bin/install -c .libs/libxcas.0.dylib /workspace/destdir/lib/libxcas.0.dylib
  (cd /workspace/destdir/lib && { ln -s -f libxcas.0.dylib libxcas.dylib || { rm -f libxcas.dylib && ln -s libxcas.0.dylib libxcas.dylib; }; })
  /usr/bin/install -c .libs/libxcas.lai /workspace/destdir/lib/libxcas.la
  g++ ${GIAC_CXXFLAGS} -o icas icas.o -L.libs -lgiac -lxcas -lintl -lpthread -ldl -lm -lmpfr -lgmp
  g++ ${GIAC_CXXFLAGS} -o xcas xcas.o -L.libs -lgiac -lxcas -lintl -lpthread -ldl -lm -lmpfr -lgmp
  g++ ${GIAC_CXXFLAGS} -o aide aide.o -L.libs -lgiac -lxcas -lintl -lpthread -ldl -lm -lmpfr -lgmp
  cd ..
  # make install fails relinking libxcas (already installed manually above), so ignore errors
  make -i install

elif [[ "${target}" == aarch64-apple-* ]]; then
  cd src
  make -j${nproc} libgiac.la libxcas.la icas.o xcas.o aide.o
  cd .libs
  g++ ${GIAC_CXXFLAGS} -dynamiclib -o libgiac.0.dylib ${GIAC_OBJS} -lintl -lpthread -lm -lmpfr -lgmp -framework Accelerate -install_name ${prefix}/lib/libgiac.0.dylib -current_version 0.0.0 -compatibility_version 0.0.0
  g++ ${GIAC_CXXFLAGS} -dynamiclib -o libxcas.0.dylib ${XCAS_OBJS} -L. -lgiac -lintl -lpthread -lm -lmpfr -lgmp -install_name ${prefix}/lib/libxcas.0.dylib -current_version 0.0.0 -compatibility_version 0.0.0
  cd ..
  /usr/bin/install -c .libs/libxcas.0.dylib /workspace/destdir/lib/libxcas.0.dylib
  (cd /workspace/destdir/lib && { ln -s -f libxcas.0.dylib libxcas.dylib || { rm -f libxcas.dylib && ln -s libxcas.0.dylib libxcas.dylib; }; })
  /usr/bin/install -c .libs/libxcas.lai /workspace/destdir/lib/libxcas.la
  g++ ${GIAC_CXXFLAGS} -o icas icas.o -L.libs -lgiac -lxcas -lintl -lpthread -ldl -lm -lmpfr -lgmp
  g++ ${GIAC_CXXFLAGS} -o xcas xcas.o -L.libs -lgiac -lxcas -lintl -lpthread -ldl -lm -lmpfr -lgmp
  g++ ${GIAC_CXXFLAGS} -o aide aide.o -L.libs -lgiac -lxcas -lintl -lpthread -ldl -lm -lmpfr -lgmp
  cd ..
  # make install fails relinking libxcas (already installed manually above), so ignore errors
  make -i install

elif [[ "${target}" == *mingw* ]]; then
  # The flag is injected only for make
  make LDFLAGS="-no-undefined ${LDFLAGS}" -j${nproc}
  make install

else
  make -j${nproc}
  make install
fi

install_license COPYING
"""

# Build for all supported platforms
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libgiac", :libgiac),
    FileProduct("share/giac/aide_cas", :aide_cas),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency("Gettext_jll"),
    Dependency("GettextRuntime_jll"),
    Dependency("GMP_jll", v"6.3.0"),
    Dependency("MPFR_jll", v"4.1.1"),
]

# Build the tarballs, and possibly a `build.jl` as well.
# Use GCC 7+ for C++17 support
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
  preferred_gcc_version=v"7", julia_compat="1.6")
