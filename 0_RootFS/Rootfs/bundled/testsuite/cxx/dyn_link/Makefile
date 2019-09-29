PROJECT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
include ../../common.mk

$(PROJECT_BUILD)/$(PROJECT_NAME)$(exeext): $(PROJECT_NAME).cc $(PROJECT_BUILD)/librepeater/librepeater.$(dlext)
	$(call color, $(CXX),-o $@ -I$(PROJECT_DIR)/librepeater -fPIC $(CPPFLAGS) $(CFLAGS) $(call rpath,librepeater) -lrepeater $(LDFLAGS) $<)

$(PROJECT_BUILD)/librepeater:
	mkdir -p $@

$(PROJECT_BUILD)/librepeater/librepeater.$(dlext): librepeater/librepeater.cc | $(PROJECT_BUILD)/librepeater
	$(call color,$(CXX),-shared -o $@ -fPIC $(CPPFLAGS) $(CFLAGS) -lm $<)

