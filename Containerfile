ARG RTORRENT_VERSION=0.16.6
ARG LIBTORRENT_VERSION=${RTORRENT_VERSION}
ARG ALPINE_VERSION=3.23

FROM alpine:${ALPINE_VERSION} AS build

ARG RTORRENT_VERSION
ARG LIBTORRENT_VERSION

WORKDIR /build

RUN apk add curl && \
    curl -Lo libtorrent.tar.gz https://github.com/rakshasa/libtorrent/archive/refs/tags/v${LIBTORRENT_VERSION}.tar.gz && \
    curl -Lo rtorrent.tar.gz https://github.com/rakshasa/rtorrent/archive/refs/tags/v${RTORRENT_VERSION}.tar.gz && \
    tar xf libtorrent.tar.gz && rm libtorrent.tar.gz && \
    tar xf rtorrent.tar.gz && rm rtorrent.tar.gz && \
    mkdir /build/output

RUN apk add \
    autoconf \
    automake \
    build-base \
    bash \
    curl-dev \
    libtool \
    ncurses-dev

RUN cd libtorrent-${LIBTORRENT_VERSION} && \
    autoreconf -ivf && \
    bash ./configure --prefix=/usr && \
    make -j $(nproc) && \
    make install DESTDIR=/build/output

RUN cd rtorrent-${RTORRENT_VERSION} && \
    export PKG_CONFIG_PATH=/build/output/usr/lib/pkgconfig && \
    export CPPFLAGS="-I/build/output/usr/include" && \
    export LDFLAGS="-L/build/output/usr/lib" && \
    autoreconf -ivf && \
    bash ./configure --prefix=/usr && \
    make -j $(nproc) && \
    make install DESTDIR=/build/output && \
    unset PKG_CONFIG_PATH CPPFLAGS LDFLAGS

FROM alpine:${ALPINE_VERSION}

RUN apk add --no-cache curl ncurses libstdc++

COPY --from=build /build/output/ /

ENTRYPOINT ["/usr/bin/rtorrent"]
