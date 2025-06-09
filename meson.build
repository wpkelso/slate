project(
    'io.github.wpkelso.slate',
    ['vala', 'c'],
    version: '0.0.1',
    license: 'GPL-3.0'
)

# these are Meson Modules
gnome = import('gnome')
i18n = import('i18n')

config_data = configuration_data()
config_data.set_quoted('LOCALEDIR', get_option('prefix') / get_option('localedir'))
config_data.set_quoted('GETTEXT_PACKAGE', meson.project_name())
config_file = configure_file(
    input: 'src/Config.vala.in',
    output: '@BASENAME@',
    configuration: config_data
)

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
    config_file,
    sources,
    dependencies: deps,
    install: true

)

subdir('data')
subdir('po')
