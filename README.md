# python-dev

Pre-compiled CPython and PyPy libraries for common Linux architectures.

**Python versions**: `3.7.17`, `3.8.20`, `3.9.23`, `3.10.18`, `3.11.13`, `3.12.11`, `3.13.5`, `3.14.0b4`  
**PyPy versions**: `3.7-v7.3.9`, `3.8-v7.3.11`, `3.9-v7.3.16`, `3.10-v7.3.19`, `3.11-v7.3.20`  
**Platforms**: `x86_64-centos7-linux-gnu`, `x86_64-bionic-linux-gnu`, `armv6-rpi-linux-gnueabihf`, `armv7-neon-linux-gnueabihf`, `armv8-rpi3-linux-gnueabihf`, `aarch64-rpi3-linux-gnu`

For more details about these platform triplets, see [tttapa/toolchains](https://github.com/tttapa/toolchains).

## Purpose

These packages can be used to (cross-)compile Python extension modules or
binaries embedding the Python interpreter.

## Download

The ready-to-use tarballs can be downloaded from the [Releases page](https://github.com/tttapa/python-dev/releases).

- `python-dev-{version}-{triplet}.tar.gz`: One single Python version for one specific platform.
- `python-dev-{triplet}.tar.xz`: All available Python versions for one specific platform.
- `python-dev-{triplet}-with-toolchain.tar.xz`: All available Python versions for one specific platform, including a GCC 13.2 cross-compilation toolchain.
