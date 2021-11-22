project('NOVAS', 'c')
cc = meson.get_compiler('c')
deps = cc.find_library('m', required : true)
sources = ['solsys1.c', 'readeph0.c', 'eph_manager.c', 'nutation.c', 'novascon.c', 'novas.c']
headers = ['solarsystem.h','eph_manager.h', 'nutation.h', 'novascon.h', 'novas.h']
shared_library('novas', 
               sources,
               dependencies : deps,
               version : '3.1',
               install : true)
install_headers(headers)
