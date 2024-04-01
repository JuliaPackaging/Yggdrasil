# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

function build_libxcrypt(ARGS; legacy::Bool)
   version = v"4.4.28"
   name = "libxcrypt"

   # Collection of sources required to build libxcrypt
   sources = [
       ArchiveSource("https://github.com/besser82/libxcrypt/releases/download/v$(version)/libxcrypt-$(version).tar.xz",
                     "9e936811f9fad11dbca33ca19bd97c55c52eb3ca15901f27ade046cc79e69e87")
   ]

   # Bash recipe for building across all platforms
   script = raw"""
   cd $WORKSPACE/srcdir/libxcrypt-*/
   if [[ ${target} == *freebsd* ]]; then
      extraflags="${extraflags} ax_cv_check_vscript_flag=--version-script"
   fi
   ./configure \
               --prefix=${prefix} \
               --build=${MACHTYPE} \
               --host=${target} \
               --enable-shared \
               --disable-static \
               ${extraflags}
   make -j${nproc}
   make install
   install_license COPYING.LIB
   """


   # These are the platforms we will build for by default, unless further
   # platforms are passed in on the command line
   platforms = filter(!Sys.iswindows, supported_platforms())

   # legacy variant is to provide a binary-compatible libcrypt.so.1 which can
   # be used at runtime instead of the removed in recent glibc versions
   # hence we only build for glibc platforms
   if legacy
      name *= "_legacy"
      filter!(p -> (Sys.islinux(p) && libc(p) == "glibc"), platforms)
   else
      # this disables the glibc compatibility api
      script = "extraflags=--disable-obsolete-api\n" * script
   end

   # The products that we will ensure are always built
   products = Product[
       LibraryProduct("libcrypt", :libcrypt)
   ]

   # Dependencies that must be installed before this package can be built
   dependencies = Dependency[
   ]

   # Build the tarballs, and possibly a `build.jl` as well.
   build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
end
