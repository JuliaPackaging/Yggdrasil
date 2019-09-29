# Default target is `buildall`, but we've also got `cleanall` and `runall`
buildall:
runall:
cleanall:

LANGUAGES=c cxx fortran go rust
PROJECTS=hello_world dyn_link

define unesc
$(subst -,/,$(subst build-,,$(subst clean-,,$(subst run-,,$1))))
endef

# Helper function that adds $(2) as a dependency to rule $(1), but only if $(2) actually exists.
define add_dep
ifneq ($(wildcard $(call unesc,$(2))/.),)
$(1): $(2)
endif
endef

# For each language, and each project within that language, add it:
$(foreach p,$(PROJECTS),$(foreach l,$(LANGUAGES),$(eval $(call add_dep,buildall,build-$(l)-$(p)))))
$(foreach p,$(PROJECTS),$(foreach l,$(LANGUAGES),$(eval $(call add_dep,cleanall,clean-$(l)-$(p)))))
$(foreach p,$(PROJECTS),$(foreach l,$(LANGUAGES),$(eval $(call add_dep,runall,build-$(l)-$(p)))))

build-%:
	@$(MAKE) -sC $(call unesc,$@)

clean-%:
	@$(MAKE) -sC $(call unesc,$@) clean

runall:
	@# `runall` serially, in a predictable pattern
	@for p in $(PROJECTS); do \
		for l in $(LANGUAGES); do \
			if [ -d $${l}/$${p} ]; then \
				$(MAKE) -sC $${l}/$${p} run; \
			fi; \
		done; \
	done;
