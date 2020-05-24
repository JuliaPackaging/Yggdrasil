using BinaryBuilder

name = "MKL"
version = v"2020.1.216"

sources = [
    ArchiveSource("https://anaconda.org/intel/mkl/2020.1/download/linux-64/mkl-2020.1-intel_217.tar.bz2",
                  "8814e952c0b4f28079361adac8bec1051b97d62dee621666798a3302e70d75e0"; unpack_target = "mkl-x86_64-linux-gnu"),
    ArchiveSource("https://anaconda.org/intel/mkl/2020.1/download/osx-64/mkl-2020.1-intel_216.tar.bz2",
                  "4dab8dd1aa12b02cd121228ba881a887448399c799ee5a2d53942716a03f880e"; unpack_target = "mkl-x86_64-apple-darwin14"),
    ArchiveSource("https://anaconda.org/intel/mkl/2020.1/download/win-32/mkl-2020.1-intel_216.tar.bz2",
                  "b43ca7a8f5aed51e197af1f9165b3a72e5dd0a7f036fd9364ccfe90a8645a235"; unpack_target = "mkl-i686-w64-mingw32"),
    ArchiveSource("https://anaconda.org/intel/mkl/2020.1/download/win-64/mkl-2020.1-intel_216.tar.bz2",
                  "5dd8eff29b390ddb1cf15f391aba7fa3bdc4034f79b98d226865a5e331060f76"; unpack_target = "mkl-x86_64-w64-mingw32"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/mkl-${target}
if [[ ${target} == *mingw* ]]; then
    cp -r Library/bin/* ${libdir}
else
    cp -r lib/* ${libdir}
fi
install_license info/*.txt
"""

platforms = [
    Linux(:x86_64, libc=:glibc),
    MacOS(:x86_64),
    Windows(:i686),
    Windows(:x86_64),
]

# The products that we will ensure are always built
products_macos = [
    LibraryProduct("libmkl_avx", :libmkl_avx),
    LibraryProduct("libmkl_avx2", :libmkl_avx2),
    LibraryProduct("libmkl_avx512", :libmkl_avx512),
    LibraryProduct("libmkl_blacs_mpich_ilp64", :libmkl_blacs_mpich_ilp64),
    LibraryProduct("libmkl_blacs_mpich_lp64", :libmkl_blacs_mpich_lp64),
    LibraryProduct("libmkl_cdft_core", :libmkl_cdft_core),
    LibraryProduct("libmkl_core", :libmkl_core),
    LibraryProduct("libmkl_intel_ilp64", :libmkl_intel_ilp64),
    LibraryProduct("libmkl_intel_lp64", :libmkl_intel_lp64),
    LibraryProduct("libmkl_intel_thread", :libmkl_intel_thread),
    LibraryProduct("libmkl_mc3", :libmkl_mc3),
    LibraryProduct("libmkl_rt", :libmkl_rt),
    LibraryProduct("libmkl_scalapack_ilp64", :libmkl_scalapack_ilp64),
    LibraryProduct("libmkl_scalapack_lp64", :libmkl_scalapack_lp64),
    LibraryProduct("libmkl_sequential", :libmkl_sequential),
    LibraryProduct("libmkl_tbb_thread", :libmkl_tbb_thread),
    LibraryProduct("libmkl_vml_avx", :libmkl_vml_avx),
    LibraryProduct("libmkl_vml_avx2", :libmkl_vml_avx2),
    LibraryProduct("libmkl_vml_avx512", :libmkl_vml_avx512),
    LibraryProduct("libmkl_vml_mc2", :libmkl_vml_mc2),
    LibraryProduct("libmkl_vml_mc3", :libmkl_vml_mc3),
]

products_linux = [
    LibraryProduct("libmkl_avx2", :libmkl_avx2),
    LibraryProduct("libmkl_avx512_mic", :libmkl_avx512_mic),
    LibraryProduct("libmkl_avx512", :libmkl_avx512),
    LibraryProduct("libmkl_avx", :libmkl_avx),
    LibraryProduct("libmkl_blacs_intelmpi_ilp64", :libmkl_blacs_intelmpi_ilp64),
    LibraryProduct("libmkl_blacs_intelmpi_lp64", :libmkl_blacs_intelmpi_lp64),
    LibraryProduct("libmkl_blacs_openmpi_ilp64", :libmkl_blacs_openmpi_ilp64),
    LibraryProduct("libmkl_blacs_openmpi_lp64", :libmkl_blacs_openmpi_lp64),
    LibraryProduct("libmkl_blacs_sgimpt_ilp64", :libmkl_blacs_sgimpt_ilp64),
    LibraryProduct("libmkl_blacs_sgimpt_lp64", :libmkl_blacs_sgimpt_lp64),
    LibraryProduct("libmkl_cdft_core", :libmkl_cdft_core),
    LibraryProduct("libmkl_core", :libmkl_core),
    LibraryProduct("libmkl_def", :libmkl_def),
    LibraryProduct("libmkl_gf_ilp64", :libmkl_gf_ilp64),
    LibraryProduct("libmkl_gf_lp64", :libmkl_gf_lp64),
    LibraryProduct("libmkl_gnu_thread", :libmkl_gnu_thread),
    LibraryProduct("libmkl_intel_ilp64", :libmkl_intel_ilp64),
    LibraryProduct("libmkl_intel_lp64", :libmkl_intel_lp64),
    LibraryProduct("libmkl_intel_thread", :libmkl_intel_thread),
    LibraryProduct("libmkl_mc3", :libmkl_mc3),
    LibraryProduct("libmkl_mc", :libmkl_mc),
    LibraryProduct("libmkl_pgi_thread", :libmkl_pgi_thread),
    LibraryProduct("libmkl_rt", :libmkl_rt),
    LibraryProduct("libmkl_scalapack_ilp64", :libmkl_scalapack_ilp64),
    LibraryProduct("libmkl_scalapack_lp64", :libmkl_scalapack_lp64),
    LibraryProduct("libmkl_sequential", :libmkl_sequential),
    LibraryProduct("libmkl_tbb_thread", :libmkl_tbb_thread),
    LibraryProduct("libmkl_vml_avx2", :libmkl_vml_avx2),
    LibraryProduct("libmkl_vml_avx512_mic", :libmkl_vml_avx512_mic),
    LibraryProduct("libmkl_vml_avx512", :libmkl_vml_avx512),
    LibraryProduct("libmkl_vml_avx", :libmkl_vml_avx),
    LibraryProduct("libmkl_vml_cmpt", :libmkl_vml_cmpt),
    LibraryProduct("libmkl_vml_def", :libmkl_vml_def),
    LibraryProduct("libmkl_vml_mc2", :libmkl_vml_mc2),
    LibraryProduct("libmkl_vml_mc3", :libmkl_vml_mc3),
    LibraryProduct("libmkl_vml_mc", :libmkl_vml_mc),
]

products_win = [
    LibraryProduct("libimalloc", :liblibimalloc),
    LibraryProduct("mkl_avx", :libmkl_avx),
    LibraryProduct("mkl_avx2", :libmkl_avx2),
    LibraryProduct("mkl_avx512", :libmkl_avx512),
    LibraryProduct("mkl_blacs_ilp64", :libmkl_blacs_ilp64),
    LibraryProduct("mkl_blacs_intelmpi_ilp64", :libmkl_blacs_intelmpi_ilp64),
    LibraryProduct("mkl_blacs_intelmpi_lp64", :libmkl_blacs_intelmpi_lp64),
    LibraryProduct("mkl_blacs_lp64", :libmkl_blacs_lp64),
    LibraryProduct("mkl_blacs_mpich2_ilp64", :libmkl_blacs_mpich2_ilp64),
    LibraryProduct("mkl_blacs_mpich2_lp64", :libmkl_blacs_mpich2_lp64),
    LibraryProduct("mkl_blacs_msmpi_ilp64", :libmkl_blacs_msmpi_ilp64),
    LibraryProduct("mkl_blacs_msmpi_lp64", :libmkl_blacs_msmpi_lp64),
    LibraryProduct("mkl_cdft_core", :libmkl_cdft_core),
    LibraryProduct("mkl_core", :libmkl_core),
    LibraryProduct("mkl_def", :libmkl_def),
    LibraryProduct("mkl_intel_thread", :libmkl_intel_thread),
    LibraryProduct("mkl_mc", :libmkl_mc),
    LibraryProduct("mkl_mc3", :libmkl_mc3),
    LibraryProduct("mkl_msg", :libmkl_msg),
    LibraryProduct("mkl_pgi_thread", :libmkl_pgi_thread),
    LibraryProduct("mkl_rt", :libmkl_rt),
    LibraryProduct("mkl_scalapack_ilp64", :libmkl_scalapack_ilp64),
    LibraryProduct("mkl_scalapack_lp64", :libmkl_scalapack_lp64),
    LibraryProduct("mkl_sequential", :libmkl_sequential),
    LibraryProduct("mkl_tbb_thread", :libmkl_tbb_thread),
    LibraryProduct("mkl_vml_avx", :libmkl_vml_avx),
    LibraryProduct("mkl_vml_avx2", :libmkl_vml_avx2),
    LibraryProduct("mkl_vml_avx512", :libmkl_vml_avx512),
    LibraryProduct("mkl_vml_cmpt", :libmkl_vml_cmpt),
    LibraryProduct("mkl_vml_def", :libmkl_vml_def),
    LibraryProduct("mkl_vml_mc", :libmkl_vml_mc),
    LibraryProduct("mkl_vml_mc2", :libmkl_vml_mc2),
    LibraryProduct("mkl_vml_mc3", :libmkl_vml_mc3)
]

include("../../fancy_toys.jl")
if any(should_build_platform.(triplet.([Windows(:i686), Windows(:x86_64)])))
    products = products_win
elseif should_build_platform(triplet(Linux(:x86_64)))
    products = products_linux
else
    products = products_macos
end

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("IntelOpenMP_jll"),
]

non_reg_ARGS = filter(arg -> arg != "--register", ARGS)
no_autofix_platforms = [Windows(:i686), Windows(:x86_64), MacOS(:x86_64)]
autofix_platforms = [Linux(:x86_64)]
if any(should_build_platform.(triplet.(no_autofix_platforms)))
    # Need to disable autofix: updating linkage of libmkl_intel_thread.dylib on
    # macOS causes runtime issues:
    # https://github.com/JuliaPackaging/Yggdrasil/issues/915.
    build_tarballs(non_reg_ARGS, name, version, sources, script, no_autofix_platforms, products, dependencies; lazy_artifacts = true, autofix = false)
end
if any(should_build_platform.(triplet.(autofix_platforms)))
    # ... but we need to run autofix on Linux, because here libmkl_rt doesn't
    # have a soname, so we can't ccall it without specifying the path:
    # https://github.com/JuliaSparse/Pardiso.jl/issues/69
    build_tarballs(ARGS, name, version, sources, script, autofix_platforms, products, dependencies; lazy_artifacts = true)
end
