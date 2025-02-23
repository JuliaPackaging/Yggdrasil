#include "value_wrap.h"
#include <string>

jinja2cpp_value_t* jinja2cpp_value_create_empty() { return new jinja2cpp_value_t(); }
jinja2cpp_value_t* jinja2cpp_value_create_string(const char* val) { return new jinja2cpp_value_t(val ? val : ""); }
jinja2cpp_value_t* jinja2cpp_value_create_int(int val) {return new jinja2cpp_value_t(val); }
jinja2cpp_value_t* jinja2cpp_value_create_double(double val) {return new jinja2cpp_value_t(val); }
jinja2cpp_value_t* jinja2cpp_value_create_list(const jinja2cpp_values_list_t* list) {return new jinja2cpp_value_t(*list);}
jinja2cpp_value_t* jinja2cpp_value_create_map(const jinja2cpp_values_map_t* map) { return new jinja2cpp_value_t(*map); }

void jinja2cpp_value_destroy(jinja2cpp_value_t* value) { delete static_cast<jinja2cpp_value_t*>(value); }

bool jinja2cpp_value_is_string(const jinja2cpp_value_t* value) {
    if (!value) return false;
    return static_cast<const jinja2cpp_value_t*>(value)->isString();
}

bool jinja2cpp_value_is_list(const jinja2cpp_value_t* value) {
    if (!value) return false;
    return static_cast<const jinja2cpp_value_t*>(value)->isList();
}

bool jinja2cpp_value_is_map(const jinja2cpp_value_t* value) {
    if (!value) return false;
    return static_cast<const jinja2cpp_value_t*>(value)->isMap();
}

bool jinja2cpp_value_is_empty(const jinja2cpp_value_t* value) {
    if (!value) return false;
    return static_cast<const jinja2cpp_value_t*>(value)->isEmpty();
}

const char* jinja2cpp_value_as_string(const jinja2cpp_value_t* value) {
    if (!value || !value->isString()) return nullptr;
    return value->asString().c_str();
}

jinja2cpp_values_list_t* jinja2cpp_value_as_list(jinja2cpp_value_t* value) {
    if (!value || !static_cast<const jinja2cpp_value_t*>(value)->isList()) return nullptr;
    return &static_cast<jinja2cpp_value_t*>(value)->asList();
}

jinja2cpp_values_map_t* jinja2cpp_value_as_map(jinja2cpp_value_t* value) {
    if (!value || !static_cast<const jinja2cpp_value_t*>(value)->isMap()) return nullptr;
    return &static_cast<jinja2cpp_value_t*>(value)->asMap();
}

jinja2cpp_values_map_t* jinja2cpp_values_map_create() { return new jinja2cpp_values_map_t(); }
void jinja2cpp_values_map_destroy(jinja2cpp_values_map_t* map) { delete map; }

void jinja2cpp_values_map_set(jinja2cpp_values_map_t* map, const char* key, jinja2cpp_value_t* value) {
    if (!map || !key || !value) return;
    (*map)[key] = *value;
}

jinja2cpp_value_t* jinja2cpp_values_map_get(const jinja2cpp_values_map_t* map, const char* key) {
    if (!map || !key) return nullptr;
    
    auto it = map->find(key);
    if (it == map->end()) return nullptr;

    return new jinja2cpp_value_t(it->second);
}

size_t jinja2cpp_values_map_size(const jinja2cpp_values_map_t* map) {
    return map ? map->size() : 0;
}

jinja2cpp_values_list_t* jinja2cpp_values_list_create() { return new jinja2cpp_values_list_t(); }
void jinja2cpp_values_list_destroy(jinja2cpp_values_list_t* list) { delete list; }

void jinja2cpp_values_list_push(jinja2cpp_values_list_t* list, const jinja2cpp_value_t* value) {
    if (!list || !value) return;
    list->push_back(*value);
}

jinja2cpp_value_t* jinja2cpp_values_list_get(const jinja2cpp_values_list_t* list, size_t index) {
    if (!list || index >= list->size()) return nullptr;
    return new jinja2cpp_value_t((*list)[index]);
}

size_t jinja2cpp_values_list_size(const jinja2cpp_values_list_t* list) {
    return list ? list->size() : 0;
}