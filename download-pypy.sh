#!/usr/bin/env bash

set -ex

PYTHON_VERSION=${1:-3.10-v7.3.16}
HOST_TRIPLE=${2:-x86_64-bionic-linux-gnu}

pypy_url="https://downloads.python.org/pypy"
version_majmin=${PYTHON_VERSION%%-v*}
pypy_version=${PYTHON_VERSION#*-v}
pypy_version_majmin=${pypy_version%.*}
staging="pypy$PYTHON_VERSION"
staging_short="pypy$version_majmin-v$pypy_version_majmin"
staging_dir="$PWD"

case $HOST_TRIPLE in
    x86_64-*) arch_suffix="linux64";;
    aarch64-*) arch_suffix="aarch64";;
    *) echo "Architecture not supported. Skipping PyPy installation."; exit 0;;
esac

# Download
pypy="pypy$version_majmin-v$pypy_version-$arch_suffix"
mkdir -p "$staging_dir/$staging/usr/local"
wget "$pypy_url/$pypy.tar.bz2" -O- | tar xj -C "$staging_dir/$staging/usr/local" --strip-components=1
# Remove parts that are unnecessary for development
rm -rf \
    "$staging_dir/$staging/usr/local/bin"/{pypy*,python*,*.debug} \
    "$staging_dir/$staging/usr/local/lib"/{tcl*,tk*,libgdbm.so*,liblzma.so*,libpanelw.so*,libsqlite3.so*,libtcl*.so*,libtk*.so*,pypy*}
ln -sf "$staging" "$staging_dir/$staging_short"

# Package PyPy
# tar czf pypy-dev-$PYTHON_VERSION-$HOST_TRIPLE.tar.gz -C "$staging_dir" "$staging"
