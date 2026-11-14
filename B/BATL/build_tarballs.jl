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
set -ex
# Setup OS variable
if [[ "${target}" == *linux* ]]; then
    OS="Linux"
elif [[ "${target}" == *apple* ]]; then
    OS="Darwin"
elif [[ "${target}" == *w64* ]]; then
    OS="Windows"
elif [[ "${target}" == *freebsd* ]]; then
    OS="FreeBSD"
else
    OS="Linux"
fi

# Define C++ library to link against
if [[ "${target}" == *apple* ]]; then
    LIB_STDCXX="-lc++"
else
    LIB_STDCXX="-lstdc++"
fi

cd ${WORKSPACE}/srcdir

# Setup SWMF directory structure
mv srcBATL BATL
mkdir -p GM/BATSRUS
mv BATL GM/BATSRUS/srcBATL

# Run CreateModMpi.pl to generate ModMpiInterfaces.f90
(cd share/Library/src && perl ../../Scripts/CreateModMpi.pl)

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
cat <<EOF > Makefile.conf
WORKSPACE=${WORKSPACE}
EOF
cat <<'EOF' >> Makefile.conf
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
SEARCH=-J$(WORKSPACE)/srcdir/include -I$(WORKSPACE)/srcdir/include
INC=-I$(WORKSPACE)/srcdir/include
CFLAG=$(SEARCH) -c -w -cpp -fPIC -DTESTACC
Cflag0=$(CFLAG) $(PRECISION) -O0
Cflag1=$(CFLAG) $(PRECISION) -O1
Cflag2=$(CFLAG) $(PRECISION) -O2
Cflag3=$(CFLAG) $(PRECISION) -O3
Cflag4=$(CFLAG) $(PRECISION) -O4
INCLDIR=$(WORKSPACE)/srcdir/include
SCRIPTDIR=$(WORKSPACE)/srcdir/share/Scripts

FLAGC = $(INC) -c $(OPT3) -fPIC
FLAGCC = $(FLAGC) -std=c++17

.SUFFIXES:
.SUFFIXES: .f90 .F90 .f .c .cpp .o

.f90.o:
	$(COMPILE.f90) $(Cflag3) $<

.F90.o:
	$(COMPILE.f90) $(Cflag3) $<

.f.o:
	$(COMPILE.f77) $(Cflag3) $<

.c.o:
	$(COMPILE.c) $(FLAGC) $< -o $@

.cpp.o:
	$(COMPILE.mpicxx) $(FLAGCC) $< -o $@
EOF

# Conditionally add -fallow-argument-mismatch for gfortran 10+
if [[ $(gfortran -dumpversion | cut -d. -f1) -ge 10 ]]; then
    sed -i 's/DTESTACC/DTESTACC -fallow-argument-mismatch/' Makefile.conf
fi

# Ensure literal tabs in Makefile.conf
sed -i 's/^[[:space:]]\+/\t/' Makefile.conf


cat <<EOF > Makefile.def
OS=${OS}
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
# Combine static libraries into the shared library.
if [[ "${target}" == *apple* ]]; then
    # On macOS we use -Wl,-force_load for each archive.
    mpif90 -shared -fPIC -o ${libdir}/libBATL.${dlext} \
        -Wl,-force_load,./libBATL.a \
        -Wl,-force_load,${libdir}/libSHARE.a \
        -Wl,-force_load,${libdir}/libTIMING.a \
        ${LIB_STDCXX}
else
    # On Linux/FreeBSD we use -Wl,--whole-archive.
    mpif90 -shared -fPIC -o ${libdir}/libBATL.${dlext} \
        -Wl,--whole-archive \
        ./libBATL.a \
        ${libdir}/libSHARE.a \
        ${libdir}/libTIMING.a \
        -Wl,--no-whole-archive \
        ${LIB_STDCXX}
fi

# Remove static libraries so they are not packaged
rm ${libdir}/libSHARE.a ${libdir}/libTIMING.a

# Install license file
install_license LICENSE.txt
"""

script = script_header * script_body

platforms = supported_platforms()
# Filter out Windows for now as it requires more complex MPI handling
filter!(p -> !Sys.iswindows(p), platforms)
platforms = expand_gfortran_versions(platforms)
platforms = expand_cxxstring_abis(platforms)
products = [
    LibraryProduct("libBATL", :libBATL)
]

dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("MPICH_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"9")
