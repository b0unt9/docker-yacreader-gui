FROM ubuntu:26.04 AS builder

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
    build-essential cmake git pkg-config qt6-base-dev qt6-base-private-dev \
    qt6-declarative-dev qt6-multimedia-dev qt6-svg-dev qt6-tools-dev qt6-l10n-tools \
    qt6-shadertools-dev libqt6opengl6-dev libqt6core5compat6-dev libqt6sql6-sqlite \
    qt6-speech-dev libpoppler-qt6-dev libarchive-dev curl ca-certificates xz-utils \
    qml6-module-qtqml qml6-module-qtqml-workerscript qml6-module-qtquick \
    qml6-module-qtquick-controls qml6-module-qtquick-layouts \
    qml6-module-qtquick-dialogs qml6-module-qttexttospeech \
    qml6-module-qtquick-effects qml6-module-qtquick-shapes \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src

RUN echo "Starting build for YACReader version: ${YACREADER_VERSION}" && \
    curl -L "https://github.com/YACReader/yacreader/archive/refs/tags/${YACREADER_VERSION}.tar.gz" -o source.tar.gz && \
    tar -xzf source.tar.gz && \
    cd yacreader-* && \
    echo "Compiling YACReader" && \
    cmake -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -DDECOMPRESSION_BACKEND=7zip && \
    cmake --build build --parallel $(nproc) && \
    DESTDIR=/build_out cmake --install build

FROM jlesage/baseimage-gui:ubuntu-26.04-v4 AS runtime

ARG YACREADER_VERSION

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
    mkdir -p /config/log && apt-get update -qq \
    && apt-get install -y -qq \
    fontconfig fonts-noto fonts-noto-cjk \
    7zip 7zip-standalone libarchive13t64 \
    libqt6core6 libqt6gui6 libqt6network6 libqt6widgets6 libqt6sql6-sqlite libpoppler-qt6-3t64 \
    libqt6multimedia6 libqt6svg6 libqt6svgwidgets6 libqt6opengl6 libqt6openglwidgets6 libqt6core5compat6 libqt6shadertools6 libqt6texttospeech6 \
    qt6-gtk-platformtheme qt6-image-formats-plugins qt6-qpa-plugins \
    libqt6qml6 libqt6quick6 libqt6quickwidgets6 \
    qml6-module-qtqml qml6-module-qtquick qml6-module-qtquick-controls \
    qml6-module-qtquick-layouts qml6-module-qtquick-dialogs qml6-module-qttexttospeech \
    qml6-module-qtquick-effects qml6-module-qtquick-shapes \
    && fc-cache -f -v

RUN --mount=type=bind,source=icon.png,target=/icon.png \
    install_app_icon.sh /icon.png \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /build_out/ /

RUN if [ -d /usr/lib/7zip ]; then \
        ln -sf /usr/lib/7zip/7z.so /usr/lib/7zip/lib7z.so && \
        ln -sfn /usr/lib/7zip /usr/lib/x86_64-linux-gnu/7zip; \
    fi

COPY --chmod=755 rootfs/ /

RUN \
    set-cont-env APP_NAME "YACReader Library" && \
    set-cont-env APP_VERSION "$YACREADER_VERSION" && \
    set-cont-env DOCKER_IMAGE_VERSION "$DOCKER_IMAGE_VERSION" && \
    true

LABEL \
    org.label-schema.name="YACReader" \
    org.label-schema.description="Docker container for YACReader" \
    org.label-schema.version="${YACREADER_VERSION}" \
    org.label-schema.vcs-url="https://github.com/b0unt9/docker-yacreader-gui" \
    org.label-schema.schema-version="1.0"

VOLUME ["/config"]