PROJECT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
include ../../common.mk

$(PROJECT_BUILD)/$(PROJECT_NAME)$(exeext): $(PROJECT_NAME).cc
	$(call color,$(CXX),-o $@ $(CPPFLAGS) $(CFLAGS) $(LDFLAGS) $<)
