PROJECT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
BINS = $(PROJECT_NAME)$(exeext)
LIBS = libfoo/libfoo.$(dlext)

include ../../common.mk

$(PROJECT_BUILD)/$(PROJECT_NAME)$(exeext): $(PROJECT_NAME).c $(PROJECT_BUILD)/libfoo/libfoo.$(dlext)
	$(call color, $(CC),-o $@ -I$(PROJECT_DIR)/libfoo -fPIC $(CPPFLAGS) $(CFLAGS) $(call rpath,libfoo) -lfoo $(LDFLAGS) $<)

$(PROJECT_BUILD)/libfoo:
	mkdir -p $@

$(PROJECT_BUILD)/libfoo/libfoo.$(dlext): libfoo/libfoo.c | $(PROJECT_BUILD)/libfoo
	$(call color,$(CC),-shared -o $@ -fPIC $(CPPFLAGS) $(CFLAGS) -lm $<)

