PROJECT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
BINS = $(PROJECT_NAME)$(exeext)

include ../../common.mk

$(PROJECT_BUILD)/$(PROJECT_NAME)$(exeext): src/main.rs
	$(call color,$(CARGO),install --verbose --path . --root $(PROJECT_BUILD))
	mv $(PROJECT_BUILD)/bin/* $(PROJECT_BUILD)/
	rm -rf $(PROJECT_BUILD)/bin
