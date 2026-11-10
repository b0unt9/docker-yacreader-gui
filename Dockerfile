ARG DOCKER_IMAGE_VERSION=1.0.0

FROM ubuntu:24.04 AS builder

ARG YACREADER_VERSION

ENV DEBIAN_FRONTEND=noninteractive

RUN set -eux; \
    sed -i 's@archive.ubuntu.com@azure.archive.ubuntu.com@g' /etc/apt/sources.list.d/ubuntu.sources 2>/dev/null \
      || sed -i 's@archive.ubuntu.com@azure.archive.ubuntu.com@g' /etc/apt/sources.list 2>/dev/null || true; \
    sed -i 's@security.ubuntu.com@azure.archive.ubuntu.com@g' /etc/apt/sources.list.d/ubuntu.sources 2>/dev/null \
      || sed -i 's@security.ubuntu.com@azure.archive.ubuntu.com@g' /etc/apt/sources.list 2>/dev/null || true; \
    \
    echo 'Acquire::Retries "3";' > /etc/apt/apt.conf.d/80-retries; \
    \
    apt-get update -qq \
    && apt-get install -y -qq --no-install-recommends \
    build-essential curl ca-certificates jq xz-utils \
    qtchooser qt5-qmake qtbase5-dev qtbase5-dev-tools qttools5-dev-tools \
    qtdeclarative5-dev qtquickcontrols2-5-dev qtmultimedia5-dev libqt5svg5-dev libqt5opengl5-dev \
    libpoppler-qt5-dev libarchive-dev libunarr-dev libqt5sql5-sqlite libqt5quickwidgets5 libqt5multimedia5 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src

RUN echo "Starting build for YACReader version: $YACREADER_VERSION" \
    && curl -L "https://github.com/YACReader/yacreader/archive/refs/tags/${YACREADER_VERSION}.tar.gz" -o source.tar.gz \
    && tar -xzf source.tar.gz \
    && cd yacreader-* \
    && echo "Downloading and extracting 7zip 23.01 source for decompression support..." \
    && mkdir -p compressed_archive/lib7zip \
    && curl -L https://www.7-zip.org/a/7z2301-src.tar.xz -o 7z_src.tar.xz \
    && tar -xf 7z_src.tar.xz -C compressed_archive/lib7zip/ \
    && echo "Compiling YACReader (Warnings suppressed, 7zip enabled)..." \
    && qmake YACReader.pro CONFIG+=warn_off CONFIG+=7zip \
    && make -j$(nproc) -s \
    && mkdir -p /build_out \
    && cp YACReaderLibrary/YACReaderLibrary /build_out/ \
    && cp YACReader/YACReader /build_out/ \
    && cp -r release /build_out/release


FROM jlesage/baseimage-gui:ubuntu-24.04-v4.11.3 AS runtime

ARG YACREADER_VERSION
ARG DOCKER_IMAGE_VERSION

ENV DEBIAN_FRONTEND=noninteractive

ENV HOME="/config"
ENV XDG_CONFIG_HOME="/config/.config"
ENV XDG_DATA_HOME="/config/.local/share"
ENV XDG_CACHE_HOME="/config/.cache"

ENV LIBGL_ALWAYS_SOFTWARE=1
ENV QT_X11_NO_MITSHM=1
ENV QT_XCB_FORCE_SOFTWARE_OPENGL=1

WORKDIR /config

RUN set -eux; \
    sed -i 's@archive.ubuntu.com@azure.archive.ubuntu.com@g' /etc/apt/sources.list.d/ubuntu.sources 2>/dev/null \
      || sed -i 's@archive.ubuntu.com@azure.archive.ubuntu.com@g' /etc/apt/sources.list 2>/dev/null || true; \
    sed -i 's@security.ubuntu.com@azure.archive.ubuntu.com@g' /etc/apt/sources.list.d/ubuntu.sources 2>/dev/null \
      || sed -i 's@security.ubuntu.com@azure.archive.ubuntu.com@g' /etc/apt/sources.list 2>/dev/null || true; \
    \
    echo 'Acquire::Retries "3";' > /etc/apt/apt.conf.d/80-retries; \
    \
    apt-get update -qq \
    && apt-get install -y -qq --no-install-recommends \
    7zip libarchive13t64 libunarr1 libpoppler-qt5-1t64 \
    libqt5core5a libqt5gui5 libqt5widgets5 libqt5network5 libqt5opengl5 libqt5multimedia5 libqt5svg5 libqt5sql5-sqlite qt5-image-formats-plugins \
    libqt5qml5 libqt5quick5 libqt5quickwidgets5 qml-module-qtquick2 qml-module-qtquick-controls qml-module-qtquick-controls2 qml-module-qtquick-layouts qml-module-qtquick-window2 qml-module-qtquick-dialogs \
    fontconfig fonts-noto fonts-noto-cjk \
    && fc-cache -f

COPY --from=builder /build_out/YACReader /usr/bin/YACReader
COPY --from=builder /build_out/YACReaderLibrary /usr/bin/YACReaderLibrary
COPY --from=builder /build_out/release /usr/share/yacreader

COPY --chmod=755 rootfs/ /

RUN --mount=type=bind,source=icon.png,target=/icon.png \
    install_app_icon.sh /icon.png \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN \
    set-cont-env APP_NAME "YACReader Library" && \
    set-cont-env APP_VERSION "$YACREADER_VERSION" && \
    set-cont-env DOCKER_IMAGE_VERSION "$DOCKER_IMAGE_VERSION" && \
    true

LABEL \
    org.label-schema.name="YACReader" \
    org.label-schema.description="Docker container for YACReader" \
    org.label-schema.version="${DOCKER_IMAGE_VERSION:-unknown}" \
    org.label-schema.vcs-url="https://github.com/b0unt9/docker-yacreader-gui" \
    org.label-schema.schema-version="1.0"

VOLUME ["/config"]