configure_file(src/spkdif_c/main.x ${CMAKE_BINARY_DIR}/spkdiff_main.c)
configure_file(src/spkdif_c/spkdiff.pgm ${CMAKE_BINARY_DIR}/spkdiff.c)

set(SPKDIFF_SRCS
  src/spkdif_c/chwcml.c
  src/spkdif_c/dr2str.c
  src/spkdif_c/getsta.c
  src/spkdif_c/ldklst.c
  src/spkdif_c/stdiff.c)

add_executable(spkdiff ${CMAKE_BINARY_DIR}/spkdiff_main.c ${CMAKE_BINARY_DIR}/spkdiff.c ${SPKDIFF_SRCS})
target_link_libraries(spkdiff cspice csupport)

