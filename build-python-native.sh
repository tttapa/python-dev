#!/usr/bin/env bash

set -ex

PYTHON_VERSION=${1}
python="Python-${PYTHON_VERSION}"
version_num=$(echo "$PYTHON_VERSION" | grep -Po '^\d+\.\d+\.\d+')
version_suf="${PYTHON_VERSION#"$version_num"}"
staging="native-python-${PYTHON_VERSION}"
staging_dir="$PWD"

# Build Python
wget "https://www.python.org/ftp/python/${version_num}/$python.tgz" -O- | tar xz
pushd "$python"
./configure \
    --prefix="/usr/local" \
    --enable-ipv6 \
    --enable-shared \
    --disable-test-modules \
    'LDFLAGS=-Wl,-rpath,\$$ORIGIN/../lib'
make -j$(nproc)
mkdir -p "$staging_dir/$staging"
make altinstall DESTDIR="$staging_dir/$staging"
popd

# Package Python
tar czf native-python-${PYTHON_VERSION}.tar.gz -C "$staging_dir" "$staging"
