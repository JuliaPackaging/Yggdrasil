configure_file(src/inspkt_c/main.x ${CMAKE_BINARY_DIR}/inspekt_main.c)
configure_file(src/inspkt_c/inspekt.pgm ${CMAKE_BINARY_DIR}/inspekt.c)

set(INSPEKT_SRCS
  src/inspkt_c/bgroup_1.c
  src/inspkt_c/chunk.c
  src/inspkt_c/clmgr.c
  src/inspkt_c/expand.c
  src/inspkt_c/fetcha.c
  src/inspkt_c/fgroup_1.c
  src/inspkt_c/fmtdp.c
  src/inspkt_c/fmtint.c
  src/inspkt_c/fmttim.c
  src/inspkt_c/hlpmen.c
  src/inspkt_c/hlptxt.c
  src/inspkt_c/inspkn.c
  src/inspkt_c/kerman.c
  src/inspkt_c/list.c
  src/inspkt_c/liter.c
  src/inspkt_c/namxpn.c
  src/inspkt_c/nspcht.c
  src/inspkt_c/nspdel.c
  src/inspkt_c/nspflg.c
  src/inspkt_c/nspfnd.c
  src/inspkt_c/nspfrp.c
  src/inspkt_c/nsphi.c
  src/inspkt_c/nsphlp.c
  src/inspkt_c/nspint.c
  src/inspkt_c/nspset.c
  src/inspkt_c/nspshc.c
  src/inspkt_c/nspsho.c
  src/inspkt_c/nsptab.c
  src/inspkt_c/nsptv.c
  src/inspkt_c/nspvrb.c
  src/inspkt_c/other.c
  src/inspkt_c/param.c
  src/inspkt_c/params.c
  src/inspkt_c/prep.c
  src/inspkt_c/preprc.c
  src/inspkt_c/proc.c
  src/inspkt_c/setchr.c
  src/inspkt_c/size.c
  src/inspkt_c/subtex.c
  src/inspkt_c/tempb.c
  src/inspkt_c/title.c
  src/inspkt_c/tokens.c
  src/inspkt_c/var.c
  src/inspkt_c/wrtnpr.c
  src/inspkt_c/wrtprs.c
  src/inspkt_c/zzhlp000.c
  src/inspkt_c/zzhlp001.c
  src/inspkt_c/zzhlp002.c
  src/inspkt_c/zzhlp003.c
  src/inspkt_c/zzhlp004.c
  src/inspkt_c/zzhlp005.c
  src/inspkt_c/zzhlp006.c
  src/inspkt_c/zzhlp007.c
  src/inspkt_c/zzhlp008.c
  src/inspkt_c/zzhlp009.c
  src/inspkt_c/zzhlp010.c
  src/inspkt_c/zzhlp011.c
  src/inspkt_c/zzhlp012.c
  src/inspkt_c/zzhlp013.c
  src/inspkt_c/zzhlp014.c
  src/inspkt_c/zzhlp015.c
  src/inspkt_c/zzhlp016.c
  src/inspkt_c/zzhlp017.c
  src/inspkt_c/zzhlp018.c
  src/inspkt_c/zzhlp019.c
  src/inspkt_c/zzhlp020.c
  src/inspkt_c/zzhlp021.c
  src/inspkt_c/zzhlp022.c
  src/inspkt_c/zzhlp023.c
  src/inspkt_c/zzhlp024.c
  src/inspkt_c/zzhlp025.c
  src/inspkt_c/zzhlp026.c
  src/inspkt_c/zzhlp027.c
  src/inspkt_c/zzhlp028.c
  src/inspkt_c/zzhlp029.c
  src/inspkt_c/zzhlp030.c
  src/inspkt_c/zzhlp031.c
  src/inspkt_c/zzhlp032.c)

add_executable(inspekt ${CMAKE_BINARY_DIR}/inspekt_main.c ${CMAKE_BINARY_DIR}/inspekt.c ${INSPEKT_SRCS})
target_link_libraries(inspekt cspice csupport)

