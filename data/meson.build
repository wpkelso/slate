icon_sizes = ['16', '24', '32', '48', '64', '128']

foreach i : icon_sizes
    install_data(
        join_paths('icons', i + '.svg'),
        install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i, 'apps'),
        rename: meson.project_name() + '.svg'
    )
    install_data(
        join_paths('icons', i + '.svg'),
        install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i + '@2', 'apps'),
        rename: meson.project_name() + '.svg'
    )
endforeach

install_data(
    'io.github.wpkelso.slate.desktop.in',
    rename : 'io.github.wpkelso.slate.desktop',
    install_dir : join_paths(get_option('datadir'), 'applications'),
)

install_data(
    'slate.metainfo.xml.in',
    rename: meson.project_name() + '.metainfo.xml',
    install_dir: join_paths(get_option('datadir'), 'metainfo'),
)
