# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "catchaMouse16"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/DynamicsAndNeuralSystems/catchaMouse16.git",
              "2a952451acf6114de562da6007e37ff6e013b157")
]

# Bash recipe for building across all platforms
makefile = raw"""
CC = cc
CFLAGS = -std=c99 -fPIC -Wall -Wextra -g -O2 -lm -lgsl -lgslcblas
LDFLAGS = -shared -lm -lgsl -lgslcblas
RM = rm -f
TARGET_LIB = "lib$(SRC_NAME).$(dlext)"

SRCS = main.c fft.c stats.c helper_functions.c histcounts.c CO_AddNoise.c CO_AutoCorr.c CO_HistogramAMI.c CO_NonlinearAutocorr.c CO_TranslateShape.c DN_RemovePoints.c FC_LoopLocalSimple.c IN_AutoMutualInfoStats.c PH_Walker.c SC_FluctAnal.c ST_LocalExtrema.c SY_DriftingMean.c SY_SlidingWindow.c

OBJS = $(SRCS:.c=.o)
.PHONY: all;
all: ${TARGET_LIB}
$(TARGET_LIB): $(OBJS)
	$(CC) ${LDFLAGS} -o $@ $^
$(SRCS:.c=.d):%.d:%.c
	$(CC) $(CFLAGS) -MM $< >$@\ninclude $(SRCS:.c=.d)
.PHONY: clean
clean:-${RM} ${TARGET_LIB} ${OBJS} $(SRCS:.c=.d)
.PHONY: install
install:
	install -Dvm 755 "./lib${SRC_NAME}.${dlext}" "${libdir}/lib${SRC_NAME}.${dlext}"
"""
script = raw"""
cd $WORKSPACE/srcdir
cd catchaMouse16/C/src/
echo -e '""" * makefile * raw"""' >> Makefile
    make -j${nproc}
    make install
    """

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=Sys.iswindows) # gsl fails to link on mingw?

# The products that we will ensure are always built
products = [
    LibraryProduct("libcatchaMouse16", :libcatchaMouse16)
]

# Dependencies that must be installed before this package can be built
dependencies = [Dependency("GSL_jll"; compat="~2.7.2")]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version = v"9.1.0", julia_compat = "1.6")
