#//////////////////////////////////////////////////////////////////////////////
#   -- MAGMA (version 2.x) --
#      Univ. of Tennessee, Knoxville
#      Univ. of California, Berkeley
#      Univ. of Colorado, Denver
#      @date
#//////////////////////////////////////////////////////////////////////////////



# --------------------
# configuration

# should MAGMA be built on CUDA (NVIDIA only) or HIP (AMD or NVIDIA)
# enter 'cuda' or 'hip' respectively
BACKEND     ?= cuda

# set these to their real paths
CUDADIR     ?= $(prefix)/cuda

# require either hip or cuda
ifeq (,$(findstring $(BACKEND),hip cuda))
    $(error "'BACKEND' should be either 'cuda' or 'hip' (got $(BACKEND))")
endif

# --------------------
# programs

# set compilers
CC          ?= gcc
CXX         ?= g++
FORT        ?= gfortran
HIPCC       ?= hipcc
NVCC        ?= $(CUDADIR)/bin/nvcc$(exeext)
DEVCC       ?= NONE

# set from 'BACKEND'
ifeq ($(BACKEND),cuda)
    DEVCC = $(NVCC)
else ifeq ($(BACKEND),hip)
    DEVCC = $(HIPCC)
endif

# and utilities
ARCH      = ar
ARCHFLAGS = cr
RANLIB    = ranlib


# --------------------
# flags/settings

# set our GPU targets
ifeq ($(BACKEND),cuda)
    GPU_TARGET = Pascal sm_61 Volta Turing Ampere sm_86 Ada Hopper
else ifeq ($(BACKEND),hip)
    GPU_TARGET = gfx900 gfx902 gfx904 gfx906 gfx908 gfx909 gfx90a gfx940 gfx941 gfx942 gfx90c gfx1010 gfx1011 gfx1012 gfx1030 gfx1031 gfx1032 gfx1033
endif

# Use -fPIC to make shared (.so) and static (.a) library;
# can be commented out if making only static library.
FPIC      = -fPIC

# now, generate our flags
CFLAGS      = -O3 $(FPIC) -DNDEBUG -DADD_64_ -Wall -fopenmp -std=c99
CXXFLAGS    = -O3 $(FPIC) -DNDEBUG -DADD_64_ -Wall -fopenmp -std=c++11
FFLAGS      = -O3 $(FPIC) -DNDEBUG -DADD_64_ -Wall -Wno-unused-dummy-argument
F90FLAGS    = -O3 $(FPIC) -DNDEBUG -DADD_64_ -Wall -Wno-unused-dummy-argument -x f95-cpp-input
LDFLAGS     =     $(FPIC)                       -fopenmp

DEVCCFLAGS  = -O3         -DNDEBUG -DADD_64_      

# DEVCCFLAGS are populated later in `backend-specific`


# --------------------
# libraries

# gcc with OpenBLAS (includes LAPACK)
LIB       += -lblastrampoline

# We're going to spoof magma to make it believe lbt is 64-bit ints.
# Defining MAGMA_ILP64 or MKL_ILP64 changes magma_int_t to int64_t in include/magma_types.h
CFLAGS    += -DMAGMA_ILP64
CXXFLAGS  += -DMAGMA_ILP64
FFLAGS    += -fdefault-integer-8
F90FLAGS  += -fdefault-integer-8
NVCCFLAGS += -DMAGMA_ILP64

# --------------------
# directories

# define library directories preferably in your environment, or here.
LIBDIR    += -L$(libdir)
INC       += 


# --------------------
# checks

# check for openblas
# -include make.check-openblas


# --------------------
# backend-specific

# add appropriate cuda flags
ifeq ($(BACKEND),cuda)
    -include make.check-cuda

    DEVCCFLAGS += -Xcompiler "$(FPIC)" -std=c++11

    # link with cuda specific libraries
    LIB += -L$(CUDADIR)/lib64 -L$(CUDADIR)/lib -lcublas -lcusparse -lcudart -lcudadevrt
    INC += -I$(CUDADIR)/include

endif

# add appropriate HIP flags
ifeq ($(BACKEND),hip)
    -include make.check-hip

    DEVCCFLAGS += $(FPIC) -std=c++11

    #TODO: see if we need to link any HIP libraries
    #LIB += -lhip_hcc -lhsa-runtime64
    INC += -I$(HIPDIR)/include

endif
