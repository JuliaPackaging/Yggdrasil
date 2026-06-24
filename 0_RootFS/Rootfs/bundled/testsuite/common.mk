# Always default to "build"
build:

# Helper that uses python to calculate relative paths
define relpath
$(shell python -c 'import os.path, sys; print os.path.relpath("$1", "$2")')
endef

CCCOLOR:="\033[35m"
FLAGCOLOR:="\033[34m"
ENDCOLOR:="\033[0m"
define color
@printf '%b' $(CCCOLOR); echo -n $(1); printf ' %b' $(ENDCOLOR)$(FLAGCOLOR); echo -n $(2); printf '%b\n'$(ENDCOLOR); $(1) $(2)
endef

# The top-level directory containing all our testing apparatus
TESTSUITE_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

# Calculate the relative path from $(TESTSUITE_DIR) to $(PROJECT_DIR)
PROJECT_REL_DIR := $(call relpath,$(PROJECT_DIR),$(TESTSUITE_DIR))
PROJECT_NAME := $(notdir $(PROJECT_DIR))
PROJECT_LANG := $(notdir $(abspath $(dir $(PROJECT_DIR))))

# Inherit some things from the environment, setting dumb defaults otherwise
target ?= x86_64-linux-gnu
dlext ?= so
exeext ?=
CPPFLAGS ?=
CFLAGS ?= -g -O2

# Do not, under any circumstances, allow USE_CCACHE when testing the compiler suite
override USE_CCACHE=0
export USE_CCACHE

# Set up rpath flags for the different targets
ifneq (,$(findstring mingw,$(target)))
define rpath
-L$(PROJECT_BUILD)/$(1)
endef
else
ifneq (,$(findstring darwin,$(target)))
define rpath
-Wl,-rpath,@loader_path/$(1) -L$(PROJECT_BUILD)/$(1)
endef
else
define rpath
-Wl,-z,origin -Wl,-rpath,'$$ORIGIN/$(1)' -L$(PROJECT_BUILD)/$(1)
endef
endif
endif

# This is where we'll put build products, but place each project in its own place
BUILD_ROOT := /tmp/testsuite
PROJECT_BUILD := $(BUILD_ROOT)/$(target)/$(PROJECT_REL_DIR)

# Define some compiler defaults (they are typically overridden by `export`'ed
# variables in the BB shell)
CC ?= $(target)-cc
CXX ?= $(target)-c++
FC ?= $(target)-f77
GO ?= $(target)-go
RUSTC ?= $(target)-rustc
OCAMLOPT ?= $(target)-ocamlopt

# Create default rule for that directory so it can be created, if need be:
$(PROJECT_BUILD):
	@mkdir -p $@
$(PROJECT_BUILD)/$(PROJECT_NAME)$(exeext): | $(PROJECT_BUILD)

# By default, `build` just tries to build all of our BINS and LIBS:
build: $(addprefix $(PROJECT_BUILD)/,$(BINS)) $(addprefix $(PROJECT_BUILD)/,$(LIBS))

# Create default rule for `install`
install: build
	@mkdir -p $(bindir) $(libdir)
	@for f in $(BINS); do \
		install -m755 $(PROJECT_BUILD)/$${f} $(bindir)/$${f%$${exeext}}_$(PROJECT_LANG)$${exeext}; \
	done
	@for f in $(LIBS); do \
		install -m755 $(PROJECT_BUILD)/$${f} $(libdir); \
	done

# Create default rule for `clean`
clean:
	rm -rf $(PROJECT_BUILD)

# Create default rule for `run`
run: build
	$(call color,$(PROJECT_BUILD)/$(PROJECT_NAME),)

.PHONY: run clean




# Helper targets for debugging
define newline # a literal \n


endef
print-%:
	@echo '$*=$(subst ','\'',$(subst $(newline),\n,$($*)))'
