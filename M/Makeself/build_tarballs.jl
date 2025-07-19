# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Makeself"
version = v"2.5.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/megastep/makeself.git", "a20c7bd68f1439dd5a5657a2a767632acb5c9537")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
chmod +x makeself/makeself.sh 
chmod +x makeself/makeself-header.sh 
cp makeself/makeself.sh /workspace/destdir/bin/makeself.sh
cp makeself/makeself-header.sh /workspace/destdir/bin/makeself-header.sh
printf '%s\n' '#include <stdio.h>' '#include <stdlib.h>' '#include <string.h>' '#include <sys/wait.h>' 'int main(int argc,char **argv){' '  size_t len = 32;                         /* base length */' '  for(int i=1;i<argc;i++) len += strlen(argv[i]) + 3; /* space + quotes */' '  char *cmd = malloc(len); if(!cmd) return 1;' '  strcpy(cmd,"/usr/bin/makeself.sh");' '  for(int i=1;i<argc;i++){strcat(cmd," \"");strcat(cmd,argv[i]);strcat(cmd,"\"");}' '  int r = system(cmd); free(cmd);' '  return (r == -1) ? 1 : WEXITSTATUS(r);' '}' | gcc -x c -std=c11 -Os -s -o run_makeself -
cp run_makeself /workspace/destdir/bin/makeself
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("powerpc64le", "linux"; libc = "glibc"),
    Platform("riscv64", "linux"; libc = "glibc"),
    Platform("i686", "linux"; libc = "musl"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("aarch64", "linux"; libc = "musl"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "musl"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl"),
    Platform("x86_64", "freebsd"; ),
    Platform("aarch64", "freebsd"; )
]


# The products that we will ensure are always built
products = [
    ExecutableProduct("makeself", :makeself)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="GnuPG_jll", uuid="1522389b-45f8-5faa-af4d-a301b79c50ac"))
    Dependency(PackageSpec(name="coreutils_jll", uuid="5818bda4-868b-5068-b238-e370ed6eefef"))
    Dependency(PackageSpec(name="gawk_jll", uuid="054acbdd-7fbc-53f6-b51a-0fe4f8189fb8"))
    Dependency(PackageSpec(name="grep_jll", uuid="47013893-54eb-5c9c-83b4-9a24496ece36"))
    Dependency(PackageSpec(name="sed_jll", uuid="8ce03227-cf0a-51af-b0b4-2693c0743e9f"))
    Dependency(PackageSpec(name="Tar_jll", uuid="9b64493d-8859-5bf3-93d7-7c32dd38186f"))
    Dependency(PackageSpec(name="OpenSSL_jll", uuid="458c3c95-2e84-50aa-8efc-19380b2a3a95"))
    Dependency(PackageSpec(name="Gzip_jll", uuid="be1be57a-8558-53c3-a7e5-50095f79957e"))
    Dependency(PackageSpec(name="Bzip2_jll", uuid="6e34b625-4abd-537c-b88f-471c36dfa7a0"))
    Dependency(PackageSpec(name="pigz_jll", uuid="1bc43ea1-30af-5bc8-a9d4-c018457e6e3e"))
    Dependency(PackageSpec(name="Zstd_jll", uuid="3161d3a3-bdf6-5164-811a-617609db77b4"))
    Dependency(PackageSpec(name="XZ_jll", uuid="ffd25f8a-64ca-5728-b0f7-c24cf3aae800"))
    Dependency(PackageSpec(name="LZO_jll", uuid="dd4b983a-f0e5-5f8d-a1b7-129d4a5fb1ac"))
    Dependency(PackageSpec(name="Lz4_jll", uuid="5ced341a-0733-55b8-9ab6-a4889d929147"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
