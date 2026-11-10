FROM jlesage/baseimage-gui:ubuntu-26.04-v4 AS runtime

ARG YACREADER_VERSION
ARG TARGETARCH

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
    7zip 7zip-rar libarchive13t64 \
    libqt6core6 libqt6gui6 libqt6network6 libqt6widgets6 libqt6sql6-sqlite libpoppler-qt6-3t64 \
    libqt6multimedia6 libqt6svg6 libqt6svgwidgets6 libqt6opengl6 libqt6openglwidgets6 libqt6core5compat6 libqt6shadertools6 libqt6texttospeech6 \
    qt6-gtk-platformtheme qt6-image-formats-plugins qt6-qpa-plugins \
    libqt6qml6 libqt6quick6 libqt6quickwidgets6 \
    qml6-module-qtqml qml6-module-qtquick qml6-module-qtquick-controls \
    qml6-module-qtquick-layouts qml6-module-qtquick-dialogs qml6-module-qttexttospeech \
    qml6-module-qtquick-effects qml6-module-qtquick-shapes \
    && fc-cache -f -v \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY output/${TARGETARCH}/ /

RUN if [ -d /usr/lib/7zip ]; then \
        ln -sf /usr/lib/7zip/7z.so /usr/lib/7zip/lib7z.so && \
        ln -sfn /usr/lib/7zip /usr/lib/$(uname -m)-linux-gnu/7zip; \
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