project('NOVAS', 'c')
cc = meson.get_compiler('c')
m_dep = cc.find_library('m', required : true)
sources = ['solsys1.c', 'readeph0.c', 'eph_manager.c', 'nutation.c', 'novascon.c', 'novas.c']
shared_library('novas',
               sources,
               version : '3.1',
               install : true)
