#ifndef VALUE_WRAP_H
#define VALUE_WRAP_H

#ifdef __cplusplus
#include <jinja2cpp/value.h>
#include <stddef.h>
#include <stdbool.h>
using jinja2cpp_value_t = jinja2::Value;
using jinja2cpp_values_list_t = jinja2::ValuesList;
using jinja2cpp_values_map_t = jinja2::ValuesMap;

extern "C" {
#endif

jinja2cpp_value_t* jinja2cpp_value_create_empty();
jinja2cpp_value_t* jinja2cpp_value_create_string(const char* val);
jinja2cpp_value_t* jinja2cpp_value_create_int(int val);
jinja2cpp_value_t* jinja2cpp_value_create_double(double val);
jinja2cpp_value_t* jinja2cpp_value_create_list(const jinja2cpp_values_list_t* list);
jinja2cpp_value_t* jinja2cpp_value_create_map(const jinja2cpp_values_map_t* map);

void jinja2cpp_value_destroy(jinja2cpp_value_t* value);

bool jinja2cpp_value_is_string(const jinja2cpp_value_t* value);
bool jinja2cpp_value_is_list(const jinja2cpp_value_t* value);
bool jinja2cpp_value_is_map(const jinja2cpp_value_t* value);
bool jinja2cpp_value_is_empty(const jinja2cpp_value_t* value);

const char* jinja2cpp_value_as_string(const jinja2cpp_value_t* value);
jinja2cpp_values_list_t* jinja2cpp_value_as_list(jinja2cpp_value_t* value);
jinja2cpp_values_map_t* jinja2cpp_value_as_map(jinja2cpp_value_t* value);

jinja2cpp_values_map_t* jinja2cpp_values_map_create();
void jinja2cpp_values_map_destroy(jinja2cpp_values_map_t* map);
void jinja2cpp_values_map_set(jinja2cpp_values_map_t* map, const char* key, jinja2cpp_value_t* value);
jinja2cpp_value_t* jinja2cpp_values_map_get(const jinja2cpp_values_map_t* map, const char* key);
size_t jinja2cpp_values_map_size(const jinja2cpp_values_map_t* map);

jinja2cpp_values_list_t* jinja2cpp_values_list_create();
void jinja2cpp_values_list_destroy(jinja2cpp_values_list_t* list);
void jinja2cpp_values_list_push(jinja2cpp_values_list_t* list, const jinja2cpp_value_t* value);
jinja2cpp_value_t* jinja2cpp_values_list_get(const jinja2cpp_values_list_t* list, size_t index);
size_t jinja2cpp_values_list_size(const jinja2cpp_values_list_t* list);

#ifdef __cplusplus
}
#endif

#endif // VALUE_WRAP_H