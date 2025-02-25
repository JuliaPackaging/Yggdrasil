#include "filesystem_handler_wrap.h"

jinja2cpp_memory_file_system_t* jinja2cpp_memory_file_system_create() {
    return new jinja2cpp_memory_file_system_t();
}

void jinja2cpp_memory_file_system_destroy(jinja2cpp_memory_file_system_t* fs) {
    delete fs;
}

void jinja2cpp_memory_file_system_add_file(jinja2cpp_memory_file_system_t* fs, const char* fileName, const char* fileContent) {
    if (!fs || !fileName || !fileContent) return;
    fs->AddFile(fileName, fileContent);
}