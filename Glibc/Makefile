VERSIONS = v2.12.2 v2.17 v2.19 v2.25

buildall:
	for v in $(VERSIONS); do \
		julia --color=yes build_tarballs.jl --verbose --debug --glibc-version $$v; \
	done

clean:
	rm -rf products/*
