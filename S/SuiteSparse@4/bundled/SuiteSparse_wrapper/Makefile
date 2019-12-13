UNAME := $(shell uname)

ifeq ($(UNAME), Darwin)
    SHLIB_EXT ?= dylib
    # RPATH ?= -Wl,-rpath,'@executable_path/../lib' -Wl,-rpath,'@executable_path'
else ifeq ($(UNAME), Windows)
    SHLIB_EXT ?= dll
else
    SHLIB_EXT ?= so
    # RPATH ?= -Wl,-rpath,'$$ORIGIN/../lib' -Wl,-rpath,'$$ORIGIN'
endif

install:
	$(CC) $(CPPFLAGS) $(CFLAGS) $(LDFLAGS) -O2 -shared -fPIC -I $(prefix)/include SuiteSparse_wrapper.c -o $(libdir)/libsuitesparse_wrapper.$(SHLIB_EXT) -L $(libdir) $(RPATH) $(LDFLAGS) -lcholmod -lumfpack -lspqr
