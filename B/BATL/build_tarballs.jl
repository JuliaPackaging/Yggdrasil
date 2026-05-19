using BinaryBuilder, Pkg

# Package name and version
name = "BATL"
version = v"0.1.0"

# Collection of sources
sources = [
    GitSource("https://github.com/SWMFsoftware/srcBATL.git", "746650cc083c54fee93eeac2805619338cb497cd"),
    GitSource("https://github.com/SWMFsoftware/share.git", "2c28575a398d901915726b06bb9ab3dc1aaeb9ca"),
    GitSource("https://github.com/SWMFsoftware/util.git", "f9810c204376a0d69ef48bff9cff527dff0edc43"),
]

# Grid parameters
nI = 8; nJ = 8; nK = 8; nG = 2

script_header = """
nI=$nI; nJ=$nJ; nK=$nK; nG=$nG
"""

script_body = raw"""
cd ${WORKSPACE}/srcdir

# Setup SWMF directory structure
mv srcBATL BATL
mkdir -p GM/BATSRUS
mv BATL GM/BATSRUS/srcBATL

# Patch BATL_size.f90
sed -i "s/\bnI = [0-9]*/nI = ${nI}/" GM/BATSRUS/srcBATL/BATL_size_orig.f90
sed -i "s/\bnJ = [0-9]*/nJ = ${nJ}/" GM/BATSRUS/srcBATL/BATL_size_orig.f90
sed -i "s/\bnK = [0-9]*/nK = ${nK}/" GM/BATSRUS/srcBATL/BATL_size_orig.f90
sed -i "s/\bnG = [0-9]*/nG = ${nG}/" GM/BATSRUS/srcBATL/BATL_size_orig.f90
cp GM/BATSRUS/srcBATL/BATL_size_orig.f90 GM/BATSRUS/srcBATL/BATL_size.f90

# Disable HDF5 and Spice
cp share/Library/src/ModHdf5Utils_empty.f90 share/Library/src/ModHdf5Utils.f90
cp share/Library/src/ModSpice_empty.f90 share/Library/src/ModSpice.f90

mkdir -p include
mkdir -p ${libdir}

# Create Makefile.conf
# We use mpif90 for everything
cat <<EOF > Makefile.conf
FORTRAN_COMPILER_NAME=gfortran
FC=mpif90
CC=mpicc
CXX=mpicxx
COMPILE.f90=mpif90
COMPILE.f77=mpif90
LINK.f90=mpif90
COMPILE.c=mpicc
COMPILE.mpicc=mpicc
COMPILE.mpicxx=mpicxx
AR=ar -rs
PRECISION=-frecord-marker=4 -fdefault-real-8 -fdefault-double-8
OPT3=-O3
SEARCH=-J${WORKSPACE}/srcdir/include -I${WORKSPACE}/srcdir/include
CFLAG=\$(SEARCH) -c -w -cpp -fPIC -DTESTACC
Cflag0=\$(CFLAG) \$(PRECISION) -O0
Cflag1=\$(CFLAG) \$(PRECISION) -O1
Cflag2=\$(CFLAG) \$(PRECISION) -O2
Cflag3=\$(CFLAG) \$(PRECISION) -O3
Cflag4=\$(CFLAG) \$(PRECISION) -O4
INCLDIR=${WORKSPACE}/srcdir/include
SCRIPTDIR=${WORKSPACE}/srcdir/share/Scripts

FLAGC = \$(SEARCH) -c \$(OPT3) -fPIC
FLAGCC = \$(FLAGC) -std=c++17

.SUFFIXES:
.SUFFIXES: .f90 .F90 .f .c .cpp .o

.f90.o:
	\$(COMPILE.f90) \$(Cflag3) \$<

.F90.o:
	\$(COMPILE.f90) \$(Cflag3) \$<

.f.o:
	\$(COMPILE.f77) \$(Cflag3) \$<

.c.o:
	\$(COMPILE.c) \$(FLAGC) \$< -o \$@

.cpp.o:
	\$(COMPILE.mpicxx) \$(FLAGCC) \$< -o \$@
EOF

cat <<EOF > Makefile.def
OS=Linux
DIR=${WORKSPACE}/srcdir
EOF

ln -s ${WORKSPACE}/srcdir/Makefile.conf GM/BATSRUS/Makefile.conf
ln -s ${WORKSPACE}/srcdir/Makefile.def GM/BATSRUS/Makefile.def

# Provide dummy files
find . -name "Makefile" -exec sh -c 'd=$(dirname {}); touch $d/Makefile.DEPEND $d/Makefile.RULES' \;

# Run DEPEND
make -C share/Library/src DEPEND -f Makefile -I ${WORKSPACE}/srcdir
make -C GM/BATSRUS/srcBATL DEPEND -f Makefile -I ${WORKSPACE}/srcdir

# Build components
make -C share/Library/src LIB LIBDIR=${libdir} INCLDIR=${WORKSPACE}/srcdir/include \
    -f Makefile -I ${WORKSPACE}/srcdir
    
make -C util/TIMING/src LIB LIBDIR=${libdir} INCLDIR=${WORKSPACE}/srcdir/include \
    -f Makefile -I ${WORKSPACE}/srcdir

cd GM/BATSRUS/srcBATL
make LIB LIBDIR=${libdir} INCLDIR=${WORKSPACE}/srcdir/include \
    -f Makefile -I ${WORKSPACE}/srcdir

# Link final shared library
mpif90 -shared -fPIC -o ${libdir}/libBATL.${dlext} *.o \
    -L${libdir} -lTIMING -lSHARE -lstdc++
"""

script = script_header * script_body

platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)

products = [
    LibraryProduct("libBATL", :libBATL)
]

dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("MPICH_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"9")
