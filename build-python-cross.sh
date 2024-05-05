#!/usr/bin/env bash

set -ex
SCRIPT_DIR="$(realpath "$( dirname "${BASH_SOURCE[0]}" )" )"

PYTHON_VERSION=${1}
HOST_TRIPLE=${2}

python_url="https://www.python.org/ftp/python"
python="Python-$PYTHON_VERSION"
version_num=$(echo "$PYTHON_VERSION" | grep -Po '^\d+\.\d+\.\d+')
version_majmin=$(echo "$PYTHON_VERSION" | grep -Po '^\d+\.\d+')
version_suf="${PYTHON_VERSION#"$version_num"}"
staging="$HOST_TRIPLE-python-$PYTHON_VERSION"
staging_dir="$PWD"

zlib_url="https://github.com/madler/zlib/releases/download/"
zlib_version="1.3"
zlib="zlib-$zlib_version"
zlib_staging_dir="$staging_dir/$zlib"

mkdir -p build
pushd build

# Disable pkg-config
mkdir -p pkg-config-bin
ln -sf $(which false) "pkg-config-bin/$HOST_TRIPLE-pkg-config"
export PATH="$PWD/pkg-config-bin:$PATH"
which $HOST_TRIPLE-pkg-config

# Build zlib
wget "$zlib_url/v$zlib_version/$zlib.tar.gz" -O- | tar xz
pushd "$zlib"
CHOST="$HOST_TRIPLE" \
./configure \
    --prefix="/usr/local"
make
make install DESTDIR="$zlib_staging_dir"
popd

# Build Python
wget "$python_url/$version_num/$python.tgz" -O- | tar xz
pushd "$python"
{ [ ! -e setup.py ] || \
    sed -i 's@# Debian/Ubuntu multiarch support.@return@g' setup.py; }
sed -i 's@libainstall:\( \|	\)all@libainstall:@g' Makefile.pre.in
sed -i 's@bininstall:\( \|	\)commoninstall@bininstall:@g' Makefile.pre.in
CONFIG_SITE="$SCRIPT_DIR/config.site" \
ZLIB_CFLAGS="-I $zlib_staging_dir/usr/local/include" \
ZLIB_LIBS="-L $zlib_staging_dir/usr/local/lib -lz" \
LIBUUID_CFLAGS="" LIBUUID_LIBS="" \
LIBFFI_CFLAGS="" LIBFFI_LIBS="" \
LIBNSL_CFLAGS="" LIBNSL_LIBS="" \
LIBSQLITE3_CFLAGS="" LIBSQLITE3_LIBS="" \
TCLTK_CFLAGS="" TCLTK_LIBS="" \
X11_CFLAGS="" X11_LIBS="" \
GDBM_CFLAGS="" GDBM_LIBS="" \
BZIP2_CFLAGS="" BZIP2_LIBS="" \
LIBLZMA_CFLAGS="" LIBLZMA_LIBS="" \
LIBCRYPT_CFLAGS="" LIBCRYPT_LIBS="" \
LIBREADLINE_CFLAGS="" LIBREADLINE_LIBS="" \
LIBEDIT_CFLAGS="" LIBEDIT_LIBS="" \
CURSES_CFLAGS="" CURSES_LIBS="" \
PANEL_CFLAGS="" PANEL_LIBS="" \
LIBB2_CFLAGS="" LIBB2_LIBS="" \
./configure \
    --enable-ipv6 \
    --enable-shared \
    --disable-test-modules \
    --build="x86_64-linux-gnu" \
    --host="$HOST_TRIPLE" \
    --prefix="/usr/local" \
    --with-pkg-config=no \
    --with-openssl=no-i-do-not-want-openssl \
    --without-readline \
    --without-doc-strings \
    --with-build-python="$(which python$version_majmin)" \
    'LDFLAGS=-Wl,-rpath,\$$ORIGIN/../lib'
make python python-config -j$(nproc)
mkdir -p "$staging_dir/$staging"
make altbininstall inclinstall libainstall bininstall DESTDIR="$staging_dir/$staging"
popd
popd

# Package Python
tar czf $HOST_TRIPLE-python-$PYTHON_VERSION.tar.gz -C "$staging_dir" "$staging"

# Note about --with-openssl=no-i-do-not-want-openssl:
# The configure script does not accept the --without-openssl or
# --with-openssl=no flags. And by default, it will try to look in /usr/include
# for ssl.h, even when cross-compiling! We absolutely do not want to add the
# /usr/include folder of the build system to the include path when
# cross-compiling, so we set --with-openssl to a nonexistent folder to avoid
# this invalid behavior.
