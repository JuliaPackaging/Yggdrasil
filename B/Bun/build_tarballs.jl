# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Bun"
version = v"1.2.10"

release_url = "https://github.com/oven-sh/bun/releases/download/bun-v$version"

# We download the SHA file to extract the SHAs of the archives
sha256sums = let 
    d = Dict{String,String}()
    sha256sums_url = "$(release_url)/SHASUMS256.txt"
    for line in eachline(download(sha256sums_url))
        sha, file = strip.(split(line, ' '; limit = 2))
        d[file] = sha
    end
    d
end

repo_SHA1 = let
    response = read(download("https://api.github.com/repos/oven-sh/bun/git/refs/tags/bun-v$(version)"), String)
    match(r"\"sha\": \"([0-9a-f]{40})\"", response).captures[1]
end

# This will store filename, arch and platform for each supported platform
data = [
    (; filename = "bun-linux-x64.zip", sha = sha256sums["bun-linux-x64.zip"], target = "x86_64-linux-gnu", platform = Platform("x86_64", "linux"; libc = "glibc")),
    (; filename = "bun-linux-aarch64.zip", sha = sha256sums["bun-linux-aarch64.zip"], target = "aarch64-linux-gnu", platform = Platform("aarch64", "linux"; libc = "glibc")),
    (; filename = "bun-darwin-x64.zip", sha = sha256sums["bun-darwin-x64.zip"], target = "x86_64-apple-darwin14", platform = Platform("x86_64", "macos")),
    (; filename = "bun-darwin-aarch64.zip", sha = sha256sums["bun-darwin-aarch64.zip"], target = "aarch64-apple-darwin20", platform = Platform("aarch64", "macos")),
    (; filename = "bun-windows-x64.zip", sha = sha256sums["bun-windows-x64.zip"], target = "x86_64-w64-mingw32", platform = Platform("x86_64", "windows")),
]


# Collection of sources required to complete build
# We start by putting the per-arch archive with the executable
sources = map(data) do d
    ArchiveSource("$release_url/$(d.filename)", d.sha; unpack_target = d.target)
end
# We add the git repo
push!(sources, GitSource("https://github.com/oven-sh/bun.git", repo_SHA1))

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/
install_license bun/LICENSE.md
mkdir "${bindir}"
install -m 755 "${target}/"*"/bun${exeext}" "${bindir}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = map(x -> x.platform, data)


# The products that we will ensure are always built
products = [
    ExecutableProduct("bun", :bun)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
