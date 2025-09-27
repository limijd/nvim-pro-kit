mkdir -p ~/cscope-musl-out

docker run --rm -it -v "$HOME/cscope-musl-out:/out" alpine:3.22 sh -euxc '
  # 1) 构建工具 & 依赖（yacc/lex 用 bison/flex；ncurses 静态库）
  apk add --no-cache \
    build-base bash ca-certificates pkgconf wget \
    bison flex \
    ncurses-dev ncurses-static
  update-ca-certificates

  # 2) 下载并解压 cscope 源码（15.9）
  CSCOPE_VER=15.9
  wget -q "https://sourceforge.net/projects/cscope/files/cscope/v${CSCOPE_VER}/cscope-${CSCOPE_VER}.tar.gz/download" -O cscope-${CSCOPE_VER}.tar.gz
  tar xf cscope-${CSCOPE_VER}.tar.gz
  cd cscope-${CSCOPE_VER}

  # 3) 设置环境：强制静态链接到 ncursesw，并提供 yacc/lex
  export PKG_CONFIG="pkg-config --static"
  export CFLAGS="-O2"
  export LDFLAGS="-static"
  export CPPFLAGS="$(pkg-config --cflags ncursesw)"
  export LIBS="$(pkg-config --libs ncursesw)"
  export YACC="bison -y"
  export LEX="flex"

  # 4) 配置、编译、安装到挂载目录 /out
  ./configure --prefix=/usr --with-ncurses
  make -j"$(nproc)" V=1
  make DESTDIR=/out install

  # 5) 精简体积（可选）
  strip /out/usr/bin/cscope || true
'

