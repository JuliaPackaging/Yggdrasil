"""
Patch CMakeLists.txt to make parsec-ptgpp import optional when cross-compiling.
When building only the C runtime library, parsec-ptgpp is not required.
"""
import sys, os

cmake_path = os.path.join(os.environ.get("WORKSPACE", ""), "srcdir", "parsec", "CMakeLists.txt")
if not os.path.exists(cmake_path):
    cmake_path = "CMakeLists.txt"

with open(cmake_path) as f:
    content = f.read()

# The marker that starts the cross-compilation block we need to modify
marker_start = '  set(IMPORT_EXECUTABLES "IMPORTFILE-NOTFOUND" CACHE FILEPATH "Point it to the export file from a native build")\n  message(STATUS "Prepare cross-compiling using ${IMPORT_EXECUTABLES}")\n  include(${IMPORT_EXECUTABLES})'
marker_end = '  add_test(NAME native-test COMMAND ${CMAKE_COMMAND} --build ${PROJECT_BINARY_DIR} --target native-test)'
else_marker = 'else()\n  set(PARSEC_PTGPP_EXECUTABLE parsec-ptgpp)\nendif(CMAKE_CROSSCOMPILING)'

if marker_start not in content:
    print("ERROR: Could not find cross-compilation block to patch!", file=sys.stderr)
    sys.exit(1)

# Find the range to replace: from marker_start through marker_end
start_idx = content.index(marker_start)
end_idx = content.index(marker_end, start_idx) + len(marker_end)

old_block = content[start_idx:end_idx]

new_block = (
    '  # Import the EXPORT file from external native ptgpp, if provided.\n'
    '  # When building only the C runtime library, parsec-ptgpp is not required.\n'
    '  set(IMPORT_EXECUTABLES "IMPORTFILE-NOTFOUND" CACHE FILEPATH "Point it to the export file from a native build")\n'
    '  if(EXISTS "${IMPORT_EXECUTABLES}")\n'
    '    message(STATUS "Prepare cross-compiling using ${IMPORT_EXECUTABLES}")\n'
    '    include(${IMPORT_EXECUTABLES})\n'
    '    set_target_properties(parsec-ptgpp PROPERTIES IMPORTED_GLOBAL ON)\n'
    '    get_target_property(PARSEC_PTGPP_EXECUTABLE parsec-ptgpp LOCATION)\n'
    '  else()\n'
    '    message(STATUS "No native parsec-ptgpp provided; PTG compiler interface will be unavailable")\n'
    '  endif()'
)

content = content[:start_idx] + new_block + content[end_idx:]

with open(cmake_path, "w") as f:
    f.write(content)

print("CMakeLists.txt patched successfully: ptgpp import is now optional.")
