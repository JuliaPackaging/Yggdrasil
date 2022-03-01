# This file has been generated by the GAP build system,
# do not edit manually!
GAParch=FAKE-GAP-ARCH
GAP_ABI=64
GAP_HPCGAP=no

GAP_VERSION="4.12dev"
GAP_BUILD_VERSION="4.12dev"
GAP_LIBTOOL_CURRENT=8
GAP_LIBTOOL_AGE=0
GAP_KERNEL_MAJOR_VERSION=8
GAP_KERNEL_MINOR_VERSION=0

GAP_BIN_DIR="/workspace/destdir/share/gap"
GAP_LIB_DIR="/workspace/destdir/share/gap"

GAP="/workspace/destdir/bin/gap"
GAC="/workspace/destdir/share/gap/gac"

GAP_CC="cc "
GAP_CXX="c++ -std=gnu++11 "
GAP_CFLAGS="-g -O2"
GAP_CXXFLAGS="-g -O2"
GAP_CPPFLAGS="-I/workspace/destdir/include/gap -DUSE_JULIA_GC=1 -fPIC "
GAP_LDFLAGS="-L/workspace/destdir/lib "
GAP_LIBS="-lgmp"

GAP_OBJS="build/obj/src/ariths.c.lo build/obj/src/bags.c.lo build/obj/src/blister.c.lo build/obj/src/bool.c.lo build/obj/src/calls.c.lo build/obj/src/code.c.lo build/obj/src/collectors.cc.lo build/obj/src/compiler.c.lo build/obj/src/costab.c.lo build/obj/src/cyclotom.c.lo build/obj/src/debug.c.lo build/obj/src/dt.c.lo build/obj/src/dteval.c.lo build/obj/src/error.c.lo build/obj/src/exprs.c.lo build/obj/src/ffdata.c.lo build/obj/src/finfield.c.lo build/obj/src/funcs.c.lo build/obj/src/gap.c.lo build/obj/src/gaptime.c.lo build/obj/build/gap_version.c.lo build/obj/src/gvars.c.lo build/obj/src/hookintrprtr.c.lo build/obj/src/info.c.lo build/obj/src/integer.c.lo build/obj/src/intfuncs.c.lo build/obj/src/intrprtr.c.lo build/obj/src/io.c.lo build/obj/src/iostream.c.lo build/obj/src/libgap-api.c.lo build/obj/src/listfunc.c.lo build/obj/src/listoper.c.lo build/obj/src/lists.c.lo build/obj/src/macfloat.c.lo build/obj/src/modules_builtin.c.lo build/obj/src/modules.c.lo build/obj/src/objcftl.c.lo build/obj/src/objects.c.lo build/obj/src/objfgelm.cc.lo build/obj/src/objpcgel.cc.lo build/obj/src/objset.c.lo build/obj/src/opers.cc.lo build/obj/src/permutat.cc.lo build/obj/src/plist.c.lo build/obj/src/pperm.cc.lo build/obj/src/precord.c.lo build/obj/src/profile.c.lo build/obj/src/range.c.lo build/obj/src/rational.c.lo build/obj/src/read.c.lo build/obj/src/records.c.lo build/obj/src/saveload.c.lo build/obj/src/scanner.c.lo build/obj/src/sctable.c.lo build/obj/src/set.c.lo build/obj/src/stats.c.lo build/obj/src/streams.c.lo build/obj/src/stringobj.c.lo build/obj/src/syntaxtree.c.lo build/obj/src/sysfiles.c.lo build/obj/src/sysroots.c.lo build/obj/src/sysstr.c.lo build/obj/src/system.c.lo build/obj/src/tietze.c.lo build/obj/src/tracing.c.lo build/obj/src/trans.cc.lo build/obj/src/trycatch.c.lo build/obj/src/vars.c.lo build/obj/src/vec8bit.c.lo build/obj/src/vecffe.c.lo build/obj/src/vecgf2.c.lo build/obj/src/vector.c.lo build/obj/src/weakptr.c.lo build/obj/src/julia_gc.c.lo build/obj/src/c_oper1.c.lo build/obj/src/c_type1.c.lo build/obj/src/compstat.c.lo"

JULIA=""
JULIA_CPPFLAGS="-I/workspace/destdir/include/julia -fPIC"
JULIA_LDFLAGS="-L/workspace/destdir/lib -L/workspace/destdir/lib/julia"
JULIA_LIBS="-Wl,-rpath,/workspace/destdir/lib -Wl,-rpath,/workspace/destdir/lib/julia -ljulia"
