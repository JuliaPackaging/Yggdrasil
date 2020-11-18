project('llvm', ['cpp'])

cpp = meson.get_compiler('cpp')

_deps = []
_search = '/workspace/destdir/lib'
foreach d : ['libLLVM']
  _deps += cpp.find_library(d, dirs : _search)
endforeach

dep_llvm = declare_dependency(
  include_directories : include_directories('/workspace/destdir/include'),
  dependencies : _deps,
  version : '9.0.1',
  static: false,
)

has_rtti = false
irbuilder_h = files('/workspace/destdir/include/llvm/IR/IRBuilder.h')