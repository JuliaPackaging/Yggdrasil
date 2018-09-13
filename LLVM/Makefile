# vim:noet

release:
	julia build_tarballs.jl

asserts:
	julia build_tarballs.jl --llvm-asserts

check:
	julia build_tarballs.jl --llvm-check --verbose

both:
	julia build_tarballs.jl --llvm-asserts
	julia build_tarballs.jl

buildjl:
	julia build_tarballs.jl --only-buildjl

clean:
	rm -rf build
	rm -rf products
