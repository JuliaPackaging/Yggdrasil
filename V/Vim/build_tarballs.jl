using BinaryBuilder, BinaryBuilderBase, Pkg

name = "Vim"
version = v"9.1.0"  # Update this to match desired Vim version

sources = [
    GitSource("https://github.com/vim/vim.git", 
              "b4ddc6c11e95cef4b372e239871fae1c8d4f72b6"),
    DirectorySource("bundled"),
]

# Bash recipe for building Vim
script = raw"""
cd $WORKSPACE/srcdir/vim*/

if [[ "${target}" == *-mingw* ]]; then
    atomic_patch -p0 ../patches/windows_build.patch
fi

# Set environment variables to help configure script during cross-compilation
export vim_cv_toupper_broken=no
export vim_cv_terminfo=yes
export vim_cv_tty_group=tty
export vim_cv_getcwd_broken=no
export vim_cv_stat_ignores_slash=yes
export vim_cv_tgetent=zero
export vim_cv_timer_create=no
export vim_cv_memmove_handles_overlap=yes

./configure \
    --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --with-features=huge \
    --enable-multibyte \
    --enable-terminal \
    --with-tlib=ncursesw \
    --enable-gui=no \
    --without-x \
    --disable-netbeans

# Build and install
if [[ "${target}" == *-mingw* ]]; then
   cd src 
   make -j${nproc} -f Make_ming.mak
   cp *.exe ${bindir}
   cd ..
else
   make -j${nproc}
   make install
fi
"""

# Platforms to build for
platforms = filter!(p -> !Sys.iswindows(p), supported_platforms())
platforms_windows = filter!(p -> Sys.iswindows(p), supported_platforms())

# Products to be built
products = [
    ExecutableProduct("vim", :vim),
]
products_windows = [
    ExecutableProduct("gvim", :gvim),
]

# Dependencies
dependencies = [
    HostBuildDependency("Gettext_jll"),
    Dependency("Ncurses_jll"),
    Dependency("Libiconv_jll"),
]

# Build the tarballs
include("../../fancy_toys.jl")

if any(should_build_platform.(triplet.(platforms_windows)))
    build_tarballs(ARGS, name, version, sources, script, platforms_windows, products_windows, dependencies; julia_compat="1.6")
end

if any(should_build_platform.(triplet.(platforms)))
    build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
end
