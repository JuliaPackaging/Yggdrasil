PROJECT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
include ../../common.mk


$(PROJECT_BUILD)/$(PROJECT_NAME).o: $(PROJECT_NAME).f | $(PROJECT_BUILD)
	$(call color,$(FC),-o $@ $(FFLAGS) -c $<)
$(PROJECT_BUILD)/$(PROJECT_NAME)$(exeext): $(PROJECT_BUILD)/$(PROJECT_NAME).o
	$(call color,$(CC),-o $@ $(LDFLAGS) -lgfortran -lquadmath -lm $<)
