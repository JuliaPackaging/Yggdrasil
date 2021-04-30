configure_file(src/frmdif_c/main.x ${CMAKE_BINARY_DIR}/frmdiff_main.c)
configure_file(src/frmdif_c/frmdiff.pgm ${CMAKE_BINARY_DIR}/frmdiff.c)

set(FRMDIFF_SRCS
  src/frmdif_c/chwcml.c
  src/frmdif_c/ckcovr.c
  src/frmdif_c/dpstrp.c
  src/frmdif_c/dr2str.c
  src/frmdif_c/et2str.c
  src/frmdif_c/getqav.c
  src/frmdif_c/ldklst.c
  src/frmdif_c/rtdiff.c
  src/frmdif_c/sc01s2d.c)

add_executable(frmdiff ${CMAKE_BINARY_DIR}/frmdiff_main.c ${CMAKE_BINARY_DIR}/frmdiff.c ${FRMDIFF_SRCS})
target_link_libraries(frmdiff cspice csupport)

