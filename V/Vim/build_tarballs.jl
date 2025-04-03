using BinaryBuilder, Pkg

name = "Vim"
version = v"9.1.0"  # Update this to match desired Vim version

sources = [
    GitSource("https://github.com/vim/vim.git", 
              "b4ddc6c11e95cef4b372e239871fae1c8d4f72b6"),
]

# Bash recipe for building Vim
script = raw"""
cd $WORKSPACE/srcdir/vim*/

# Set environment variables to help configure script during cross-compilation
export vim_cv_toupper_broken=no
export vim_cv_terminfo=yes
export vim_cv_tty_group=tty
export vim_cv_getcwd_broken=no
export vim_cv_stat_ignores_slash=yes  # Already set, but ensuring it’s correct
export vim_cv_tgetent=zero
export vim_cv_timer_create=yes  # Assume timer_create is available without -lrt
export vim_cv_memmove_handles_overlap=yes  # Assume memmove handles overlaps

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
make -j${nproc}
make install
"""

# Platforms to build for
platforms = supported_platforms()

# Products to be built
products = [
    ExecutableProduct("vim", :vim),
]

# Dependencies
dependencies = [
    Dependency("Ncurses_jll"),
    Dependency("Libiconv_jll"),
    Dependency("libxcrypt_jll"),
]

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
