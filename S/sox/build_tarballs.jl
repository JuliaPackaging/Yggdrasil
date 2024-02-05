# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "sox"
version = v"14.4.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/chirlu/sox.git", "45b161d73ec087a8e003747b1aed07cd33589bca")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/sox/
if [[ "${target}" == *-apple-darwin* ]]; then # Apply patch from https://github.com/chirlu/sox/pull/2
    echo "diff --git a/src/skelform.c b/src/skelform.c
index 793c767e..412bea5d 100644
--- a/src/skelform.c
+++ b/src/skelform.c
@@ -183,7 +183,7 @@ static int stopwrite(sox_format_t UNUSED * ft)
   return SOX_SUCCESS;
 }
 
-static int seek(sox_format_t UNUSED * ft, uint64_t UNUSED offset)
+static int seek(sox_format_t UNUSED * ft, sox_uint64_t UNUSED offset)
 {
   /* Seek relative to current position. */
   return SOX_SUCCESS;
diff --git a/src/sox_i.h b/src/sox_i.h
index c8552f97..301bb5e8 100644
--- a/src/sox_i.h
+++ b/src/sox_i.h
@@ -237,7 +237,7 @@ size_t lsx_rawread(sox_format_t * ft, sox_sample_t *buf, size_t nsamp);
 int lsx_rawstopread(sox_format_t * ft);
 int lsx_rawstartwrite(sox_format_t * ft);
 size_t lsx_rawwrite(sox_format_t * ft, const sox_sample_t *buf, size_t nsamp);
-int lsx_rawseek(sox_format_t * ft, uint64_t offset);
+int lsx_rawseek(sox_format_t * ft, sox_uint64_t offset);
 int lsx_rawstart(sox_format_t * ft, sox_bool default_rate, sox_bool default_channels, sox_bool default_length, sox_encoding_t encoding, unsigned bits_per_sample);
 #define lsx_rawstartread(ft) lsx_rawstart(ft, sox_false, sox_false, sox_false, SOX_ENCODING_UNKNOWN, 0)
 #define lsx_rawstartwrite lsx_rawstartread" > macos.patch
    git apply macos.patch
fi
autoreconf -i
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
# Musl is unsupported
filter!(p -> libc(p) != "musl", platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("sox", :sox)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
