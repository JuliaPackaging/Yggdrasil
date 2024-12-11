# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "catch22"
version = v"0.4.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/DynamicsAndNeuralSystems/catch22.git",
              "2e1a271c6a7437b6a4a754e1adc7e34d7a224c01")
]

# Bash recipe for building across all platforms
makefile = raw"""
CC = cc
CFLAGS = -std=c11 -fPIC -Wall -Wextra -g -O2 -lm
LDFLAGS = -shared -lm
RM = rm -f
TARGET_LIB = "lib$(SRC_NAME).$(dlext)"

SRCS := $(shell find ./ -name "*.c" ! -name "main.c")

OBJS = $(SRCS:.c=.o)
.PHONY: all;
all: ${TARGET_LIB}
$(TARGET_LIB): $(OBJS)
	$(CC) -o $@ $^ $(LDFLAGS) $(FLAGS)
$(SRCS:.c=.d):%.d:%.c
	$(CC) $(CFLAGS) $(FLAGS) -MM $< >$@
	include $(SRCbS:.c=.d)
.PHONY: clean
clean:
	$(RM) $(TARGET_LIB) $(OBJS) $(SRCS:.c=.d)
.PHONY: install
install:
	install -Dvm 755 "./lib${SRC_NAME}.$(dlext)" "$(libdir)/lib$(SRC_NAME).$(dlext)"
"""
script = raw"""
cd ${WORKSPACE}/srcdir
cd catch22/C/
echo -e '""" * makefile * raw"""' >> Makefile
    make -j${nproc} FLAGS="${FLAGS}"
    make install
    """

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# platforms = supported_platforms(; exclude=Sys.iswindows)
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libcatch22", :libcatch22)
]

# Dependencies that must be installed before this package can be built
dependencies = []

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version = v"9.1.0", julia_compat = "1.6")
