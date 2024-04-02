# Environment setup for libblastrampoline to allow the CMake FindBLAS and FindLAPACK
# scripts work with this library in the Yggdrasil environment.

set( BB_NBITS  "$ENV{nbits}" )
set( BB_TARGET "$ENV{target}" )
set( BB_DLLEXT "$ENV{dlext}" )
set( BB_LIBDIR "$ENV{libdir}" )
set( BB_INCDIR "$ENV{includedir}" )

# Allow modifying the library name of libblastrampoline to link to. This isn't
# going to be a standard option people use, but allow it just in case.
if( NOT BLASTRAMPOLINE_LIB )
    # Windows encodes the library version in the pre-extension library name
    if( BB_TARGET MATCHES ".*-mingw.*" )
        set( BLASTRAMPOLINE_LIB "blastrampoline-5" )
    else()
        set( BLASTRAMPOLINE_LIB "blastrampoline" )
    endif()
endif()

# BLASTRAMPOLINE_INTEGER can be overriden to always specify a specific integer type,
# however this will only affect the include files since libblastrampoline exports both
# ILP64 and LP64 symbols.
if( NOT BLASTRAMPOLINE_INTEGER )
    if( BB_NBITS STREQUAL "64" )
        set( BLASTRAMPOLINE_INTEGER "ILP64" )
    else()
        set( BLASTRAMPOLINE_INTEGER "LP64" )
    endif()
endif()

set( BLA_VENDOR "blastrampoline" )

# FindBLAS overrides
set( BLAS_FOUND 1 )
set( BLAS_LIBRARIES "${BB_LIBDIR}/lib${BLASTRAMPOLINE_LIB}.${BB_DLLEXT}" )
set( BLAS_LINKER_FLAGS "${BLASTRAMPOLINE_LIB}" )

# FindLAPACK overrides
set( LAPACK_FOUND 1 )
set( LAPACK_LIBRARIES "${BB_LIBDIR}/lib${BLASTRAMPOLINE_LIB}.${BB_DLLEXT}" )
set( LAPACK_LINKER_FLAGS "${BLASTRAMPOLINE_LIB}" )

# These are not actually part of the FindBLAS/FindLAPACK packages, but they will
# make life easier for consumers if they want the header files
set( BLAS_INCLUDE_DIRS "${BB_INCDIR}/libblastrampoline/${BLASTRAMPOLINE_INTEGER}/${BB_TARGET}" )
set( LAPACK_INCLUDE_DIRS "${BB_INCDIR}/libblastrampoline/${BLASTRAMPOLINE_INTEGER}/${BB_TARGET}" )

# CBLAS and LAPACKE don't have upstream CMake Find modules, but blastrampoline is complex
# enough in its pathing that it is nice to define these for possible consumers.
set( CBLAS_FOUND 1 )
set( CBLAS_LIBRARIES "${BB_LIBDIR}/lib${BLASTRAMPOLINE_LIB}.${BB_DLLEXT}" )
set( CBLAS_LINKER_FLAGS "${BLASTRAMPOLINE_LIB}" )
set( CBLAS_INCLUDE_DIRS "${BB_INCDIR}/libblastrampoline/${BLASTRAMPOLINE_INTEGER}/${BB_TARGET}" )

set( LAPACKE_FOUND 1 )
set( LAPACKE_LIBRARIES "${BB_LIBDIR}/lib${BLASTRAMPOLINE_LIB}.${BB_DLLEXT}" )
set( LAPACKE_LINKER_FLAGS "${BLASTRAMPOLINE_LIB}" )
set( LAPACKE_INCLUDE_DIRS "${BB_INCDIR}/libblastrampoline/${BLASTRAMPOLINE_INTEGER}/${BB_TARGET}" )

# Cleanup temporary variables so they don't leak into the user CMake
unset( BB_NBITS )
unset( BB_DLLEXT )
unset( BB_LIBDIR )
unset( BB_INCDIR )
unset( BB_TARGET )

