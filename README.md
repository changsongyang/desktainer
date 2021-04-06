# desktainer

![](desktainer-icon-128.png)

[![Docker Pulls](https://img.shields.io/github/workflow/status/dmotte/desktainer/docker?logo=github&style=flat-square)](https://hub.docker.com/r/dmotte/desktainer)
[![Docker Pulls](https://img.shields.io/docker/pulls/dmotte/desktainer?logo=docker&style=flat-square)](https://hub.docker.com/r/dmotte/desktainer)

:computer: Remote **desk**top in a cont**ainer**.

> :package: This image is also on **Docker Hub** as [`dmotte/desktainer`](https://hub.docker.com/r/dmotte/desktainer) and runs on **several architectures** (e.g. amd64, arm64, ...). To see the full list of supported platforms, please refer to the `.github/workflows/docker.yml` file. If you need an architecture which is currently unsupported, feel free to open an issue.

Thanks to [fcwu/docker-ubuntu-vnc-desktop](https://github.com/fcwu/docker-ubuntu-vnc-desktop) and [soffchen/tiny-remote-desktop](https://github.com/soffchen/tiny-remote-desktop) for the inspiration.

## Usage

The simplest way to try this image is:

```bash
docker run -it --rm -p 6901:6901 dmotte/desktainer
```

Then head over to http://localhost:6901/ to access the remote desktop.

TODO screenshot

For a more complex example, refer to the `docker-compose.yml` file.

TODO you can make your own Dockerfile starting from this and/or mount your own supervisord file. See example of how to extend: TODO `example-extended` (sshd + siab + browser + other packages see t.o.Dockerfile and various p.b.)

### Environment variables

List of supported **environment variables**:

TODO: VNC_PASSWORD, USER, PASSWORD, RESOLUTION, VNC_PORT, NOVNC_PORT (see also docker-compose.yml)

remember to do envvars cleanup! otherwise vnc password would be available, etc.

## Development

TODO
