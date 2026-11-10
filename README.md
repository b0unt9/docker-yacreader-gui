# Docker container for YACReader

This project provides a lightweight and secure Docker container for
[YACReader](https://www.yacreader.com).

Access the application's full graphical interface directly from any modern web
browser - no downloads, installs, or setup required on the client side - or
connect with any VNC client.

The web interface also offers audio playback, seamless clipboard sharing, an
integrated file manager and terminal for accessing the container's files and
shell, desktop notifications, and more.

> [!NOTE]
> This Docker container is entirely unofficial and not made by the creators of YACReader.

---

## Quick Start

> [!IMPORTANT]
> The Docker command provided in this quick start is an example, and parameters should be adjusted to suit your needs.

Launch the YACReader docker container with the following command:

```shell
docker run -d \
    --name=YACReader \
    -p 5800:5800 \
    -p 5700:8080 \
    -v /path/to/config:/config \
    -v /path/to/comics:/comics \
    b0unt9/yacreader-gui
```

Where:

  - `/path/to/config`: Stores the application's configuration, state, logs, and any files requiring persistency.
  - `/path/to/comics`: Stores the your's comics.

Access the YACReader GUI by browsing to `http://your-host-ip:5800`.

Access thie YACReaderServer by browsing to `http://your-host-ip:5700`

---

For detailed configuration, please refer to [jlesage/docker-baseimage-gui](https://github.com/jlesage/docker-baseimage-gui).