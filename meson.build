project('gnotebook', 'vala', 'c', version: '0.1', license: 'GPL-3.0-or-later')

gnome = import('gnome')

deps = [
  dependency('glib-2.0', version: '>= 2.52.0'),
  dependency('gobject-2.0', version: '>= 2.52.0'),
  dependency('gee-0.8', version: '>= 0.8.0'),
  dependency('gtk4')
]

res = gnome.compile_resources('gnotebook-resources', 'gnotebook.gresource.xml',
                              c_name: 'gnotebook')

src = [
  'main.vala',
  'page.vala',
  'rename.vala',
  'window.vala',
  res
]

executable('gnotebook', src, dependencies: deps, install: true)
