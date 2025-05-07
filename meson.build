project(
    'io.github.wpkelso.slate',
    ['vala', 'c'],
    version: '0.0.1',
    license: 'GPL-3.0'
)

# these are Meson Modules
gnome = import('gnome')
i18n = import('i18n')

add_global_arguments(
    '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
    language:'c'
)

add_project_arguments(
    language: 'vala'
)

sources = files()

subdir('src')

deps = [
    dependency('granite-7'),
    dependency('gtk4'),
    dependency('gio-2.0'),
]

executable(
    meson.project_name(),
    sources,
    dependencies: deps,
    install: true

)

subdir('data')
