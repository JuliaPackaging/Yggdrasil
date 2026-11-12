# Default target is `build`, but we've also got `clean` and `run`
build:
run:
clean:
install:

LANGUAGES :=

define enable_language
ifneq ($(shell which $(2)),)
LANGUAGES += $(1)
build-$(1):
run-$(1):
clean-$(1):
install-$(1):
endif
endef

$(eval $(call enable_language,c,cc))
$(eval $(call enable_language,cxx,c++))
$(eval $(call enable_language,fortran,gfortran))
$(eval $(call enable_language,go,go))
$(eval $(call enable_language,rust,rustc))
$(eval $(call enable_language,ocaml,ocamlopt))

define unesc
$(subst -,/,$1)
endef

# Helper function that adds $(2) as a dependency to rule $(1)
define add_dep
$(1): $(2)
endef

# For each language, and each project within that language, add them to the overall `build-$(lang)` targets
$(foreach l,$(LANGUAGES),$(foreach p,$(wildcard $(l)/*),$(eval $(call add_dep,build-$(l),build-project-$(l)-$(notdir $(p))))))
$(foreach l,$(LANGUAGES),$(foreach p,$(wildcard $(l)/*),$(eval $(call add_dep,clean-$(l),clean-project-$(l)-$(notdir $(p))))))
$(foreach l,$(LANGUAGES),$(foreach p,$(wildcard $(l)/*),$(eval $(call add_dep,install-$(l),install-project-$(l)-$(notdir $(p))))))

# Add all languages to the overall `build` and `clean` targets
$(foreach l,$(LANGUAGES),$(eval $(call add_dep,build,build-$(l))))
$(foreach l,$(LANGUAGES),$(eval $(call add_dep,clean,clean-$(l))))
$(foreach l,$(LANGUAGES),$(eval $(call add_dep,install,install-$(l))))

build-project-%:
	@$(MAKE) -sC $(call unesc,$*)

install-project-%:
	@$(MAKE) -sC $(call unesc,$*) install

clean-project-%:
	@$(MAKE) -sC $(call unesc,$*) clean

run-project-%:
	@$(MAKE) -sC $(call unesc,$*) run

runall:
	# Build a list of `run` targets that we can run serially, in a predictable order
	@for run_target in $(foreach l,$(LANGUAGES),$(foreach p,$(wildcard $(l)/*),run-project-$(l)-$(notdir $(p)))); do \
		@$(MAKE) $${run_target};
	done

.PHONY: build clean run install run-project-% clean-project-%

print-%:
	@echo "$*=$($*)"
