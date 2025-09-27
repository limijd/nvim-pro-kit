docker run --rm -it -v "$HOME/git-musl-out:/out" alpine:3.22 sh -euxc '
  # 1) Toolchain + STATIC libs
  apk add --no-cache \
    build-base perl bash ca-certificates pkgconf autoconf gettext \
    curl-dev curl-static \
    openssl-dev openssl-libs-static \
    zlib-dev zlib-static \
    pcre2-dev pcre2-static \
    expat-dev expat-static
  update-ca-certificates

  # 2) Pick a Git version (change as you like)
  GIT_VER=2.51.0
  wget -q https://www.kernel.org/pub/software/scm/git/git-${GIT_VER}.tar.xz
  tar xf git-${GIT_VER}.tar.xz
  cd git-${GIT_VER}

  # 3) Prepare and force static linking
  make configure
  export PKG_CONFIG="pkg-config --static"
  export CFLAGS="-O2"
  export LDFLAGS="-static"
  # Tell Git how to link to a fully static libcurl:
  export CURL_LDFLAGS="$(pkg-config --static --libs libcurl)"

  # 4) Configure + build (trim GUI/gettext to keep it small/static)
  ./configure --prefix=/usr
  make -j"$(nproc)" \
      NO_TCLTK=YesPlease \
      NO_GETTEXT=YesPlease \
      USE_LIBPCRE=YesPlease \
      V=1

  # 5) Install into the mounted /out dir
  make DESTDIR=/out install
'

