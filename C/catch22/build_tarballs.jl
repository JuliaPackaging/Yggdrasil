# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "catch22"
version = v"0.2.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/chlubba/catch22.git", "96fc2c39f1f3dee0ca990667f999469754760af0")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd catch22/C/
echo -e 'CFLAGS = -fPIC\nLDFLAGS = -shared\nRM = rm -f\nTARGET_LIB = "lib${SRC_NAME}.${dlext}"\nSRCS = main.c CO_AutoCorr.c DN_HistogramMode_10.c DN_HistogramMode_5.c DN_OutlierInclude.c FC_LocalSimple.c IN_AutoMutualInfoStats.c MD_hrv.c PD_PeriodicityWang.c SB_BinaryStats.c SB_CoarseGrain.c SB_MotifThree.c SB_TransitionMatrix.c SC_FluctAnal.c SP_Summaries.c butterworth.c fft.c helper_functions.c histcounts.c splinefit.c stats.c\nOBJS = $(SRCS:.c=.o)\n.PHONY: all\nall: ${TARGET_LIB}\n$(TARGET_LIB): $(OBJS);    $(CC) ${LDFLAGS} -o $@ $^\n$(SRCS:.c=.d):%.d:%.c;$(CC) $(CFLAGS) -MM $< >$@\ninclude $(SRCS:.c=.d)\n.PHONY: clean\nclean:-${RM} ${TARGET_LIB} ${OBJS} $(SRCS:.c=.d)' >> Makefile
make
mkdir "${libdir}"
cp "./lib${SRC_NAME}.${dlext}" "${libdir}/lib${SRC_NAME}.${dlext}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libcatch22", :ccatch22)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"9.1.0", preferred_llvm_version = v"9.0.1")
