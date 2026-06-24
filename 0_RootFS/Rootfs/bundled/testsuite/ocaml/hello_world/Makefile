PROJECT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
BINS = $(PROJECT_NAME)$(exeext)

include ../../common.mk

$(PROJECT_BUILD)/$(PROJECT_NAME)$(exeext): $(PROJECT_NAME).ml
	$(call color,$(OCAMLOPT),-o $@ $<)
