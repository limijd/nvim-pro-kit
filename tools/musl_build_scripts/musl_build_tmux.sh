mkdir -p ~/tmux-musl-out

docker run --rm -it -v "$HOME/tmux-musl-out:/out" alpine:3.22 sh -euxc '
  # 1) 构建工具 + 静态依赖
  apk add --no-cache \
    build-base bash ca-certificates pkgconf autoconf automake libtool wget bison flex \
    libevent-dev libevent-static \
    ncurses-dev ncurses-static
  update-ca-certificates

  # 2) 下载 tmux 源码（如需改版本，改 TMUX_VER）
  TMUX_VER=3.5a
  wget -q https://github.com/tmux/tmux/releases/download/${TMUX_VER}/tmux-${TMUX_VER}.tar.gz
  tar xf tmux-${TMUX_VER}.tar.gz
  cd tmux-${TMUX_VER}

  # 3) 强制静态链接（让 pkg-config 给出 .a 的链接参数）
  export PKG_CONFIG="pkg-config --static"
  export CFLAGS="-O2"
  export LDFLAGS="-static"
  # 让 configure/编译都能拿到头文件与库参数（尤其是 ncursesw 与 libevent）
  export CPPFLAGS="$(pkg-config --cflags ncursesw libevent)"
  export LIBS="$(pkg-config --libs ncursesw libevent)"

  # 4) 配置 + 编译 + 安装到挂载目录 /out
  ./configure --prefix=/usr --enable-static
  make -j"$(nproc)" V=1
  make DESTDIR=/out install

  # 5) 精简体积（可选）
  strip /out/usr/bin/tmux || true
'

