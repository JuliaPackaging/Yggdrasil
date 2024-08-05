--- libtool.orig
+++ libtool
@@ -11716,8 +11716,8 @@
 old_archive_from_expsyms_cmds=""
 
 # Commands used to build a shared archive.
-archive_cmds="\$CC -r -keep_private_externs -nostdlib -o \$lib-master.o \$libobjs~\$CC -dynamiclib \$allow_undefined_flag -o \$lib \$lib-master.o \$deplibs \$compiler_flags -install_name \$rpath/\$soname \$verstring"
-archive_expsym_cmds="sed 's|^|_|' < \$export_symbols > \$output_objdir/\$libname-symbols.expsym~\$CC -r -keep_private_externs -nostdlib -o \$lib-master.o \$libobjs~\$CC -dynamiclib \$allow_undefined_flag -o \$lib \$lib-master.o \$deplibs \$compiler_flags -install_name \$rpath/\$soname \$verstring \$wl-exported_symbols_list,\$output_objdir/\$libname-symbols.expsym"
+archive_cmds="\$CC -dynamiclib \$allow_undefined_flag -o \$lib \$libobjs \$deplibs \$compiler_flags -install_name \$rpath/\$soname \$verstring"
+archive_expsym_cmds="sed 's|^|_|' < \$export_symbols > \$output_objdir/\$libname-symbols.expsym~\$CC -dynamiclib \$allow_undefined_flag -o \$lib \$libobjs \$deplibs \$compiler_flags -install_name \$rpath/\$soname \$verstring \$wl-exported_symbols_list,\$output_objdir/\$libname-symbols.expsym"
 
 # Commands used to build a loadable module if different from building
 # a shared archive.
