// Minimal C ABI shim over pugixml's C++ DOM, for use from Julia via ccall. Just enough surface to
// parse a file, walk element children, read attributes, read leaf text content, and write documents
// back out.
//
// Handle model:
//   - pugishim_parse_file returns an owning pugi::xml_document* (caller must
//     call pugishim_free_doc exactly once on it).
//   - All node/attribute handles are pugixml's own internal pointers
//     (xml_node_struct*/xml_attribute_struct*), obtained via xml_node's public
//     internal_object()/xml_node(xml_node_struct*) round-trip. They are views
//     into the document's memory pool: they do NOT need to be freed, and they
//     become invalid once the owning document is freed.
//   - nullptr means "no such node/attribute" (empty/end-of-iteration/failure).

#include <pugixml.hpp>
#include <cstring>

extern "C" {

// --- Document lifecycle ------------------------------------------------

// Parse the file at `path`. Returns an opaque xml_document* handle, or
// nullptr if the file could not be parsed (bad path, malformed XML, ...).
void* pugishim_parse_file(const char* path) {
    pugi::xml_document* doc = new pugi::xml_document();
    pugi::xml_parse_result result = doc->load_file(path);
    if (!result) {
        delete doc;
        return nullptr;
    }
    return doc;
}

// Parse an in-memory buffer of `size` bytes (not necessarily null-terminated).
// For loading from an arbitrary Julia IO (read fully into a Vector{UInt8} on
// the Julia side, then pass its pointer here) rather than a file path.
// Returns an opaque xml_document* handle, or nullptr on parse failure.
void* pugishim_parse_buffer(const char* data, size_t size) {
    pugi::xml_document* doc = new pugi::xml_document();
    pugi::xml_parse_result result = doc->load_buffer(data, size);
    if (!result) {
        delete doc;
        return nullptr;
    }
    return doc;
}

// Free a document handle returned by pugishim_parse_file. Invalidates every
// node/attribute handle obtained from it.
void pugishim_free_doc(void* doc) {
    delete static_cast<pugi::xml_document*>(doc);
}

// --- Node access ---------------------------------------------------------

// The document's root element (e.g. <document> in <?xml?><document>...),
// or nullptr if the document has no root element.
void* pugishim_root(void* doc) {
    pugi::xml_node root = static_cast<pugi::xml_document*>(doc)->document_element();
    return root.internal_object();
}

// Tag/element name, e.g. "TestElement1". Owned by the document; valid until
// the document is freed. Never null (empty string if the node has no name).
const char* pugishim_node_name(void* node) {
    return pugi::xml_node(static_cast<pugi::xml_node_struct*>(node)).name();
}

// Direct text content of a node (pugixml's child_value(): the value of the
// first text/CDATA child, NOT concatenated across all descendants). Owned by
// the document; valid until the document is freed. Never null ("" if none).
const char* pugishim_node_text(void* node) {
    return pugi::xml_node(static_cast<pugi::xml_node_struct*>(node)).child_value();
}

// First ELEMENT child of `node` (skips text/comment/PI/declaration nodes),
// or nullptr if it has none.
void* pugishim_first_child_element(void* node) {
    pugi::xml_node n = pugi::xml_node(static_cast<pugi::xml_node_struct*>(node)).first_child();
    while (n && n.type() != pugi::node_element) {
        n = n.next_sibling();
    }
    return n.internal_object();
}

// Next ELEMENT sibling after `node` (skips text/comment/PI/declaration
// nodes), or nullptr if there is none.
void* pugishim_next_sibling_element(void* node) {
    pugi::xml_node n = pugi::xml_node(static_cast<pugi::xml_node_struct*>(node)).next_sibling();
    while (n && n.type() != pugi::node_element) {
        n = n.next_sibling();
    }
    return n.internal_object();
}

// 1 if `node` has at least one element child, 0 otherwise (i.e. it is a leaf).
int pugishim_has_element_children(void* node) {
    return pugishim_first_child_element(node) != nullptr ? 1 : 0;
}

// --- Attribute access ------------------------------------------------------

// First attribute of `node`, or nullptr if it has none.
void* pugishim_first_attribute(void* node) {
    pugi::xml_attribute a = pugi::xml_node(static_cast<pugi::xml_node_struct*>(node)).first_attribute();
    return a.internal_object();
}

// Next attribute after `attr`, or nullptr if there is none.
void* pugishim_next_attribute(void* attr) {
    pugi::xml_attribute a = pugi::xml_attribute(static_cast<pugi::xml_attribute_struct*>(attr)).next_attribute();
    return a.internal_object();
}

// Attribute name, e.g. "xsi:schemaLocation". Owned by the document; valid
// until the document is freed. Never null.
const char* pugishim_attribute_name(void* attr) {
    return pugi::xml_attribute(static_cast<pugi::xml_attribute_struct*>(attr)).name();
}

// Attribute value. Owned by the document; valid until the document is freed.
// Never null.
const char* pugishim_attribute_value(void* attr) {
    return pugi::xml_attribute(static_cast<pugi::xml_attribute_struct*>(attr)).value();
}

// --- Writing ---------------------------------------------------------------
//
// A freshly-created xml_document is the same C++ type pugishim_parse_file
// returns (pugixml doesn't distinguish "parsed" from "constructed" docs), so
// pugishim_free_doc frees these too.
//
// xml_document publicly inherits xml_node (xml_document : public xml_node),
// but the *handle types differ*: pugishim_new_doc returns an owning
// pugi::xml_document* (a heap object, like pugishim_parse_file's result),
// while every node handle in this shim is the lightweight internal pointer
// obtained via xml_node::internal_object(). The two are not
// reinterpret_cast-compatible, so pugishim_doc_as_node() is the bridge: it
// upcasts the xml_document& to xml_node& (slicing off just the node view)
// and returns *that* node's internal_object(), giving a normal node handle
// that pugishim_append_child_element accepts like any other -- this is how
// you attach the first/root element to an otherwise-empty document.

// Create a new, empty, writable document. Returns an owning handle; free
// with pugishim_free_doc exactly like a parsed document.
void* pugishim_new_doc() {
    return new pugi::xml_document();
}

// View a document handle (from pugishim_new_doc or pugishim_parse_file) as a
// plain node handle, so it can be passed to pugishim_append_child_element to
// attach the document's root element. Do not free this handle separately --
// it is owned by the document, same as any other node handle.
void* pugishim_doc_as_node(void* doc) {
    pugi::xml_node n = *static_cast<pugi::xml_document*>(doc); // upcast, not a new object
    return n.internal_object();
}

// Append a new child element named `name` to `node` (which may be an
// ordinary element handle, or a document viewed via pugishim_doc_as_node --
// in the latter case this creates the document's root element). Returns the
// new child's node handle, or nullptr on failure (e.g. `node` is a leaf type
// that can't take children).
void* pugishim_append_child_element(void* node, const char* name) {
    pugi::xml_node parent(static_cast<pugi::xml_node_struct*>(node));
    pugi::xml_node child = parent.append_child(name);
    return child.internal_object();
}

// Set a node's direct text content (finds-or-creates the node's pcdata
// child and sets its value, via pugixml's xml_text proxy). Returns 1 on
// success, 0 on failure (e.g. `node` is null/empty).
int pugishim_set_node_text(void* node, const char* text) {
    pugi::xml_node n(static_cast<pugi::xml_node_struct*>(node));
    return n.text().set(text) ? 1 : 0;
}

// Append one attribute (name + value) to `node`. Returns the new attribute's
// handle, or nullptr on failure. Call once per attribute (mirrors iterating
// a Dict on the Julia side).
void* pugishim_append_attribute(void* node, const char* name, const char* value) {
    pugi::xml_node n(static_cast<pugi::xml_node_struct*>(node));
    pugi::xml_attribute a = n.append_attribute(name);
    if (!a) return nullptr;
    a.set_value(value);
    return a.internal_object();
}

// Serialize `doc` to the file at `path` (default pugixml formatting: tab
// indentation, UTF-8). Returns 1 on success, 0 on failure (bad path,
// permissions, ...).
int pugishim_save_file(void* doc, const char* path) {
    return static_cast<pugi::xml_document*>(doc)->save_file(path) ? 1 : 0;
}

} // extern "C"
