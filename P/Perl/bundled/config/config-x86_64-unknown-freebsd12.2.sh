#!/bin/sh
#
# This file was produced by running the Configure script. It holds all the
# definitions figured out by Configure. Should you modify one of these values,
# do not forget to propagate your changes by running "Configure -der". You may
# instead choose to run each of the .SH files by yourself, or "Configure -S".
#

# Package name      : perl5
# Source directory  : .
# Configuration time: Fri Nov 19 11:42:41 UTC 2021
# Configured by     : root
# Target system     : freebsd earth 11.1-release-p9 freebsd 11.1-release-p9 #0: wed feb 13 00:49:00 utc 2013 root@build.julialang.org:julia amd64 linux 

: Configure command line arguments.
config_arg0='./Configure'
config_args='-des -Dcc=cc -Dprefix=/workspace/destdir -Duserelocatableinc -Duseshrplib -Dsysroot=/opt/x86_64-unknown-freebsd12.2/x86_64-unknown-freebsd12.2/sys-root -Dccflags=-DPERL_FPU_INIT -fno-strict-aliasing -pipe -fstack-protector-strong -I/workspace/destdir/include -Dldflags=-L/workspace/destdir/lib -Wl,-rpath,/workspace/destdir/lib -Dlddlflags=-shared -L/workspace/destdir/lib -Wl,-rpath,/workspace/destdir/lib -Dusecrosscompile -Dtargethost=localhost -Dtargetarch=x86_64-unknown-freebsd12.2 -Dhostperl=/workspace/srcdir/perl-5.34.0/host/miniperl -Dhostgenerate=/workspace/srcdir/perl-5.34.0/host/generate_uudmap -Dtargetuser=root -Dtargetdir=/root/tmpdir -Dtargetport=2222 -Dusenm=false -Dosname=freebsd -Dhintfile=freebsd_11'
config_argc=20
config_arg1='-des'
config_arg2='-Dcc=cc'
config_arg3='-Dprefix=/workspace/destdir'
config_arg4='-Duserelocatableinc'
config_arg5='-Duseshrplib'
config_arg6='-Dsysroot=/opt/x86_64-unknown-freebsd12.2/x86_64-unknown-freebsd12.2/sys-root'
config_arg7='-Dccflags=-DPERL_FPU_INIT -fno-strict-aliasing -pipe -fstack-protector-strong -I/workspace/destdir/include'
config_arg8='-Dldflags=-L/workspace/destdir/lib -Wl,-rpath,/workspace/destdir/lib'
config_arg9='-Dlddlflags=-shared -L/workspace/destdir/lib -Wl,-rpath,/workspace/destdir/lib'
config_arg10='-Dusecrosscompile'
config_arg11='-Dtargethost=localhost'
config_arg12='-Dtargetarch=x86_64-unknown-freebsd12.2'
config_arg13='-Dhostperl=/workspace/srcdir/perl-5.34.0/host/miniperl'
config_arg14='-Dhostgenerate=/workspace/srcdir/perl-5.34.0/host/generate_uudmap'
config_arg15='-Dtargetuser=root'
config_arg16='-Dtargetdir=/root/tmpdir'
config_arg17='-Dtargetport=2222'
config_arg18='-Dusenm=false'
config_arg19='-Dosname=freebsd'
config_arg20='-Dhintfile=freebsd_11'

