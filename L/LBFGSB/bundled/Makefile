FC = gfortran
FFLAGS = -O3 -fPIC -shared -Wall -fbounds-check -g -Wno-uninitialized

LIB_SEARCH_PATH = lib
OS := $(shell uname)
ifeq ($(OS), Linux)
	SHLIB_EXT := so
else ifeq ($(OS), FreeBSD)
	SHLIB_EXT := so
else ifeq ($(OS), Darwin)
	SHLIB_EXT := dylib
else
	SHLIB_EXT := dll
endif

LBFGSB  = lbfgsb.f
LINPACK = linpack.f
BLAS    = blas.f
TIMER   = timer.f

lbfgsb: $(LBFGSB) $(LINPACK) $(BLAS) $(TIMER)
	$(FC) $(LDFLAGS) $(FFLAGS) $(LBFGSB) $(LINPACK) $(BLAS) $(TIMER) -o liblbfgsb.$(SHLIB_EXT)

all: lbfgsb

install:
	mkdir -p $(WORKSPACE)/destdir/$(LIB_SEARCH_PATH)
	cp -f liblbfgsb*$(SHLIB_EXT) $(WORKSPACE)/destdir/$(LIB_SEARCH_PATH)/

.PHONY: install
