# dmc-gestures Documentation

New here? The [Quick Start](../README.md#quick-start) makes a square you drag and double-tap in about 10 minutes.

## Start

- [Quick Start](../README.md#quick-start): copy the library in, a square with a pan and a double tap

## Use

- [API reference](api.md): the four gestures and their settings, the gesture event, several gestures on one object, delegates, configuration, known issues
- [Examples](../examples/): each gesture on its own, several gestures on one object, a memory test

## Contribute

- [Development](development.md): which files are generated, building, testing, possible future changes
- [Issues](https://github.com/dmccuskey/dmc-gestures/issues)

## Project Structure

```text
README.md                       landing page and Quick Start
LICENSE
docs/                           this documentation
└── images/                     screenshots for the README
dmc_corona/                     what apps copy
├── dmc_gestures.lua            the module: the new*Gesture() constructors (source)
├── dmc_gestures/               the gesture classes and the gesture manager (source)
│   └── core/                   base classes: Gesture, Continuous
└── ...                         the libraries it uses (generated copies)
dmc_corona_boot.lua             loader, from dmc-corona-boot (generated copy)
dmc_corona.cfg                  library configuration
examples/                       sample apps, each with its own generated dmc_corona/
└── screenshots/                one per app, for examples/README.md
Snakefile                       build rules for the generated copies
```
