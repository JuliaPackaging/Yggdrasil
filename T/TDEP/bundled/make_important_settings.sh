#!/bin/bash
GFORTRAN_VERSION=$(gfortran -dumpversion | cut -d. -f1)

# Default values
OPTIMIZATION_LEVEL="-O3" # BinaryBuilder doesnt like -Ofast cause of fastmath
# FORTRAN_COMPILER="gfortran"
FCFLAGS="-ffree-line-length-none -std=f2008 -cpp -fPIC"
FCFLAGS_EXTRA=""
DOUBLE_FLAG="-fdefault-real-8"
MODULE_FLAG="-J"
PRECOMPILER_FLAGS="-Dclusterprogressbar"
USECGAL="no"

# FORTRAN_COMPILER="gfortran"
# FORTRAN_COMPILER="mpifort"

if [ "$MACHTYPE" = "$target" ]; then
    FORTRAN_COMPILER="gfortran"
else
    FORTRAN_COMPILER="${target}-gfortran"
fi


if [[ "$GFORTRAN_VERSION" -ge 10 ]]; then
    FCFLAGS="$FCFLAGS -fallow-argument-mismatch"
else
    FCFLAGS="$FCFLAGS -Wno-argument-mismatch"
fi


# Required libraries
declare -A REQUIRED_LIBS
REQUIRED_LIBS[BLASLAPACK]="-lopenblas"
REQUIRED_LIBS[FFTW]="-lfftw3"
REQUIRED_LIBS[MPI]=$MPI_LIBS
REQUIRED_LIBS[HDF5]="-lhdf5 -lhdf5_fortran"

# Output file
outdir=$(pwd)
output_file="$outdir/important_settings"

# Write settings to file
echo "#!/bin/bash" > "$output_file"
echo "OPTIMIZATION_LEVEL=\"$OPTIMIZATION_LEVEL\"" >> "$output_file"
echo "FORTRAN_COMPILER=\"$FORTRAN_COMPILER\"" >> "$output_file"
echo "FCFLAGS=\"$FCFLAGS\"" >> "$output_file"
echo "FCFLAGS_EXTRA=\"$FCFLAGS_EXTRA\"" >> "$output_file"
echo "DOUBLE_FLAG=\"$DOUBLE_FLAG\"" >> "$output_file"
echo "MODULE_FLAG=\"$MODULE_FLAG\"" >> "$output_file"
echo "PRECOMPILER_FLAGS=\"$PRECOMPILER_FLAGS\"" >> "$output_file"
echo "USECGAL=\"$USECGAL\"" >> "$output_file"

for LIB_NAME in "${!REQUIRED_LIBS[@]}"; do
    LIBS=${REQUIRED_LIBS[$LIB_NAME]}
    echo "PATH_TO_${LIB_NAME}_LIB=\"-L${libdir}\"" >> "$output_file"
    echo "PATH_TO_${LIB_NAME}_INC=\"-I${includedir}\"" >> "$output_file"
    echo "${LIB_NAME}_LIBS=\"${LIBS}\"" >> "$output_file"
done

echo "important_settings file generated successfully."
