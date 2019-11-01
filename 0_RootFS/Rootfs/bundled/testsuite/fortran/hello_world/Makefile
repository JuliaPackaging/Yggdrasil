PROJECT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
BINS = $(PROJECT_NAME)$(exeext)

include ../../common.mk

# On aarch64 and powerpc64le, libquadmath doesn't exist!
# https://gcc.gnu.org/bugzilla/show_bug.cgi?id=85440
ifeq (,$(findstring aarch64,$(target)$(findstring powerpc64le,$(target))))
LDFLAGS += -lquadmath
endif

$(PROJECT_BUILD)/$(PROJECT_NAME).o: $(PROJECT_NAME).f | $(PROJECT_BUILD)
	$(call color,$(FC),-o $@ $(FFLAGS) -c $<)
$(PROJECT_BUILD)/$(PROJECT_NAME)$(exeext): $(PROJECT_BUILD)/$(PROJECT_NAME).o
	$(call color,$(CC),-o $@ $(LDFLAGS) -lgfortran -lm $<)
