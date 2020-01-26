# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Julia"
version = v"1.3.1"

sources = Dict(
	"x86_64-w64-mingw32" => ["https://julialang-s3.julialang.org/bin/winnt/x86/1.3/julia-1.3.1-win32.exe" => "6f2255d7e1707af00549f06b334d7794c4cde5a1eb92776e31142fdf294768be"], 
   	"i686-w64-mingw32" => ["https://julialang-s3.julialang.org/bin/winnt/x64/1.3/julia-1.3.1-win64.exe" => "8350ca66f80484c5ca6f7341ffbdb9d5182f8d4231762d585e229567b227ef7f"],
	"i686-linux-gnu" => ["https://julialang-s3.julialang.org/bin/linux/x86/1.3/julia-1.3.1-linux-i686.tar.gz" => "2cef14e892ac317707b39d2afd9ad57a39fb77445ffb7c461a341a4cdf34141a"],
	"x86_64-linux-gnu" => ["https://julialang-s3.julialang.org/bin/linux/x64/1.3/julia-1.3.1-linux-x86_64.tar.gz" => "faa707c8343780a6fe5eaf13490355e8190acf8e2c189b9e7ecbddb0fa2643ad"],
	"arm-linux-gnueabihf" => ["https://julialang-s3.julialang.org/bin/linux/armv7l/1.3/julia-1.3.1-linux-armv7l.tar.gz" => "965c8fab2214f8ce1b3d449d088561a6de61be42543b48c3bbadaed5b02bf824"],
	"x86_64-linux-aarch64" => ["https://julialang-s3.julialang.org/bin/linux/aarch64/1.3/julia-1.3.1-linux-aarch64.tar.gz" => "e028e64f29faa823557819cf4d5887c0b41c28b5225b60f5f2e5e2f38d453458"],
	"x86_64-freebsd" => ["https://julialang-s3.julialang.org/bin/freebsd/x64/1.3/julia-1.3.1-freebsd-x86_64.tar.gz" => "a6fb3edbc4f892a9e3a9f3684b2dc47afb7f4c8d08133db437002432d8aa5fa4"], 
	"x86_64-apple-darwin14" => ["https://julialang-s3.julialang.org/bin/mac/x64/1.3/julia-1.3.1-mac64.dmg" => "b3df0bfde44c16688c140ac94358fcae8c3e4dcb14a68576054e667370cf86f1"]
)

# Bash recipe for building across all platforms
script = raw"""
echo ${target}
if [[ ${target} == x86_64-*mingw* ]]; then
	apk add p7zip
	7z e *julia-1.3.1-win64.exe
	cd ${prefix}
	7z x ${WORKRSPACE}/srcdir/julia-installer.exe
elif [[ ${target} == i686-*mingw* ]]; then
	apk add p7zip
	7z e *julia-1.3.1-win32.exe
	cd ${prefix}
	7z x ${WORKRSPACE}/srcdir/julia-installer.exe
elif [[ ${target} == arm-linux-gnueabihf ]]; then
	cd ${prefix}
	rsync -a ${WORKSPACE}/srcdir/julia-1.3.1/ .
elif [[ ${target} == x86_64-linux-gnu ]]; then
	cd ${prefix}
	rsync -a ${WORKSPACE}/srcdir/julia-1.3.1/ .
elif [[ ${target} == i686-linux-gnu ]]; then
	cd ${prefix}
	rsync -a ${WORKSPACE}/srcdir/julia-1.3.1/ .
elif [[ ${target} == x86_64-apple-darwin* ]]; then
	cd ${prefix}
	apk add p7zip
	7z x *julia-1.3.1-mac64.dmg
else
	echo "ERROR: Unsupported platform ${target}" >&2
        exit 1
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:x86_64; libc=:glibc),
    Linux(:i686; libc=:glibc),
    Windows(:x86_64;),
    Windows(:i686;),
    MacOS(:x86_64)
]

# The products that we will ensure are always built
products = Product[
    ExecutableProduct("julia", :julia),
    LibraryProduct("libjulia", :libjulia),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

include("../../fancy_toys.jl")

# Build the tarballs, and possibly a `build.jl` as well.
for p in platforms
	should_build_platform(triplet(p)) && build_tarballs(ARGS, name, version, sources[triplet(p)], script, [p], products, dependencies)
end

