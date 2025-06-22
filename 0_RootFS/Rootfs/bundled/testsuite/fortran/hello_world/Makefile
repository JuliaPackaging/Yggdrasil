PROJECT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
BINS = $(PROJECT_NAME)$(exeext)

include ../../common.mk

# ppc64le sometimes requires -lm because it's bugged.  It doesn't hurt us to include it, so we do it everywhere
CFLDFLAGS = -lgfortran -lm

# On armv7l, aarch64, powerpc64le, and risc-v libquadmath doesn't exist!
# https://gcc.gnu.org/bugzilla/show_bug.cgi?id=85440
ifeq (,$(findstring arm-,$(target))$(findstring aarch64,$(target))$(findstring powerpc64le,$(target))$(findstring riscv,$(target)))
CFLDFLAGS += -lquadmath
endif

$(PROJECT_BUILD)/$(PROJECT_NAME).o: $(PROJECT_NAME).f | $(PROJECT_BUILD)
	$(call color,$(FC),-o $@ $(FFLAGS) -c $<)
$(PROJECT_BUILD)/$(PROJECT_NAME)$(exeext): $(PROJECT_BUILD)/$(PROJECT_NAME).o
	@# We want to compare linking with $(CC) as well as fully linking with $(FC)
	$(call color,$(CC),-o $@ $(CFLAGS) $(LDFLAGS) $< $(CFLDFLAGS))
	$(call color,$(FC),-o $@ $(FFLAGS) $(LDFLAGS) $(PROJECT_NAME).f)
