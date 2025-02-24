#ifndef FILE_SYSTEM_WRAP_H
#define FILE_SYSTEM_WRAP_H

#ifdef __cplusplus
#include <jinja2cpp/filesystem_handler.h>
#include <stddef.h>

using jinja2cpp_memory_file_system_t = jinja2::MemoryFileSystem;

extern "C" {
#endif

jinja2cpp_memory_file_system_t* jinja2cpp_memory_file_system_create();

void jinja2cpp_memory_file_system_destroy(jinja2cpp_memory_file_system_t* fs);

void jinja2cpp_memory_file_system_add_file(jinja2cpp_memory_file_system_t* fs, const char* fileName, const char* fileContent);

#ifdef __cplusplus
}
#endif

#endif // FILE_SYSTEM_WRAP_H