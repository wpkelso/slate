<div align="center">
  <img alt="An icon consisting of a black square with a thick brown border and a white grid" src="data/icons/128.svg" />
  <h1>Slate</h1>
  <h3>The text editor that's dumb as rocks</h3>

[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](http://www.gnu.org/licenses/gpl-3.0)
[![CI](https://github.com/wpkelso/slate/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/wpkelso/slate/actions/workflows/ci.yml)

  <img src="data/screenshot-light.png" />

  <a href="https://elementary.io">
    <img src="https://ellie-commons.github.io/community-badge.svg" alt="Made for elementary OS">
  </a>
  <a href="https://appcenter.elementary.io/io.github.wpkelso.slate/">
    <img src="https://appcenter.elementary.io/badge.svg" alt="Get it on AppCenter">
  </a>
</div>

## Building

Make sure you have the following dependencies:

```bash
libgranite-7-dev
gtk-4.0
libgio-2.0
meson
valac
```

Clone the repository and run:

```bash
meson setup build --prefix=/usr
cd build
ninja
```

Then to install run:

```bash
sudo ninja install
```

To build flatpak:
```bash
flatpak-builder build io.github.wpkelso.slate.yaml --user --install --force-clean --install-deps-from=appcenter
```

