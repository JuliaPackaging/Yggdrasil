PROJECT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
BINS = $(PROJECT_NAME)$(exeext)

include ../../common.mk

$(PROJECT_BUILD)/$(PROJECT_NAME)$(exeext): $(PROJECT_NAME).c
	@# We explicitly use `gcc` here, because openmp doesn't work in `clang`
	$(call color,gcc,-o $@ $(CPPFLAGS) $(CFLAGS) -fopenmp $(LDFLAGS) $<)

