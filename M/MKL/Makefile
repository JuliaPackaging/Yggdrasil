deploy:

ifeq ($(GITHUB_TOKEN),)
$(warn GITHUB_TOKEN not exported...)
endif

JULIA ?= julia
DEBUG ?= 0

ifeq ($(DEBUG),1)
	DEBUG_FLAGS := --verbose --debug
endif


build-%:
	$(JULIA) --color=yes build_tarballs.jl --deploy $(DEBUG_FLAGS) $*

deploy: build-i686-linux-gnu build-x86_64-w64-mingw32 build-i686-w64-mingw32 build-x86_64-apple-darwin14
	# Once all those builds are done, we do our final build for x86_64-linx-gnu, but this time with --register turned on:
	$(JULIA) --color=yes build_tarballs.jl --deploy --register $(DEBUG_FLAGS) x86_64-linux-gnu