Author=''
Date=''
Header=''
Id=''
Locker=''
Log=''
RCSfile=''
Revision=''
Source=''
State=''
_a='.a'
_exe=''
_o='.o'
afs='false'
afsroot='/afs'
alignbytes='8'
aphostname='/bin/hostname'
api_revision='5'
api_subversion='0'
api_version='34'
api_versionstring='5.34.0'
ar='ar'
archlib='.../../lib/perl5/5.34.0/unknown-freebsd12.2'
archlibexp='.../../lib/perl5/5.34.0/unknown-freebsd12.2'
archname64=''
archname='unknown-freebsd12.2'
archobjs=''
asctime_r_proto='0'
awk='awk'
baserev='5.0'
bash=''
bin='.../'
bin_ELF='define'
binexp='.../'
bison='bison'
byacc='byacc'
byteorder='12345678'
c=''
castflags='0'
cat='cat'
cc='cc'
cccdlflags='-fpic --sysroot=/opt/x86_64-unknown-freebsd12.2/x86_64-unknown-freebsd12.2/sys-root'
ccdlflags='  -Wl,-R\$$ORIGIN/../lib/perl5/5.34.0/unknown-freebsd12.2/CORE'
ccflags='-DPERL_FPU_INIT -fno-strict-aliasing -pipe -fstack-protector-strong -I/workspace/destdir/include'
ccflags_uselargefiles=''
ccname='gcc'
ccsymbols=''
ccversion=''
cf_by='root'
cf_email='root@earth.nonet'
cf_time='Fri Nov 19 11:42:41 UTC 2021'
charbits='8'
charsize='1'
chgrp=''
chmod='chmod'
chown=''
clocktype='clock_t'
comm='comm'
compiler_warning='grep -i warning'
compress=''
contains='grep'
cp='cp'
cpio=''
cpp='cpp'
cpp_stuff='42'
cppccsymbols=''
cppflags='-DPERL_FPU_INIT -fno-strict-aliasing -pipe -fstack-protector-strong -I/workspace/destdir/include'
cpplast='-'
cppminus='-'
cpprun='cc  -E'
cppstdin='cc  -E'
cppsymbols='_LP64=1 __BYTE_ORDER__=1234 __ELF__=1 __FreeBSD__=12 __GNUC_MINOR__=2 __GNUC__=4 __LITTLE_ENDIAN__=1 __LP64__=1 __STDC__=1 __amd64=1 __amd64__=1 __clang__=1 __unix=1 __unix__=1 __x86_64=1 __x86_64__=1 unix=1'
crypt_r_proto='0'
cryptlib=''
csh='csh'
ctermid_r_proto='0'
ctime_r_proto='0'
d_Gconvert='sprintf((b),"%.*g",(n),(x))'
d_PRIEUldbl='define'
d_PRIFUldbl='define'
d_PRIGUldbl='define'
d_PRIXU64='define'
d_PRId64='define'
d_PRIeldbl='define'
d_PRIfldbl='define'
d_PRIgldbl='define'
d_PRIi64='define'
d_PRIo64='define'
d_PRIu64='define'
d_PRIx64='define'
d_SCNfldbl='define'
d__fwalk='undef'
d_accept4='define'
d_access='define'
d_accessx='undef'
d_acosh='define'
d_aintl='undef'
d_alarm='define'
d_archlib='define'
d_asctime64='undef'
d_asctime_r='undef'
d_asinh='define'
d_atanh='define'
d_atolf='undef'
d_atoll='define'
d_attribute_always_inline='define'
d_attribute_deprecated='define'
d_attribute_format='define'
d_attribute_malloc='define'
d_attribute_nonnull='define'
d_attribute_noreturn='define'
d_attribute_pure='define'
d_attribute_unused='define'
d_attribute_warn_unused_result='define'
d_backtrace='undef'
d_bsd='define'
d_bsdgetpgrp='undef'
d_bsdsetpgrp='define'
d_builtin_add_overflow='define'
d_builtin_choose_expr='define'
d_builtin_expect='define'
d_builtin_mul_overflow='define'
d_builtin_sub_overflow='define'
d_c99_variadic_macros='define'
d_casti32='undef'
d_castneg='define'
d_cbrt='define'
d_chown='define'
d_chroot='define'
d_chsize='undef'
d_class='undef'
d_clearenv='undef'
d_closedir='define'
d_cmsghdr_s='define'
d_copysign='define'
d_copysignl='define'
d_cplusplus='undef'
d_crypt='define'
d_crypt_r='undef'
d_csh='undef'
d_ctermid='define'
d_ctermid_r='undef'
d_ctime64='undef'
d_ctime_r='undef'
d_cuserid='undef'
d_dbminitproto='undef'
d_difftime64='undef'
d_difftime='define'
d_dir_dd_fd='undef'
d_dirfd='define'
d_dirnamlen='define'
d_dladdr='define'
d_dlerror='define'
d_dlopen='define'
d_dlsymun='undef'
d_dosuid='undef'
d_double_has_inf='define'
d_double_has_nan='define'
d_double_has_negative_zero='define'
d_double_has_subnormals='define'
d_double_style_cray='undef'
d_double_style_ibm='undef'
d_double_style_ieee='define'
d_double_style_vax='undef'
d_drand48_r='undef'
d_drand48proto='define'
d_dup2='define'
d_dup3='define'
d_duplocale='define'
d_eaccess='define'
d_endgrent='define'
d_endgrent_r='undef'
d_endhent='define'
d_endhostent_r='undef'
d_endnent='define'
d_endnetent_r='undef'
d_endpent='define'
d_endprotoent_r='undef'
d_endpwent='define'
d_endpwent_r='undef'
d_endsent='define'
d_endservent_r='undef'
d_eofnblk='define'
d_erf='define'
d_erfc='define'
d_eunice='undef'
d_exp2='define'
d_expm1='define'
d_faststdio='define'
d_fchdir='define'
d_fchmod='define'
d_fchmodat='define'
d_fchown='define'
d_fcntl='define'
d_fcntl_can_lock='define'
d_fd_macros='define'
d_fd_set='define'
d_fdclose='define'
d_fdim='define'
d_fds_bits='define'
d_fegetround='define'
d_fgetpos='define'
d_finite='define'
d_finitel='undef'
d_flexfnam='define'
d_flock='define'
d_flockproto='define'
d_fma='define'
d_fmax='define'
d_fmin='define'
d_fork='define'
d_fp_class='undef'
d_fp_classify='undef'
d_fp_classl='undef'
d_fpathconf='define'
d_fpclass='undef'
d_fpclassify='define'
d_fpclassl='undef'
d_fpgetround='define'
d_fpos64_t='undef'
d_freelocale='define'
d_frexpl='define'
d_fs_data_s='undef'
d_fseeko='define'
d_fsetpos='define'
d_fstatfs='define'
d_fstatvfs='define'
d_fsync='define'
d_ftello='define'
d_ftime='undef'
d_futimes='define'
d_gai_strerror='define'
d_gdbm_ndbm_h_uses_prototypes='undef'
d_gdbmndbm_h_uses_prototypes='undef'
d_getaddrinfo='define'
d_getcwd='define'
d_getenv_preserves_other_thread='define'
d_getespwnam='undef'
d_getfsstat='define'
d_getgrent='define'
d_getgrent_r='undef'
d_getgrgid_r='undef'
d_getgrnam_r='undef'
d_getgrps='define'
d_gethbyaddr='define'
d_gethbyname='define'
d_gethent='define'
d_gethname='define'
d_gethostbyaddr_r='undef'
d_gethostbyname_r='undef'
d_gethostent_r='undef'
d_gethostprotos='define'
d_getitimer='define'
d_getlogin='define'
d_getlogin_r='undef'
d_getmnt='undef'
d_getmntent='undef'
d_getnameinfo='define'
d_getnbyaddr='define'
d_getnbyname='define'
d_getnent='define'
d_getnetbyaddr_r='undef'
d_getnetbyname_r='undef'
d_getnetent_r='undef'
d_getnetprotos='define'
d_getpagsz='define'
d_getpbyname='define'
d_getpbynumber='define'
d_getpent='define'
d_getpgid='define'
d_getpgrp2='undef'
d_getpgrp='define'
d_getppid='define'
d_getprior='define'
d_getprotobyname_r='undef'
d_getprotobynumber_r='undef'
d_getprotoent_r='undef'
d_getprotoprotos='define'
d_getprpwnam='undef'
d_getpwent='define'
d_getpwent_r='undef'
d_getpwnam_r='undef'
d_getpwuid_r='undef'
d_getsbyname='define'
d_getsbyport='define'
d_getsent='define'
d_getservbyname_r='undef'
d_getservbyport_r='undef'
d_getservent_r='undef'
d_getservprotos='define'
d_getspnam='undef'
d_getspnam_r='undef'
d_gettimeod='define'
d_gmtime64='undef'
d_gmtime_r='undef'
d_gnulibc='undef'
d_grpasswd='define'
d_has_C_UTF8='true'
d_hasmntopt='undef'
d_htonl='define'
d_hypot='define'
d_ilogb='define'
d_ilogbl='define'
d_inc_version_list='undef'
d_inetaton='define'
d_inetntop='define'
d_inetpton='define'
d_int64_t='define'
d_ip_mreq='define'
d_ip_mreq_source='define'
d_ipv6_mreq='define'
d_ipv6_mreq_source='undef'
d_isascii='define'
d_isblank='define'
d_isfinite='define'
d_isfinitel='undef'
d_isinf='define'
d_isinfl='undef'
d_isless='define'
d_isnan='define'
d_isnanl='undef'
d_isnormal='define'
d_j0='define'
d_j0l='undef'
d_killpg='define'
d_lc_monetary_2008='define'
d_lchown='undef'
d_ldbl_dig='define'
d_ldexpl='define'
d_lgamma='define'
d_lgamma_r='define'
d_libm_lib_version='undef'
d_libname_unique='undef'
d_link='define'
d_linkat='define'
d_llrint='define'
d_llrintl='define'
d_llround='define'
d_llroundl='define'
d_localeconv_l='define'
d_localtime64='undef'
d_localtime_r='undef'
d_localtime_r_needs_tzset='undef'
d_locconv='define'
d_lockf='define'
d_log1p='define'
d_log2='define'
d_logb='define'
d_long_double_style_ieee='define'
d_long_double_style_ieee_doubledouble='undef'
d_long_double_style_ieee_extended='define'
d_long_double_style_ieee_std='undef'
d_long_double_style_vax='undef'
d_longdbl='define'
d_longlong='define'
d_lrint='define'
d_lrintl='define'
d_lround='define'
d_lroundl='define'
d_lseekproto='define'
d_lstat='define'
d_madvise='define'
d_malloc_good_size='undef'
d_malloc_size='undef'
d_malloc_usable_size='define'
d_mblen='define'
d_mbrlen='define'
d_mbrtowc='define'
d_mbstowcs='define'
d_mbtowc='define'
d_memmem='define'
d_memrchr='define'
d_mkdir='define'
d_mkdtemp='define'
d_mkfifo='define'
d_mkostemp='define'
d_mkstemp='define'
d_mkstemps='define'
d_mktime64='undef'
d_mktime='define'
d_mmap='define'
d_modfl='define'
d_modflproto='define'
d_mprotect='define'
d_msg='define'
d_msg_ctrunc='define'
d_msg_dontroute='define'
d_msg_oob='define'
d_msg_peek='define'
d_msg_proxy='undef'
d_msgctl='define'
d_msgget='define'
d_msghdr_s='define'
d_msgrcv='define'
d_msgsnd='define'
d_msync='define'
d_munmap='define'
d_mymalloc='undef'
d_nan='define'
d_nanosleep='define'
d_ndbm='define'
d_ndbm_h_uses_prototypes='define'
d_nearbyint='define'
d_newlocale='define'
d_nextafter='define'
d_nexttoward='define'
d_nice='define'
d_nl_langinfo='define'
d_nv_preserves_uv='undef'
d_nv_zero_is_allbits_zero='define'
d_off64_t='define'
d_old_pthread_create_joinable='undef'
d_oldpthreads='undef'
d_oldsock='undef'
d_open3='define'
d_openat='define'
d_pathconf='define'
d_pause='define'
d_perl_otherlibdirs='undef'
d_phostname='undef'
d_pipe2='define'
d_pipe='define'
d_poll='define'
d_portable='define'
d_prctl='undef'
d_prctl_set_name='undef'
d_printf_format_null='define'
d_procselfexe='undef'
d_pseudofork='undef'
d_pthread_atfork='define'
d_pthread_attr_setscope='define'
d_pthread_yield='define'
d_ptrdiff_t='define'
d_pwage='undef'
d_pwchange='define'
d_pwclass='define'
d_pwcomment='undef'
d_pwexpire='define'
d_pwgecos='define'
d_pwpasswd='define'
d_pwquota='undef'
d_qgcvt='undef'
d_quad='define'
d_querylocale='define'
d_random_r='undef'
d_re_comp='undef'
d_readdir64_r='undef'
d_readdir='define'
d_readdir_r='undef'
d_readlink='define'
d_readv='define'
d_recvmsg='define'
d_regcmp='undef'
d_regcomp='define'
d_remainder='define'
d_remquo='define'
d_rename='define'
d_renameat='define'
d_rewinddir='define'
d_rint='define'
d_rmdir='define'
d_round='define'
d_sbrkproto='define'
d_scalbn='define'
d_scalbnl='define'
d_sched_yield='define'
d_scm_rights='define'
d_seekdir='define'
d_select='define'
d_sem='define'
d_semctl='define'
d_semctl_semid_ds='define'
d_semctl_semun='define'
d_semget='define'
d_semop='define'
d_sendmsg='define'
d_setegid='define'
d_seteuid='define'
d_setgrent='define'
d_setgrent_r='undef'
d_setgrps='define'
d_sethent='define'
d_sethostent_r='undef'
d_setitimer='define'
d_setlinebuf='define'
d_setlocale='define'
d_setlocale_accepts_any_locale_name='undef'
d_setlocale_r='undef'
d_setnent='define'
d_setnetent_r='undef'
d_setpent='define'
d_setpgid='define'
d_setpgrp2='undef'
d_setpgrp='define'
d_setprior='define'
d_setproctitle='define'
d_setprotoent_r='undef'
d_setpwent='define'
d_setpwent_r='undef'
d_setregid='define'
d_setresgid='define'
d_setresuid='define'
d_setreuid='define'
d_setrgid='define'
d_setruid='define'
d_setsent='define'
d_setservent_r='undef'
d_setsid='define'
d_setvbuf='define'
d_shm='define'
d_shmat='define'
d_shmatprototype='define'
d_shmctl='define'
d_shmdt='define'
d_shmget='define'
d_sigaction='define'
d_siginfo_si_addr='define'
d_siginfo_si_band='define'
d_siginfo_si_errno='define'
d_siginfo_si_fd='undef'
d_siginfo_si_pid='define'
d_siginfo_si_status='define'
d_siginfo_si_uid='define'
d_siginfo_si_value='define'
d_signbit='define'
d_sigprocmask='define'
d_sigsetjmp='define'
d_sin6_scope_id='define'
d_sitearch='define'
d_snprintf='define'
d_sockaddr_in6='define'
d_sockaddr_sa_len='define'
d_sockaddr_storage='define'
d_sockatmark='define'
d_sockatmarkproto='define'
d_socket='define'
d_socklen_t='define'
d_sockpair='define'
d_socks5_init='undef'
d_sqrtl='define'
d_srand48_r='undef'
d_srandom_r='undef'
d_sresgproto='define'
d_sresuproto='define'
d_stat='define'
d_statblks='define'
d_statfs_f_flags='define'
d_statfs_s='define'
d_static_inline='define'
d_statvfs='define'
d_stdio_cnt_lval='define'
d_stdio_ptr_lval='define'
d_stdio_ptr_lval_nochange_cnt='define'
d_stdio_ptr_lval_sets_cnt='undef'
d_stdio_stream_array='undef'
d_stdiobase='define'
d_stdstdio='define'
d_strcoll='define'
d_strerror_l='undef'
d_strerror_r='undef'
d_strftime='define'
d_strlcat='define'
d_strlcpy='define'
d_strnlen='define'
d_strtod='define'
d_strtod_l='define'
d_strtol='define'
d_strtold='define'
d_strtold_l='define'
d_strtoll='define'
d_strtoq='define'
d_strtoul='define'
d_strtoull='define'
d_strtouq='define'
d_strxfrm='define'
d_suidsafe='undef'
d_symlink='define'
d_syscall='define'
d_syscallproto='define'
d_sysconf='define'
d_sysernlst=''
d_syserrlst='define'
d_system='define'
d_tcgetpgrp='define'
d_tcsetpgrp='define'
d_telldir='define'
d_telldirproto='define'
d_tgamma='define'
d_thread_safe_nl_langinfo_l='undef'
d_time='define'
d_timegm='define'
d_times='define'
d_tm_tm_gmtoff='define'
d_tm_tm_zone='define'
d_tmpnam_r='undef'
d_towlower='define'
d_towupper='define'
d_trunc='define'
d_truncate='define'
d_truncl='define'
d_ttyname_r='undef'
d_tzname='define'
d_u32align='define'
d_ualarm='define'
d_umask='define'
d_uname='define'
d_union_semun='undef'
d_unlinkat='define'
d_unordered='undef'
d_unsetenv='define'
d_uselocale='define'
d_usleep='define'
d_usleepproto='define'
d_ustat='undef'
d_vendorarch='undef'
d_vendorbin='undef'
d_vendorlib='undef'
d_vendorscript='undef'
d_vfork='undef'
d_void_closedir='undef'
d_voidsig='define'
d_voidtty=''
d_vsnprintf='define'
d_wait4='define'
d_waitpid='define'
d_wcrtomb='define'
d_wcscmp='define'
d_wcstombs='define'
d_wcsxfrm='define'
d_wctomb='define'
d_writev='define'
d_xenix='undef'
date='date'
db_hashtype='u_int32_t'
db_prefixtype='size_t'
db_version_major='1'
db_version_minor='0'
db_version_patch='0'
default_inc_excludes_dot='define'
direntrytype='struct dirent'
dlext='so'
dlsrc='dl_dlopen.xs'
doubleinfbytes='0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xf0, 0x7f'
doublekind='3'
doublemantbits='52'
doublenanbytes='0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xf8, 0xff'
doublesize='8'
drand01='Perl_drand48()'
drand48_r_proto='0'
dtrace=''
dtraceobject=''
dtracexnolibs=''
dynamic_ext='B Compress/Raw/Bzip2 Compress/Raw/Zlib Cwd DB_File Data/Dumper Devel/PPPort Devel/Peek Digest/MD5 Digest/SHA Encode Fcntl File/DosGlob File/Glob Filter/Util/Call Hash/Util Hash/Util/FieldHash I18N/Langinfo IO IPC/SysV List/Util MIME/Base64 Math/BigInt/FastCalc NDBM_File Opcode POSIX PerlIO/encoding PerlIO/mmap PerlIO/scalar PerlIO/via SDBM_File Socket Storable Sys/Hostname Sys/Syslog Term/ReadLine/Gnu TermReadKey Time/HiRes Time/Piece Unicode/Collate Unicode/Normalize XS/APItest XS/Typemap attributes mro re threads threads/shared'
eagain='EAGAIN'
ebcdic='undef'
echo='echo'
egrep='egrep'
emacs=''
endgrent_r_proto='0'
endhostent_r_proto='0'
endnetent_r_proto='0'
endprotoent_r_proto='0'
endpwent_r_proto='0'
endservent_r_proto='0'
eunicefix=':'
exe_ext=''
expr='expr'
extensions='B Compress/Raw/Bzip2 Compress/Raw/Zlib Cwd DB_File Data/Dumper Devel/PPPort Devel/Peek Digest/MD5 Digest/SHA Encode Fcntl File/DosGlob File/Glob Filter/Util/Call Hash/Util Hash/Util/FieldHash I18N/Langinfo IO IPC/SysV List/Util MIME/Base64 Math/BigInt/FastCalc NDBM_File Opcode POSIX PerlIO/encoding PerlIO/mmap PerlIO/scalar PerlIO/via SDBM_File Socket Storable Sys/Hostname Sys/Syslog Term/ReadLine/Gnu TermReadKey Time/HiRes Time/Piece Unicode/Collate Unicode/Normalize XS/APItest XS/Typemap attributes mro re threads threads/shared Archive/Tar Attribute/Handlers AutoLoader CPAN CPAN/Meta CPAN/Meta/Requirements CPAN/Meta/YAML Carp Config/Perl/V Devel/SelfStubber Digest Dumpvalue Env Errno Exporter ExtUtils/CBuilder ExtUtils/Constant ExtUtils/Install ExtUtils/MakeMaker ExtUtils/Manifest ExtUtils/Miniperl ExtUtils/PL2Bat ExtUtils/ParseXS File/Fetch File/Find File/Path File/Temp FileCache Filter/Simple FindBin Getopt/Long HTTP/Tiny I18N/Collate I18N/LangTags IO/Compress IO/Socket/IP IO/Zlib IPC/Cmd IPC/Open3 JSON JSON/PP Locale/Maketext Locale/Maketext/Simple Math/BigInt Math/BigRat Math/Complex Memoize Module/CoreList Module/Load Module/Load/Conditional Module/Loaded Module/Metadata NEXT Net/Ping Params/Check Perl/OSType PerlIO/via/QuotedPrint Pod/Checker Pod/Escapes Pod/Functions Pod/Html Pod/Perldoc Pod/Simple Pod/Usage SVG Safe Search/Dict SelfLoader Term/ANSIColor Term/Cap Term/Complete Term/ReadLine Test Test/Harness Test/Simple Text/Abbrev Text/Balanced Text/ParseWords Text/Tabs Thread/Queue Thread/Semaphore Tie/File Tie/Hash/NamedCapture Tie/Memoize Tie/RefHash Time/Local XML/NamespaceSupport XML/SAX XML/SAX/Base XML/Writer XSLoader autodie autouse base bignum constant encoding/warnings experimental if lib libnet parent perlfaq podlators version'
extern_C='extern'
extras=''
fflushNULL='define'
fflushall='undef'
find=''
firstmakefile='makefile'
flex=''
fpossize='8'
fpostype='fpos_t'
freetype='void'
from='/workspace/srcdir/perl-5.34.0/Cross/from-scp'
full_ar='/opt/bin/x86_64-unknown-freebsd12.2-libgfortran4-cxx11/ar'
full_csh='csh'
full_sed='/bin/sed'
gccansipedantic=''
gccosandvers=''
gccversion='Clang 12.0.0 (/home/mose/.julia/dev/BinaryBuilderBase/deps/downloads/llvm-project.git d28af7c654d8db0b68c175db5ce212d74fb5e9bc)'
getgrent_r_proto='0'
getgrgid_r_proto='0'
getgrnam_r_proto='0'
gethostbyaddr_r_proto='0'
gethostbyname_r_proto='0'
gethostent_r_proto='0'
getlogin_r_proto='0'
getnetbyaddr_r_proto='0'
getnetbyname_r_proto='0'
getnetent_r_proto='0'
getprotobyname_r_proto='0'
getprotobynumber_r_proto='0'
getprotoent_r_proto='0'
getpwent_r_proto='0'
getpwnam_r_proto='0'
getpwuid_r_proto='0'
getservbyname_r_proto='0'
getservbyport_r_proto='0'
getservent_r_proto='0'
getspnam_r_proto='0'
gidformat='"u"'
gidsign='1'
gidsize='4'
gidtype='gid_t'
glibpth=' /opt/x86_64-unknown-freebsd12.2/x86_64-unknown-freebsd12.2/sys-root/usr/shlib /opt/x86_64-unknown-freebsd12.2/x86_64-unknown-freebsd12.2/sys-root/lib /opt/x86_64-unknown-freebsd12.2/x86_64-unknown-freebsd12.2/sys-root/usr/lib /opt/x86_64-unknown-freebsd12.2/x86_64-unknown-freebsd12.2/sys-root/usr/lib/386 /opt/x86_64-unknown-freebsd12.2/x86_64-unknown-freebsd12.2/sys-root/lib/386 /opt/x86_64-unknown-freebsd12.2/x86_64-unknown-freebsd12.2/sys-root/usr/ccs/lib /opt/x86_64-unknown-freebsd12.2/x86_64-unknown-freebsd12.2/sys-root/usr/ucblib /opt/x86_64-unknown-freebsd12.2/x86_64-unknown-freebsd12.2/sys-root/usr/local/lib'
gmake='gmake'
gmtime_r_proto='0'
gnulibc_version=''
grep='grep'
groupcat='cat /etc/group'
groupstype='gid_t'
gzip='gzip'
h_fcntl='false'
h_sysfile='true'
hint='recommended'
hostcat='cat /etc/hosts'
hostgenerate='/workspace/srcdir/perl-5.34.0/host/generate_uudmap'
hostosname='linux'
hostperl='/workspace/srcdir/perl-5.34.0/host/miniperl'
html1dir=' '
html1direxp=''
html3dir=' '
html3direxp=''
i16size='2'
i16type='short'
i32size='4'
i32type='int'
i64size='8'
i64type='long'
i8size='1'
i8type='signed char'
i_arpainet='define'
i_bfd='undef'
i_bsdioctl=''
i_crypt='undef'
i_db='define'
i_dbm='undef'
i_dirent='define'
i_dlfcn='define'
i_execinfo='define'
i_fcntl='undef'
i_fenv='define'
i_fp='undef'
i_fp_class='undef'
i_gdbm='undef'
i_gdbm_ndbm='undef'
i_gdbmndbm='undef'
i_grp='define'
i_ieeefp='define'
i_inttypes='define'
i_langinfo='define'
i_libutil='define'
i_locale='define'
i_machcthr='undef'
i_malloc='define'
i_mallocmalloc='undef'
i_mntent='undef'
i_ndbm='define'
i_netdb='define'
i_neterrno='undef'
i_netinettcp='define'
i_niin='define'
i_poll='define'
i_prot='undef'
i_pthread='define'
i_pwd='define'
i_quadmath='undef'
i_rpcsvcdbm='undef'
i_sgtty='undef'
i_shadow='undef'
i_socks='undef'
i_stdbool='define'
i_stdint='define'
i_stdlib='define'
i_sunmath='undef'
i_sysaccess='undef'
i_sysdir='define'
i_sysfile='define'
i_sysfilio='define'
i_sysin='undef'
i_sysioctl='define'
i_syslog='define'
i_sysmman='define'
i_sysmode='undef'
i_sysmount='define'
i_sysndir='undef'
i_sysparam='define'
i_syspoll='define'
i_sysresrc='define'
i_syssecrt='undef'
i_sysselct='define'
i_syssockio='define'
i_sysstat='define'
i_sysstatfs='undef'
i_sysstatvfs='define'
i_systime='define'
i_systimek='undef'
i_systimes='define'
i_systypes='define'
i_sysuio='define'
i_sysun='define'
i_sysutsname='define'
i_sysvfs='undef'
i_syswait='define'
i_termio='undef'
i_termios='define'
i_time='define'
i_unistd='define'
i_ustat='undef'
i_utime='define'
i_vfork='undef'
i_wchar='define'
i_wctype='define'
i_xlocale='define'
ignore_versioned_solibs=''
inc_version_list=' '
inc_version_list_init='0'
incpath=''
incpth='/opt/x86_64-linux-musl/lib/clang/12.0.0/include /opt/x86_64-unknown-freebsd12.2/x86_64-unknown-freebsd12.2/sys-root/include'
inews=''
initialinstalllocation='/workspace/destdir/bin'
installarchlib='.../../lib/perl5/5.34.0/unknown-freebsd12.2'
installbin='/workspace/destdir/bin'
installhtml1dir=''
installhtml3dir=''
installman1dir=''
installman3dir=''
installprefix='/workspace/destdir'
installprefixexp='.../..'
installprivlib='.../../lib/perl5/5.34.0'
installscript='.../'
installsitearch='.../../lib/perl5/site_perl/5.34.0/unknown-freebsd12.2'
installsitebin='.../../bin'
installsitehtml1dir=''
installsitehtml3dir=''
installsitelib='.../../lib/perl5/site_perl/5.34.0'
installsiteman1dir=''
installsiteman3dir=''
installsitescript='.../../bin'
installstyle='lib/perl5'
installusrbinperl='undef'
installvendorarch=''
installvendorbin=''
installvendorhtml1dir=''
installvendorhtml3dir=''
installvendorlib=''
installvendorman1dir=''
installvendorman3dir=''
installvendorscript=''
intsize='4'
issymlink='test -h'
ivdformat='"ld"'
ivsize='8'
ivtype='long'
known_extensions='Amiga/ARexx Amiga/Exec Archive/Tar Attribute/Handlers AutoLoader B CPAN CPAN/Meta CPAN/Meta/Requirements CPAN/Meta/YAML Carp Compress/Raw/Bzip2 Compress/Raw/Zlib Config/Perl/V Cwd DB_File Data/Dumper Devel/PPPort Devel/Peek Devel/SelfStubber Digest Digest/MD5 Digest/SHA Dumpvalue Encode Env Errno Exporter ExtUtils/CBuilder ExtUtils/Constant ExtUtils/Install ExtUtils/MakeMaker ExtUtils/Manifest ExtUtils/Miniperl ExtUtils/PL2Bat ExtUtils/ParseXS Fcntl File/DosGlob File/Fetch File/Find File/Glob File/Path File/Temp FileCache Filter/Simple Filter/Util/Call FindBin GDBM_File Getopt/Long HTTP/Tiny Hash/Util Hash/Util/FieldHash I18N/Collate I18N/LangTags I18N/Langinfo IO IO/Compress IO/Socket/IP IO/Zlib IPC/Cmd IPC/Open3 IPC/SysV JSON JSON/PP List/Util Locale/Maketext Locale/Maketext/Simple MIME/Base64 Math/BigInt Math/BigInt/FastCalc Math/BigRat Math/Complex Memoize Module/CoreList Module/Load Module/Load/Conditional Module/Loaded Module/Metadata NDBM_File NEXT Net/Ping ODBM_File Opcode POSIX Params/Check Perl/OSType PerlIO/encoding PerlIO/mmap PerlIO/scalar PerlIO/via PerlIO/via/QuotedPrint Pod/Checker Pod/Escapes Pod/Functions Pod/Html Pod/Perldoc Pod/Simple Pod/Usage SDBM_File SVG Safe Search/Dict SelfLoader Socket Storable Sys/Hostname Sys/Syslog Term/ANSIColor Term/Cap Term/Complete Term/ReadLine Term/ReadLine/Gnu TermReadKey Test Test/Harness Test/Simple Text/Abbrev Text/Balanced Text/ParseWords Text/Tabs Thread/Queue Thread/Semaphore Tie/File Tie/Hash/NamedCapture Tie/Memoize Tie/RefHash Time/HiRes Time/Local Time/Piece Unicode/Collate Unicode/Normalize VMS/DCLsym VMS/Filespec VMS/Stdio Win32 Win32API/File Win32CORE XML/NamespaceSupport XML/SAX XML/SAX/Base XML/Writer XS/APItest XS/Typemap XSLoader attributes autodie autouse base bignum constant encoding/warnings experimental if lib libnet mro parent perlfaq podlators re threads threads/shared version '
ksh=''
ld='cc'
ld_can_script='define'
lddlflags='-shared -L/workspace/destdir/lib -Wl,-rpath,/workspace/destdir/lib --sysroot=/opt/x86_64-unknown-freebsd12.2/x86_64-unknown-freebsd12.2/sys-root -fstack-protector-strong'
ldflags='-L/workspace/destdir/lib -Wl,-rpath,/workspace/destdir/lib -fstack-protector-strong'
ldflags_uselargefiles=''
ldlibpthname='LD_LIBRARY_PATH'
less='less'
lib_ext='.a'
libc=''
libperl='libperl.so'
libpth='/opt/x86_64-linux-musl/lib/clang/12.0.0/lib /opt/x86_64-unknown-freebsd12.2/x86_64-unknown-freebsd12.2/sys-root/lib /opt/x86_64-unknown-freebsd12.2/x86_64-unknown-freebsd12.2/sys-root/usr/lib /workspace/x86_64-unknown-freebsd12.2-libgfortran4-cxx11/destdir/lib'
libs='-lpthread -ldl -lm -lcrypt -lutil -lc'
libsdirs=' /opt/x86_64-unknown-freebsd12.2/x86_64-unknown-freebsd12.2/sys-root/usr/lib'
libsfiles=' libpthread.so libdl.so libm.so libcrypt.so libutil.so libc.so'
libsfound=' /opt/x86_64-unknown-freebsd12.2/x86_64-unknown-freebsd12.2/sys-root/usr/lib/libpthread.so /opt/x86_64-unknown-freebsd12.2/x86_64-unknown-freebsd12.2/sys-root/usr/lib/libdl.so /opt/x86_64-unknown-freebsd12.2/x86_64-unknown-freebsd12.2/sys-root/usr/lib/libm.so /opt/x86_64-unknown-freebsd12.2/x86_64-unknown-freebsd12.2/sys-root/usr/lib/libcrypt.so /opt/x86_64-unknown-freebsd12.2/x86_64-unknown-freebsd12.2/sys-root/usr/lib/libutil.so /opt/x86_64-unknown-freebsd12.2/x86_64-unknown-freebsd12.2/sys-root/usr/lib/libc.so'
libspath=' /opt/x86_64-linux-musl/lib/clang/12.0.0/lib /opt/x86_64-unknown-freebsd12.2/x86_64-unknown-freebsd12.2/sys-root/lib /opt/x86_64-unknown-freebsd12.2/x86_64-unknown-freebsd12.2/sys-root/usr/lib /workspace/x86_64-unknown-freebsd12.2-libgfortran4-cxx11/destdir/lib'
libswanted='cl pthread socket bind inet nsl ndbm gdbm dbm db malloc dl ld sun m crypt sec util c cposix posix ucb bsd BSD'
libswanted_uselargefiles=''
line=''
lint=''
lkflags=''
ln='ln'
lns='/bin/ln -s'
localtime_r_proto='0'
locincpth=' '
loclibpth=' '
longdblinfbytes='0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0xff, 0x7f, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00'
longdblkind='3'
longdblmantbits='64'
longdblnanbytes='0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xc0, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00'
longdblsize='16'
longlongsize='8'
longsize='8'
lp=''
lpr=''
ls='ls'
lseeksize='8'
lseektype='off_t'
mail=''
mailx=''
make='make'
make_set_make='#'
mallocobj=''
mallocsrc=''
malloctype='void *'
man1dir=' '
man1direxp=''
man1ext='0'
man3dir=' '
man3direxp=''
man3ext='0'
mips_type=''
mistrustnm=''
mkdir='mkdir'
mmaptype='void *'
modetype='mode_t'
more='more'
multiarch='undef'
mv=''
myarchname='x86_64-freebsd'
mydomain='.nonet'
myhostname='earth'
myuname='freebsd earth 11.1-release-p9 freebsd 11.1-release-p9 #0: wed feb 13 00:49:00 utc 2013 root@build.julialang.org:julia amd64 linux '
n='-n'
need_va_copy='define'
netdb_hlen_type='size_t'
netdb_host_type='char *'
netdb_name_type='const char *'
netdb_net_type='in_addr_t'
nm='nm'
nm_opt=''
nm_so_opt='--dynamic'
nonxs_ext='Archive/Tar Attribute/Handlers AutoLoader CPAN CPAN/Meta CPAN/Meta/Requirements CPAN/Meta/YAML Carp Config/Perl/V Devel/SelfStubber Digest Dumpvalue Env Errno Exporter ExtUtils/CBuilder ExtUtils/Constant ExtUtils/Install ExtUtils/MakeMaker ExtUtils/Manifest ExtUtils/Miniperl ExtUtils/PL2Bat ExtUtils/ParseXS File/Fetch File/Find File/Path File/Temp FileCache Filter/Simple FindBin Getopt/Long HTTP/Tiny I18N/Collate I18N/LangTags IO/Compress IO/Socket/IP IO/Zlib IPC/Cmd IPC/Open3 JSON JSON/PP Locale/Maketext Locale/Maketext/Simple Math/BigInt Math/BigRat Math/Complex Memoize Module/CoreList Module/Load Module/Load/Conditional Module/Loaded Module/Metadata NEXT Net/Ping Params/Check Perl/OSType PerlIO/via/QuotedPrint Pod/Checker Pod/Escapes Pod/Functions Pod/Html Pod/Perldoc Pod/Simple Pod/Usage SVG Safe Search/Dict SelfLoader Term/ANSIColor Term/Cap Term/Complete Term/ReadLine Test Test/Harness Test/Simple Text/Abbrev Text/Balanced Text/ParseWords Text/Tabs Thread/Queue Thread/Semaphore Tie/File Tie/Hash/NamedCapture Tie/Memoize Tie/RefHash Time/Local XML/NamespaceSupport XML/SAX XML/SAX/Base XML/Writer XSLoader autodie autouse base bignum constant encoding/warnings experimental if lib libnet parent perlfaq podlators version'
nroff='nroff'
nvEUformat='"E"'
nvFUformat='"F"'
nvGUformat='"G"'
nv_overflows_integers_at='256.0*256.0*256.0*256.0*256.0*256.0*2.0*2.0*2.0*2.0*2.0'
nv_preserves_uv_bits='53'
nveformat='"e"'
nvfformat='"f"'
nvgformat='"g"'
nvmantbits='52'
nvsize='8'
nvtype='double'
o_nonblock='O_NONBLOCK'
obj_ext='.o'
old_pthread_create_joinable=''
optimize='-O'
orderlib='false'
osname='freebsd'
osvers='11'
otherlibdirs=' '
package='perl5'
pager='/usr/bin/less -R'
passcat='cat /etc/passwd'
patchlevel='34'
path_sep=':'
perl5='/usr/bin/perl'
perl='perl'
perl_patchlevel=''
perl_static_inline='static __inline__'
perladmin='root@earth.nonet'
perllibs='-lpthread -ldl -lm -lcrypt -lutil -lc'
perlpath='/workspace/destdir/bin/perl'
pg='pg'
phostname='hostname'
pidtype='pid_t'
plibpth=''
pmake=''
pr=''
prefix='.../..'
prefixexp='.../..'
privlib='.../../lib/perl5/5.34.0'
privlibexp='.../../lib/perl5/5.34.0'
procselfexe=''
ptrsize='8'
quadkind='2'
quadtype='long'
randbits='48'
randfunc='Perl_drand48'
random_r_proto='0'
randseedtype='U32'
ranlib=':'
rd_nodata='-1'
readdir64_r_proto='0'
readdir_r_proto='0'
revision='5'
rm='rm'
rm_try='/bin/rm -f try try a.out .out try.[cho] try..o core core.try* try.core*'
rmail=''
run='/workspace/srcdir/perl-5.34.0/Cross/run-ssh'
runnm='false'
sGMTIME_max='72057594037927935'
sGMTIME_min='-62167219200'
sLOCALTIME_max='67767976233532799'
sLOCALTIME_min='-62167219200'
sPRIEUldbl='"LE"'
sPRIFUldbl='"LF"'
sPRIGUldbl='"LG"'
sPRIXU64='"lX"'
sPRId64='"ld"'
sPRIeldbl='"Le"'
sPRIfldbl='"Lf"'
sPRIgldbl='"Lg"'
sPRIi64='"li"'
sPRIo64='"lo"'
sPRIu64='"lu"'
sPRIx64='"lx"'
sSCNfldbl='"Lf"'
sched_yield='sched_yield()'
scriptdir='.../'
scriptdirexp='.../'
sed='sed'
seedfunc='Perl_drand48_init'
selectminbits='64'
selecttype='fd_set *'
sendmail=''
setgrent_r_proto='0'
sethostent_r_proto='0'
setlocale_r_proto='0'
setnetent_r_proto='0'
setprotoent_r_proto='0'
setpwent_r_proto='0'
setservent_r_proto='0'
sh='/bin/sh'
shar=''
sharpbang='#!'
shmattype='void *'
shortsize='2'
shrpenv=''
shsharp='true'
sig_count='32'
sig_name='ZERO HUP INT QUIT ILL TRAP ABRT EMT FPE KILL BUS SEGV SYS PIPE ALRM TERM URG STOP TSTP CONT CHLD TTIN TTOU IO XCPU XFSZ VTALRM PROF WINCH INFO USR1 USR2 IOT THR '
sig_name_init='"ZERO", "HUP", "INT", "QUIT", "ILL", "TRAP", "ABRT", "EMT", "FPE", "KILL", "BUS", "SEGV", "SYS", "PIPE", "ALRM", "TERM", "URG", "STOP", "TSTP", "CONT", "CHLD", "TTIN", "TTOU", "IO", "XCPU", "XFSZ", "VTALRM", "PROF", "WINCH", "INFO", "USR1", "USR2", "IOT", "THR", 0'
sig_num='0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 6 32 '
sig_num_init='0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 6, 32, 0'
sig_size='34'
signal_t='void'
sitearch='.../../lib/perl5/site_perl/5.34.0/unknown-freebsd12.2'
sitearchexp='.../../lib/perl5/site_perl/5.34.0/unknown-freebsd12.2'
sitebin='.../../bin'
sitebinexp='.../../bin'
sitehtml1dir=''
sitehtml1direxp=''
sitehtml3dir=''
sitehtml3direxp=''
sitelib='.../../lib/perl5/site_perl/5.34.0'
sitelib_stem='.../../lib/perl5/site_perl'
sitelibexp='.../../lib/perl5/site_perl/5.34.0'
siteman1dir=''
siteman1direxp=''
siteman3dir=''
siteman3direxp=''
siteprefix='.../..'
siteprefixexp='.../..'
sitescript='.../../bin'
sitescriptexp='.../../bin'
sizesize='8'
sizetype='size_t'
sleep=''
smail=''
so='so'
sockethdr=''
socketlib=''
socksizetype='socklen_t'
sort='sort'
spackage='Perl5'
spitshell='cat'
srand48_r_proto='0'
srandom_r_proto='0'
src='.'
ssizetype='ssize_t'
st_ino_sign='1'
st_ino_size='8'
startperl='#!/workspace/destdir/bin/perl'
startsh='#!/bin/sh'
static_ext=' '
stdchar='char'
stdio_base='((fp)->_ub._base ? (fp)->_ub._base : (fp)->_bf._base)'
stdio_bufsiz='((fp)->_ub._base ? (fp)->_ub._size : (fp)->_bf._size)'
stdio_cnt='((fp)->_r)'
stdio_filbuf=''
stdio_ptr='((fp)->_p)'
stdio_stream_array=''
strerror_r_proto='0'
submit=''
subversion='0'
sysman='/usr/share/man/man1'
sysroot='/opt/x86_64-unknown-freebsd12.2/x86_64-unknown-freebsd12.2/sys-root'
tail=''
tar=''
targetarch='x86_64-unknown-freebsd12.2'
targetdir='/root/tmpdir'
targetenv=''
targethost='localhost'
targetmkdir='/workspace/srcdir/perl-5.34.0/Cross/mkdir'
targetport='2222'
targetsh='/bin/sh'
tbl=''
tee=''
test='test'
timeincl='/opt/x86_64-unknown-freebsd12.2/x86_64-unknown-freebsd12.2/sys-root/include/sys/time.h '
timetype='time_t'
tmpnam_r_proto='0'
to='/workspace/srcdir/perl-5.34.0/Cross/to-scp'
touch='touch'
tr='tr'
trnl='\n'
troff=''
ttyname_r_proto='0'
u16size='2'
u16type='unsigned short'
u32size='4'
u32type='unsigned int'
u64size='8'
u64type='unsigned long'
u8size='1'
u8type='unsigned char'
uidformat='"u"'
uidsign='1'
uidsize='4'
uidtype='uid_t'
uname='uname'
uniq='uniq'
uquadtype='unsigned long'
use64bitall='define'
use64bitint='define'
usecbacktrace='undef'
usecrosscompile='define'
usedefaultstrict='undef'
usedevel='undef'
usedl='define'
usedtrace='undef'
usefaststdio='undef'
useithreads='undef'
usekernprocpathname='define'
uselanginfo='true'
uselargefiles='define'
uselongdouble='undef'
usemallocwrap='undef'
usemorebits='undef'
usemultiplicity='undef'
usemymalloc='n'
usenm='false'
usensgetexecutablepath='undef'
useopcode='true'
useperlio='define'
useposix='true'
usequadmath='undef'
usereentrant='undef'
userelocatableinc='define'
useshrplib='true'
usesitecustomize='undef'
usesocks='undef'
usethreads='undef'
usevendorprefix='undef'
useversionedarchname='undef'
usevfork='false'
usrinc='/opt/x86_64-unknown-freebsd12.2/x86_64-unknown-freebsd12.2/sys-root/usr/include'
uuname=''
uvXUformat='"lX"'
uvoformat='"lo"'
uvsize='8'
uvtype='unsigned long'
uvuformat='"lu"'
uvxformat='"lx"'
vendorarch=''
vendorarchexp=''
vendorbin=''
vendorbinexp=''
vendorhtml1dir=' '
vendorhtml1direxp=''
vendorhtml3dir=' '
vendorhtml3direxp=''
vendorlib=''
vendorlib_stem=''
vendorlibexp=''
vendorman1dir=' '
vendorman1direxp=''
vendorman3dir=' '
vendorman3direxp=''
vendorprefix=''
vendorprefixexp=''
vendorscript=''
vendorscriptexp=''
version='5.34.0'
version_patchlevel_string='version 34 subversion 0'
versiononly='undef'
vi=''
xlibpth=' /opt/x86_64-unknown-freebsd12.2/x86_64-unknown-freebsd12.2/sys-root/usr/lib/386 /opt/x86_64-unknown-freebsd12.2/x86_64-unknown-freebsd12.2/sys-root/lib/386'
yacc='yacc'
yaccflags=''
zcat=''
zip='zip'
PERL_REVISION=5
PERL_VERSION=34
PERL_SUBVERSION=0
PERL_API_REVISION=5
PERL_API_VERSION=34
PERL_API_SUBVERSION=0
PERL_PATCHLEVEL=''
PERL_CONFIG_SH=true
