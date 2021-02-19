using BinaryBuilder

# Collection of sources required to build SHTOOLS
name = "SHTOOLS"
version = v"4.8"
sources = [
    ArchiveSource("https://github.com/SHTOOLS/SHTOOLS/releases/download/v4.8/SHTOOLS-4.8.tar.gz",
                  "c36fc86810017e544abbfb12f8ddf6f101a1ac8b89856a76d7d9801ffc8dac44"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/SHTOOLS-*

# Patch source code
patch -p0 <<'EOF'
--- src/Makefile.orig	2021-02-16 19:24:29.000000000 -0500
+++ src/Makefile	2021-02-16 19:24:46.000000000 -0500
@@ -80,10 +80,10 @@
 	@echo "--> Compilation of source files successful"
 	@echo
 	@rm -f $(PROG)
-	$(LIBTOOL) $(LIBTOOLFLAGS) -o $(PROG) $(OBJS)
+#	$(LIBTOOL) $(LIBTOOLFLAGS) -o $(PROG) $(OBJS)
 #	If you prefer to use libtool, uncomment the above line, and comment the two lines below (AR and RLIB)
-#	$(AR) $(ARFLAGS) $(PROG) $(OBJS)
-#	$(RLIB) $(RLIBFLAGS) $(PROG)
+	$(AR) $(ARFLAGS) $(PROG) $(OBJS)
+	$(RLIB) $(RLIBFLAGS) $(PROG)
 	@echo
 	@echo "--> Creation of static library successful"
 #	@rm -f $(OBJS)
EOF

# Build and install static libraries
make fortran -j${nproc} F95FLAGS="-fPIC -O3 -std=gnu"
make fortran-mp -j${nproc} F95FLAGS="-fPIC -O3 -std=gnu"
make install PREFIX=${prefix}

# Create shared libraries
gfortran -shared -o ${libdir}/libSHTOOLS.${dlext} -Wl,$(flagon --whole-archive) ${prefix}/lib/libSHTOOLS.a -Wl,$(flagon --no-whole-archive | cut -d' ' -f1) -lfftw3 -lopenblas -lm
gfortran -fopenmp -shared -o ${libdir}/libSHTOOLS-mp.${dlext} -Wl,$(flagon --whole-archive) ${prefix}/lib/libSHTOOLS-mp.a -Wl,$(flagon --no-whole-archive | cut -d' ' -f1) -lfftw3 -lopenblas -lm
"""

platforms = expand_gfortran_versions(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libSHTOOLS", :libSHTOOLS),
    LibraryProduct("libSHTOOLS-mp", :libSHTOOLS_mp),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("FFTW_jll"),
    Dependency("OpenBLAS32_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"5")
