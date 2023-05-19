using BinaryBuilder, Pkg

name = "KMC"
version = v"3.2.2"

# url = "https://github.com/refresh-bio/KMC"
# description = "Fast and frugal disk based k-mer counter"

# NOTES
# - the code assumes that is either compiled on aarch64 or x86_64
# - we use gcc/g++ on macos/freebsd, as the code uses GNU extensions
#   (#include <ext/algorithm>)

# Build issues
#
# - aarch64-apple-darwin: build fails
#   [23:42:49] ld: warning: building for macOS, but linking in object file (/opt/aarch64-apple-darwin20/bin/../lib/gcc/aarch64-apple-darwin20/12.0.1/../../../../aarch64-apple-darwin20/lib/libstdc++.a(cp-demangle.o)) built for iOS
#   [23:42:49] Undefined symbols for architecture arm64:
#   [23:42:49]   "__ZN10RadulsSort17RadixSortMSD_NEONI5CKmerILj1EEEEvPT_S4_yjjP11CMemoryPool", referenced from:
#   [23:42:49]       __ZN4CKMCILj1EE18ProcessStage2_implEv in libkmc_core.a(kmc_runner.o)
#
# - x86_64-apple-darwin: linker warnings (many about visibility)
#   [23:36:43] ld: warning: direct access in function 'std::basic_ios<char, std::char_traits<char> >::copyfmt(std::basic_ios<char, std::char_traits<char> > const&)' from file '/opt/x86_64-apple-darwin14/bin/../lib/gcc/x86_64-apple-darwin14/7.1.0/../../../../x86_64-apple-darwin14/lib/libstdc++.a(ios-inst.o)' to global weak symbol 'std::ctype<char>::do_widen(char) const' from file 'kmc_tools/parameters_parser.o' means the weak symbol cannot be overridden at runtime. This was likely caused by different translation units being compiled with different visibility settings.

sources = [
    GitSource("https://github.com/refresh-bio/KMC",
              "25d29e62bc5f6d8f171d846c19aedfdd4a3b799e"),
    DirectorySource("./bundled"),
]

script = raw"""
cd $WORKSPACE/srcdir/KMC*/

atomic_patch -p1 ../patches/fix-missing-includes.patch

# the Makefile expects zlib.h,libz.a in the 3rd_party/cloudflare/ dir
ln -s "${includedir}/zlib.h" 3rd_party/cloudflare/zlib.h
# we have to use ${prefix}/lib, as ${libdir} is ${prefix}/bin on windows
ln -s "${prefix}/lib/libz.a" 3rd_party/cloudflare/libz.a

# use gcc/g++ on macOS and FreeBSD
if [[ "${target}" == *-freebsd* ]] || [[ "${target}" == *-apple-* ]]; then
    CC=gcc
    CXX=g++
fi

# Notes
# - the Makefile expects ${CC} to be a C++ compiler
make -j${nproc} CC="${CXX}" CXX="${CXX}" CPU_FLAGS= STATIC_CFLAGS="-fPIC -pthread" STATIC_LFLAGS="-lpthread" \
    kmc kmc_dump kmc_tools

# no `make install`
for prg in kmc kmc_dump kmc_tools; do
    install -Dvm 755 "./bin/${prg}${exeext}" "${bindir}/${prg}${exeext}"
done
# install header files
for hdr in include/*; do
    install -Dvm 644 "${hdr}" "${prefix}/include/$(basename "${hdr}")"
done

# build and install shared library
if [[ "${target}" == *-apple-* ]]; then
    # Avoid linker error on macos, can't find file ' '
    # I think it's because -Wl,$(flagon --no-whole-archive) expands to -Wl, (with a space at the end?)
    link_libs="-Wl,$(flagon --whole-archive) ./bin/libkmc_core.a -lz"
else
    link_libs="-Wl,$(flagon --whole-archive) ./bin/libkmc_core.a -Wl,$(flagon --no-whole-archive) -lz"
fi
"${CXX}" -O3 -shared -o "${libdir}/libkmc_core.${dlext}" $link_libs

# no explicit license file, the README says KMC is licensed under the GNU GPL 3
install_license /usr/share/licenses/GPL-3.0+
"""

platforms = supported_platforms(; exclude = p -> arch(p) ∉ ("x86_64", "aarch64")
                                              || (Sys.isapple(p) && arch(p) == "aarch64"))
platforms = expand_cxxstring_abis(platforms; skip=Returns(false))

products = [
    ExecutableProduct("kmc", :kmc),
    ExecutableProduct("kmc_dump", :kmc_dump),
    ExecutableProduct("kmc_tools", :kmc_tools),
    LibraryProduct("libkmc_core", :libkmc_core),
]

dependencies = [
    Dependency("Zlib_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version = v"11")
