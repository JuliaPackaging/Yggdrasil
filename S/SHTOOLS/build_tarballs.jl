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

# Add missing C interface for MakeGradientDH
atomic_patch -p1 <<'EOF'
diff --git a/src/cWrapper.f95 b/src/cWrapper.f95
index 6bfc7adc..01b2fe18 100644
--- a/src/cWrapper.f95
+++ b/src/cWrapper.f95
@@ -292,6 +292,27 @@
                                ,lmax_calc=lmax_calc,extend=extend,exitstatus=exitstatus)
     end subroutine cMakeGridDHC

+    subroutine cMakeGradientDH(cilm,cilm_dim,lmax,theta,phi,theta_d0,theta_d1,n,sampling&
+                                   ,lmax_calc,extend,exitstatus)  bind(c, name="MakeGradientDH")
+        use, intrinsic :: iso_c_binding
+        use shtools, only: MakeGradientDH
+        implicit none
+        integer(kind=c_int), value,intent(in) :: cilm_dim
+        real(kind=c_double), dimension(2,cilm_dim,cilm_dim),intent(in) :: cilm
+        integer(kind=c_int), value,intent(in) :: theta_d0
+        integer(kind=c_int), value,intent(in) :: theta_d1
+        real(kind=c_double), dimension(theta_d0,theta_d1),intent(out) :: theta
+        real(kind=c_double), dimension(theta_d0,theta_d1),intent(out) :: phi
+        integer(kind=c_int), value,intent(in) :: lmax
+        integer(kind=c_int), intent(out) :: n
+        integer(kind=c_int), optional,intent(in) :: sampling
+        integer(kind=c_int), optional,intent(in) :: lmax_calc
+        integer(kind=c_int), optional,intent(in) :: extend
+        integer(kind=c_int), optional,intent(out) :: exitstatus
+        call MakeGradientDH(cilm,lmax,theta,phi,n,sampling=sampling&
+                                ,lmax_calc=lmax_calc,extend=extend,exitstatus=e
xitstatus)
+    end subroutine cMakeGradientDH
+
     subroutine cSHGLQ(lmax,zero,w,plx,norm,csphase,cnorm,exitstatus)  bind(c, name="SHGLQ")
         use, intrinsic :: iso_c_binding
         use shtools, only: SHGLQ
EOF

# Don't use libtool
atomic_patch -p0 <<'EOF'
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
