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
CFLAGS = -std=c11 -fPIC -Wall -Wextra -g -O2 -lm -lgsl -lgslcblas
LDFLAGS = -shared -lm -lgsl -lgslcblas
RM = rm -f
TARGET_LIB = "lib$(SRC_NAME).$(dlext)"

SRCS := $(shell find ./ -name "*.c")

OBJS = $(SRCS:.c=.o)
.PHONY: all;
all: ${TARGET_LIB}
$(TARGET_LIB): $(OBJS)
	$(CC) -o $@ $^ $(LDFLAGS) $(FLAGS)
$(SRCS:.c=.d):%.d:%.c
	$(CC) $(CFLAGS) $(FLAGS) -MM $< >$@
	include $(SRCS:.c=.d)
.PHONY: clean
clean:
	$(RM) $(TARGET_LIB) $(OBJS) $(SRCS:.c=.d)
.PHONY: install
install:
	install -Dvm 755 "./lib${SRC_NAME}.$(dlext)" "$(libdir)/lib$(SRC_NAME).$(dlext)"
"""
script = raw"""
cd ${WORKSPACE}/srcdir
cd catchaMouse16/C/src/
echo -e '""" * makefile * raw"""' >> Makefile
    if [[ ${target} == aarch64-apple-* ]]; then
        FLAGS="-L${libdir}/darwin -lclang_rt.osx"
    fi
    make -j${nproc} FLAGS="${FLAGS}"
    make install
    """

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# platforms = supported_platforms(; exclude=Sys.iswindows)
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libcatchaMouse16", :libcatchaMouse16)
]

# Dependencies that must be installed before this package can be built
llvm_version = v"17.0.6"
dependencies = [
    Dependency("GSL_jll"; compat = "~2.7.2"),
    # libclang_rt.osx.a is required on aarch64-macos to provide `__divdc3`.
    BuildDependency(PackageSpec(name = "LLVMCompilerRT_jll",
                                uuid = "4e17d02c-6bf5-513e-be62-445f41c75a11",
                                version = llvm_version);
                    platforms = filter(p -> Sys.isapple(p) && arch(p) == "aarch64", platforms))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version = v"9.1.0", julia_compat = "1.6", preferred_llvm_version = llvm_version)
