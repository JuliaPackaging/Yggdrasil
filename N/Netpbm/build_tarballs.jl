# Note that this script can accept some limited command-line arguments,
# run `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms

name = "Netpbm"
version_string = "10.86.43"
version = VersionNumber(version_string)

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://sourceforge.net/projects/netpbm/files/super_stable/$(version_string)/netpbm-$(version_string).tgz",
                  "ac7d30dc1bcfc754931d247fcad475503c121c16cc6470e68c4313128a221ddd"),
    GitSource("https://github.com/win32ports/sys_wait_h", "229dee8de9cb4c29a3a31115112a4175df84a8eb"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/netpbm-*

# Ensure that BSD functions can be found on FreeBSD
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/freebsd.patch

# Provide <sys/wait.h> for Windows
if [[ ${target} == *-mingw32* ]]; then
    cp ${WORKSPACE}/srcdir/sys_wait_h/sys/wait.h /opt/${target}/${target}/sys-root/include/sys/wait.h
fi

cp ${WORKSPACE}/srcdir/files/config.mk .

make -j${nproc}
make package pkgdir=${WORKSPACE}/installdir

for file in $(cd ${WORKSPACE}/installdir/bin && ls); do
    install -Dvm 755 ${WORKSPACE}/installdir/bin/${file} ${bindir}/${file}
done

for file in $(cd ${WORKSPACE}/installdir/include && ls | grep -v netpbm); do
    install -Dvm 644 ${WORKSPACE}/installdir/include/${file} ${includedir}/${file}
done
for file in $(cd ${WORKSPACE}/installdir/include/netpbm && ls); do
    install -Dvm 644 ${WORKSPACE}/installdir/include/netpbm/${file} ${includedir}/netpbm/${file}
done

for file in $(cd ${WORKSPACE}/installdir/lib && ls); do
    install -Dvm 644 ${WORKSPACE}/installdir/lib/${file} ${libdir}/${file}
done

for file in $(cd ${WORKSPACE}/installdir/misc && ls); do
    install -Dvm 644 ${WORKSPACE}/installdir/misc/${file} ${miscdir}/${file}
done

for file in $(cd ${WORKSPACE}/installdir/sharedlink && ls); do
    install -Dvm 644 ${WORKSPACE}/installdir/sharedlink/${file} ${libdir}/${file}
done

install_license doc/CONTRIBUTORS doc/COPYRIGHT.PATENT doc/GPL_LICENSE.txt doc/copyright_summary doc/lgpl_v21.txt doc/patent_summary
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The build doesn't succeed on Windows. I'm sure this could be fixed.
filter!(!Sys.iswindows, platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("411toppm", :a411toppm),
    ExecutableProduct("anytopnm", :anytopnm),
    ExecutableProduct("asciitopgm", :asciitopgm),
    ExecutableProduct("atktopbm", :atktopbm),
    ExecutableProduct("avstopam", :avstopam),
    ExecutableProduct("bioradtopgm", :bioradtopgm),
    ExecutableProduct("bmptopnm", :bmptopnm),
    ExecutableProduct("bmptoppm", :bmptoppm),
    ExecutableProduct("brushtopbm", :brushtopbm),
    ExecutableProduct("cameratopam", :cameratopam),
    ExecutableProduct("cistopbm", :cistopbm),
    ExecutableProduct("cmuwmtopbm", :cmuwmtopbm),
    ExecutableProduct("ddbugtopbm", :ddbugtopbm),
    ExecutableProduct("escp2topbm", :escp2topbm),
    ExecutableProduct("eyuvtoppm", :eyuvtoppm),
    ExecutableProduct("fiascotopnm", :fiascotopnm),
    ExecutableProduct("fitstopnm", :fitstopnm),
    ExecutableProduct("fstopgm", :fstopgm),
    ExecutableProduct("g3topbm", :g3topbm),
    ExecutableProduct("gemtopbm", :gemtopbm),
    ExecutableProduct("gemtopnm", :gemtopnm),
    ExecutableProduct("giftopnm", :giftopnm),
    ExecutableProduct("gouldtoppm", :gouldtoppm),
    ExecutableProduct("hdifftopam", :hdifftopam),
    ExecutableProduct("hipstopgm", :hipstopgm),
    ExecutableProduct("hpcdtoppm", :hpcdtoppm),
    ExecutableProduct("icontopbm", :icontopbm),
    ExecutableProduct("ilbmtoppm", :ilbmtoppm),
    ExecutableProduct("imgtoppm", :imgtoppm),
    ExecutableProduct("infotopam", :infotopam),
    ExecutableProduct("jbigtopnm", :jbigtopnm),
    ExecutableProduct("jpeg2ktopam", :jpeg2ktopam),
    ExecutableProduct("leaftoppm", :leaftoppm),
    ExecutableProduct("lispmtopgm", :lispmtopgm),
    ExecutableProduct("macptopbm", :macptopbm),
    ExecutableProduct("manweb", :manweb),
    ExecutableProduct("mdatopbm", :mdatopbm),
    ExecutableProduct("mgrtopbm", :mgrtopbm),
    ExecutableProduct("mrftopbm", :mrftopbm),
    ExecutableProduct("mtvtoppm", :mtvtoppm),
    ExecutableProduct("neotoppm", :neotoppm),
    ExecutableProduct("palmtopnm", :palmtopnm),
    ExecutableProduct("pamaddnoise", :pamaddnoise),
    ExecutableProduct("pamaltsat", :pamaltsat),
    ExecutableProduct("pamarith", :pamarith),
    ExecutableProduct("pambackground", :pambackground),
    ExecutableProduct("pambayer", :pambayer),
    ExecutableProduct("pambrighten", :pambrighten),
    ExecutableProduct("pamchannel", :pamchannel),
    ExecutableProduct("pamcomp", :pamcomp),
    ExecutableProduct("pamcrater", :pamcrater),
    ExecutableProduct("pamcut", :pamcut),
    ExecutableProduct("pamdeinterlace", :pamdeinterlace),
    ExecutableProduct("pamdepth", :pamdepth),
    ExecutableProduct("pamdice", :pamdice),
    ExecutableProduct("pamditherbw", :pamditherbw),
    ExecutableProduct("pamedge", :pamedge),
    ExecutableProduct("pamendian", :pamendian),
    ExecutableProduct("pamenlarge", :pamenlarge),
    ExecutableProduct("pamexec", :pamexec),
    ExecutableProduct("pamfile", :pamfile),
    ExecutableProduct("pamfind", :pamfind),
    ExecutableProduct("pamfix", :pamfix),
    ExecutableProduct("pamfixtrunc", :pamfixtrunc),
    ExecutableProduct("pamflip", :pamflip),
    ExecutableProduct("pamfunc", :pamfunc),
    ExecutableProduct("pamgauss", :pamgauss),
    ExecutableProduct("pamgetcolor", :pamgetcolor),
    ExecutableProduct("pamgradient", :pamgradient),
    ExecutableProduct("pamhue", :pamhue),
    ExecutableProduct("pamlevels", :pamlevels),
    ExecutableProduct("pamlookup", :pamlookup),
    ExecutableProduct("pammasksharpen", :pammasksharpen),
    ExecutableProduct("pammixinterlace", :pammixinterlace),
    ExecutableProduct("pammixmulti", :pammixmulti),
    ExecutableProduct("pammosaicknit", :pammosaicknit),
    ExecutableProduct("pamoil", :pamoil),
    ExecutableProduct("pampaintspill", :pampaintspill),
    ExecutableProduct("pamperspective", :pamperspective),
    ExecutableProduct("pampick", :pampick),
    ExecutableProduct("pampop9", :pampop9),
    ExecutableProduct("pamrecolor", :pamrecolor),
    ExecutableProduct("pamrgbatopng", :pamrgbatopng),
    ExecutableProduct("pamrubber", :pamrubber),
    ExecutableProduct("pamscale", :pamscale),
    ExecutableProduct("pamseq", :pamseq),
    ExecutableProduct("pamshadedrelief", :pamshadedrelief),
    ExecutableProduct("pamsharpmap", :pamsharpmap),
    ExecutableProduct("pamsharpness", :pamsharpness),
    ExecutableProduct("pamsistoaglyph", :pamsistoaglyph),
    ExecutableProduct("pamslice", :pamslice),
    ExecutableProduct("pamsplit", :pamsplit),
    ExecutableProduct("pamstack", :pamstack),
    ExecutableProduct("pamstereogram", :pamstereogram),
    ExecutableProduct("pamstretch", :pamstretch),
    ExecutableProduct("pamstretch-gen", :pamstretch_gen),
    ExecutableProduct("pamsumm", :pamsumm),
    ExecutableProduct("pamsummcol", :pamsummcol),
    ExecutableProduct("pamtable", :pamtable),
    ExecutableProduct("pamthreshold", :pamthreshold),
    ExecutableProduct("pamtilt", :pamtilt),
    ExecutableProduct("pamtoavs", :pamtoavs),
    ExecutableProduct("pamtodjvurle", :pamtodjvurle),
    ExecutableProduct("pamtofits", :pamtofits),
    ExecutableProduct("pamtogif", :pamtogif),
    ExecutableProduct("pamtohdiff", :pamtohdiff),
    ExecutableProduct("pamtohtmltbl", :pamtohtmltbl),
    ExecutableProduct("pamtojpeg2k", :pamtojpeg2k),
    ExecutableProduct("pamtompfont", :pamtompfont),
    ExecutableProduct("pamtooctaveimg", :pamtooctaveimg),
    ExecutableProduct("pamtopam", :pamtopam),
    ExecutableProduct("pamtopdbimg", :pamtopdbimg),
    ExecutableProduct("pamtopfm", :pamtopfm),
    ExecutableProduct("pamtopng", :pamtopng),
    ExecutableProduct("pamtopnm", :pamtopnm),
    ExecutableProduct("pamtosrf", :pamtosrf),
    ExecutableProduct("pamtosvg", :pamtosvg),
    ExecutableProduct("pamtotga", :pamtotga),
    ExecutableProduct("pamtouil", :pamtouil),
    ExecutableProduct("pamtowinicon", :pamtowinicon),
    ExecutableProduct("pamtoxvmini", :pamtoxvmini),
    ExecutableProduct("pamtris", :pamtris),
    ExecutableProduct("pamundice", :pamundice),
    ExecutableProduct("pamunlookup", :pamunlookup),
    ExecutableProduct("pamvalidate", :pamvalidate),
    ExecutableProduct("pamwipeout", :pamwipeout),
    # pamx requires X11 which is not built for Apple
    # ExecutableProduct("pamx", :pamx),
    ExecutableProduct("pbmclean", :pbmclean),
    ExecutableProduct("pbmlife", :pbmlife),
    ExecutableProduct("pbmmake", :pbmmake),
    ExecutableProduct("pbmmask", :pbmmask),
    ExecutableProduct("pbmminkowski", :pbmminkowski),
    ExecutableProduct("pbmpage", :pbmpage),
    ExecutableProduct("pbmpscale", :pbmpscale),
    ExecutableProduct("pbmreduce", :pbmreduce),
    ExecutableProduct("pbmtext", :pbmtext),
    ExecutableProduct("pbmtextps", :pbmtextps),
    ExecutableProduct("pbmto10x", :pbmto10x),
    ExecutableProduct("pbmto4425", :pbmto4425),
    ExecutableProduct("pbmtoascii", :pbmtoascii),
    ExecutableProduct("pbmtoatk", :pbmtoatk),
    ExecutableProduct("pbmtobbnbg", :pbmtobbnbg),
    ExecutableProduct("pbmtocis", :pbmtocis),
    ExecutableProduct("pbmtocmuwm", :pbmtocmuwm),
    ExecutableProduct("pbmtodjvurle", :pbmtodjvurle),
    ExecutableProduct("pbmtoepsi", :pbmtoepsi),
    ExecutableProduct("pbmtoepson", :pbmtoepson),
    ExecutableProduct("pbmtoescp2", :pbmtoescp2),
    ExecutableProduct("pbmtog3", :pbmtog3),
    ExecutableProduct("pbmtogem", :pbmtogem),
    ExecutableProduct("pbmtogo", :pbmtogo),
    ExecutableProduct("pbmtoibm23xx", :pbmtoibm23xx),
    ExecutableProduct("pbmtoicon", :pbmtoicon),
    ExecutableProduct("pbmtolj", :pbmtolj),
    ExecutableProduct("pbmtoln03", :pbmtoln03),
    ExecutableProduct("pbmtolps", :pbmtolps),
    ExecutableProduct("pbmtomacp", :pbmtomacp),
    ExecutableProduct("pbmtomatrixorbital", :pbmtomatrixorbital),
    ExecutableProduct("pbmtomda", :pbmtomda),
    ExecutableProduct("pbmtomgr", :pbmtomgr),
    ExecutableProduct("pbmtomrf", :pbmtomrf),
    ExecutableProduct("pbmtonokia", :pbmtonokia),
    ExecutableProduct("pbmtopgm", :pbmtopgm),
    ExecutableProduct("pbmtopi3", :pbmtopi3),
    ExecutableProduct("pbmtopk", :pbmtopk),
    ExecutableProduct("pbmtoplot", :pbmtoplot),
    ExecutableProduct("pbmtoppa", :pbmtoppa),
    ExecutableProduct("pbmtopsg3", :pbmtopsg3),
    ExecutableProduct("pbmtoptx", :pbmtoptx),
    ExecutableProduct("pbmtosunicon", :pbmtosunicon),
    ExecutableProduct("pbmtowbmp", :pbmtowbmp),
    ExecutableProduct("pbmtox10bm", :pbmtox10bm),
    ExecutableProduct("pbmtoxbm", :pbmtoxbm),
    ExecutableProduct("pbmtoybm", :pbmtoybm),
    ExecutableProduct("pbmtozinc", :pbmtozinc),
    ExecutableProduct("pbmupc", :pbmupc),
    ExecutableProduct("pc1toppm", :pc1toppm),
    ExecutableProduct("pcdindex", :pcdindex),
    ExecutableProduct("pcdovtoppm", :pcdovtoppm),
    ExecutableProduct("pcxtoppm", :pcxtoppm),
    ExecutableProduct("pdbimgtopam", :pdbimgtopam),
    ExecutableProduct("pfmtopam", :pfmtopam),
    ExecutableProduct("pgmabel", :pgmabel),
    ExecutableProduct("pgmbentley", :pgmbentley),
    ExecutableProduct("pgmcrater", :pgmcrater),
    ExecutableProduct("pgmdeshadow", :pgmdeshadow),
    ExecutableProduct("pgmedge", :pgmedge),
    ExecutableProduct("pgmenhance", :pgmenhance),
    ExecutableProduct("pgmhist", :pgmhist),
    ExecutableProduct("pgmkernel", :pgmkernel),
    ExecutableProduct("pgmmake", :pgmmake),
    ExecutableProduct("pgmmedian", :pgmmedian),
    ExecutableProduct("pgmminkowski", :pgmminkowski),
    ExecutableProduct("pgmmorphconv", :pgmmorphconv),
    ExecutableProduct("pgmnoise", :pgmnoise),
    ExecutableProduct("pgmnorm", :pgmnorm),
    ExecutableProduct("pgmoil", :pgmoil),
    ExecutableProduct("pgmramp", :pgmramp),
    ExecutableProduct("pgmslice", :pgmslice),
    ExecutableProduct("pgmtexture", :pgmtexture),
    ExecutableProduct("pgmtofs", :pgmtofs),
    ExecutableProduct("pgmtolispm", :pgmtolispm),
    ExecutableProduct("pgmtopbm", :pgmtopbm),
    ExecutableProduct("pgmtopgm", :pgmtopgm),
    ExecutableProduct("pgmtoppm", :pgmtoppm),
    ExecutableProduct("pgmtosbig", :pgmtosbig),
    ExecutableProduct("pgmtost4", :pgmtost4),
    ExecutableProduct("pi1toppm", :pi1toppm),
    ExecutableProduct("pi3topbm", :pi3topbm),
    ExecutableProduct("picttoppm", :picttoppm),
    ExecutableProduct("pjtoppm", :pjtoppm),
    ExecutableProduct("pktopbm", :pktopbm),
    ExecutableProduct("pngtopam", :pngtopam),
    ExecutableProduct("pngtopnm", :pngtopnm),
    ExecutableProduct("pnmalias", :pnmalias),
    ExecutableProduct("pnmarith", :pnmarith),
    ExecutableProduct("pnmcat", :pnmcat),
    ExecutableProduct("pnmcolormap", :pnmcolormap),
    ExecutableProduct("pnmcomp", :pnmcomp),
    ExecutableProduct("pnmconvol", :pnmconvol),
    ExecutableProduct("pnmcrop", :pnmcrop),
    ExecutableProduct("pnmcut", :pnmcut),
    ExecutableProduct("pnmdepth", :pnmdepth),
    ExecutableProduct("pnmenlarge", :pnmenlarge),
    ExecutableProduct("pnmfile", :pnmfile),
    ExecutableProduct("pnmflip", :pnmflip),
    ExecutableProduct("pnmgamma", :pnmgamma),
    ExecutableProduct("pnmhisteq", :pnmhisteq),
    ExecutableProduct("pnmhistmap", :pnmhistmap),
    ExecutableProduct("pnmindex", :pnmindex),
    ExecutableProduct("pnminterp", :pnminterp),
    ExecutableProduct("pnminvert", :pnminvert),
    ExecutableProduct("pnmmargin", :pnmmargin),
    ExecutableProduct("pnmmercator", :pnmmercator),
    ExecutableProduct("pnmmontage", :pnmmontage),
    ExecutableProduct("pnmnlfilt", :pnmnlfilt),
    ExecutableProduct("pnmnoraw", :pnmnoraw),
    ExecutableProduct("pnmnorm", :pnmnorm),
    ExecutableProduct("pnmpad", :pnmpad),
    ExecutableProduct("pnmpaste", :pnmpaste),
    ExecutableProduct("pnmpsnr", :pnmpsnr),
    ExecutableProduct("pnmquant", :pnmquant),
    ExecutableProduct("pnmquantall", :pnmquantall),
    ExecutableProduct("pnmremap", :pnmremap),
    ExecutableProduct("pnmrotate", :pnmrotate),
    ExecutableProduct("pnmscale", :pnmscale),
    ExecutableProduct("pnmscalefixed", :pnmscalefixed),
    ExecutableProduct("pnmshear", :pnmshear),
    ExecutableProduct("pnmsmooth", :pnmsmooth),
    ExecutableProduct("pnmsplit", :pnmsplit),
    ExecutableProduct("pnmstitch", :pnmstitch),
    ExecutableProduct("pnmtile", :pnmtile),
    ExecutableProduct("pnmtoddif", :pnmtoddif),
    ExecutableProduct("pnmtofiasco", :pnmtofiasco),
    ExecutableProduct("pnmtofits", :pnmtofits),
    ExecutableProduct("pnmtojbig", :pnmtojbig),
    ExecutableProduct("pnmtopalm", :pnmtopalm),
    ExecutableProduct("pnmtopclxl", :pnmtopclxl),
    ExecutableProduct("pnmtoplainpnm", :pnmtoplainpnm),
    ExecutableProduct("pnmtopng", :pnmtopng),
    ExecutableProduct("pnmtopnm", :pnmtopnm),
    ExecutableProduct("pnmtops", :pnmtops),
    ExecutableProduct("pnmtorast", :pnmtorast),
    ExecutableProduct("pnmtorle", :pnmtorle),
    ExecutableProduct("pnmtosgi", :pnmtosgi),
    ExecutableProduct("pnmtosir", :pnmtosir),
    ExecutableProduct("pnmtoxwd", :pnmtoxwd),
    ExecutableProduct("ppm3d", :ppm3d),
    ExecutableProduct("ppmbrighten", :ppmbrighten),
    ExecutableProduct("ppmchange", :ppmchange),
    ExecutableProduct("ppmcie", :ppmcie),
    ExecutableProduct("ppmcolormask", :ppmcolormask),
    ExecutableProduct("ppmcolors", :ppmcolors),
    ExecutableProduct("ppmdcfont", :ppmdcfont),
    ExecutableProduct("ppmddumpfont", :ppmddumpfont),
    ExecutableProduct("ppmdim", :ppmdim),
    ExecutableProduct("ppmdist", :ppmdist),
    ExecutableProduct("ppmdither", :ppmdither),
    ExecutableProduct("ppmdmkfont", :ppmdmkfont),
    ExecutableProduct("ppmdraw", :ppmdraw),
    ExecutableProduct("ppmfade", :ppmfade),
    ExecutableProduct("ppmflash", :ppmflash),
    ExecutableProduct("ppmforge", :ppmforge),
    ExecutableProduct("ppmglobe", :ppmglobe),
    ExecutableProduct("ppmhist", :ppmhist),
    ExecutableProduct("ppmlabel", :ppmlabel),
    ExecutableProduct("ppmmake", :ppmmake),
    ExecutableProduct("ppmmix", :ppmmix),
    ExecutableProduct("ppmnorm", :ppmnorm),
    ExecutableProduct("ppmntsc", :ppmntsc),
    ExecutableProduct("ppmpat", :ppmpat),
    ExecutableProduct("ppmquant", :ppmquant),
    ExecutableProduct("ppmquantall", :ppmquantall),
    ExecutableProduct("ppmrainbow", :ppmrainbow),
    ExecutableProduct("ppmrelief", :ppmrelief),
    ExecutableProduct("ppmrough", :ppmrough),
    ExecutableProduct("ppmshadow", :ppmshadow),
    ExecutableProduct("ppmshift", :ppmshift),
    ExecutableProduct("ppmspread", :ppmspread),
    ExecutableProduct("ppmtoacad", :ppmtoacad),
    ExecutableProduct("ppmtoapplevol", :ppmtoapplevol),
    ExecutableProduct("ppmtoarbtxt", :ppmtoarbtxt),
    ExecutableProduct("ppmtoascii", :ppmtoascii),
    ExecutableProduct("ppmtobmp", :ppmtobmp),
    ExecutableProduct("ppmtoeyuv", :ppmtoeyuv),
    ExecutableProduct("ppmtogif", :ppmtogif),
    ExecutableProduct("ppmtoicr", :ppmtoicr),
    ExecutableProduct("ppmtoilbm", :ppmtoilbm),
    ExecutableProduct("ppmtoleaf", :ppmtoleaf),
    ExecutableProduct("ppmtolj", :ppmtolj),
    ExecutableProduct("ppmtomap", :ppmtomap),
    ExecutableProduct("ppmtomitsu", :ppmtomitsu),
    ExecutableProduct("ppmtompeg", :ppmtompeg),
    ExecutableProduct("ppmtoneo", :ppmtoneo),
    ExecutableProduct("ppmtopcx", :ppmtopcx),
    ExecutableProduct("ppmtopgm", :ppmtopgm),
    ExecutableProduct("ppmtopi1", :ppmtopi1),
    ExecutableProduct("ppmtopict", :ppmtopict),
    ExecutableProduct("ppmtopj", :ppmtopj),
    ExecutableProduct("ppmtopjxl", :ppmtopjxl),
    ExecutableProduct("ppmtoppm", :ppmtoppm),
    ExecutableProduct("ppmtopuzz", :ppmtopuzz),
    ExecutableProduct("ppmtorgb3", :ppmtorgb3),
    ExecutableProduct("ppmtosixel", :ppmtosixel),
    ExecutableProduct("ppmtospu", :ppmtospu),
    ExecutableProduct("ppmtoterm", :ppmtoterm),
    ExecutableProduct("ppmtotga", :ppmtotga),
    ExecutableProduct("ppmtouil", :ppmtouil),
    ExecutableProduct("ppmtowinicon", :ppmtowinicon),
    ExecutableProduct("ppmtoxpm", :ppmtoxpm),
    ExecutableProduct("ppmtoyuv", :ppmtoyuv),
    ExecutableProduct("ppmtoyuvsplit", :ppmtoyuvsplit),
    ExecutableProduct("ppmtv", :ppmtv),
    ExecutableProduct("ppmwheel", :ppmwheel),
    ExecutableProduct("psidtopgm", :psidtopgm),
    ExecutableProduct("pstopnm", :pstopnm),
    ExecutableProduct("qrttoppm", :qrttoppm),
    ExecutableProduct("rasttopnm", :rasttopnm),
    ExecutableProduct("rawtopgm", :rawtopgm),
    ExecutableProduct("rawtoppm", :rawtoppm),
    ExecutableProduct("rgb3toppm", :rgb3toppm),
    ExecutableProduct("rlatopam", :rlatopam),
    ExecutableProduct("rletopnm", :rletopnm),
    ExecutableProduct("sbigtopgm", :sbigtopgm),
    ExecutableProduct("sgitopnm", :sgitopnm),
    ExecutableProduct("sirtopnm", :sirtopnm),
    ExecutableProduct("sldtoppm", :sldtoppm),
    ExecutableProduct("spctoppm", :spctoppm),
    ExecutableProduct("spottopgm", :spottopgm),
    ExecutableProduct("sputoppm", :sputoppm),
    ExecutableProduct("srftopam", :srftopam),
    ExecutableProduct("st4topgm", :st4topgm),
    ExecutableProduct("sunicontopnm", :sunicontopnm),
    ExecutableProduct("svgtopam", :svgtopam),
    ExecutableProduct("tgatoppm", :tgatoppm),
    ExecutableProduct("thinkjettopbm", :thinkjettopbm),
    ExecutableProduct("wbmptopbm", :wbmptopbm),
    ExecutableProduct("winicontopam", :winicontopam),
    ExecutableProduct("winicontoppm", :winicontoppm),
    ExecutableProduct("xbmtopbm", :xbmtopbm),
    ExecutableProduct("ximtoppm", :ximtoppm),
    ExecutableProduct("xpmtoppm", :xpmtoppm),
    ExecutableProduct("xvminitoppm", :xvminitoppm),
    ExecutableProduct("xwdtopnm", :xwdtopnm),
    ExecutableProduct("ybmtopbm", :ybmtopbm),
    ExecutableProduct("yuvsplittoppm", :yuvsplittoppm),
    ExecutableProduct("yuvtoppm", :yuvtoppm),
    ExecutableProduct("yuy2topam", :yuy2topam),
    ExecutableProduct("zeisstopnm", :zeisstopnm),
    LibraryProduct("libnetpbm", :libnetpbm),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_kbproto_jll"), # compat="1.0.7"
    BuildDependency("Xorg_xproto_jll"),  # compat="7.0.31"
    # Need at least JpegTurbo v3.0.4 for aarch64-freebsd support
    Dependency("JpegTurbo_jll"; compat="3.0.4"),
    # Need at least Libtiff v4.7.0 for aarch64-freebsd support
    Dependency("Libtiff_jll"; compat="4.7.0"),
    # Need at least XML2 v2.13.5 for aarch64-freebsd support
    Dependency("XML2_jll"; compat="2.13.5"),
    # Need at least Xorg_libX11 v1.8.6 for armv6l support
    Dependency("Xorg_libX11_jll"; compat="1.8.6"),
    # Need at least Zlib v1.2.12; older versions don't work with libpng
    # We can't declare a Zlib compat entry because this is a stdlib
    Dependency("Zlib_jll"),
    # Need at least libpng v1.6.44 for aarch64-freebsd support
    Dependency("libpng_jll"; compat="1.6.44"),
    RuntimeDependency("Ghostscript_jll"; compat="9.53.3"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"5")
