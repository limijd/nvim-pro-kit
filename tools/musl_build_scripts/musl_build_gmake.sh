docker run --rm -it -v "$HOME/git-musl-out:/out" alpine:3.22 sh -euxc '
  apk add --no-cache build-base bash ca-certificates wget
  update-ca-certificates

  MAKE_VER=4.4.1
  wget -q https://ftp.gnu.org/gnu/make/make-${MAKE_VER}.tar.gz
  tar xf make-${MAKE_VER}.tar.gz
  cd make-${MAKE_VER}

  # Fully static on musl, and disable NLS to avoid gettext
  export CFLAGS="-O2"
  export LDFLAGS="-static"
  ./configure --prefix=/usr --disable-nls

  # Avoid rebuilding docs if texinfo isn’t present
  make -j"$(nproc)" MAKEINFO=true
  make DESTDIR=/out install

  strip /out/usr/bin/make
'

