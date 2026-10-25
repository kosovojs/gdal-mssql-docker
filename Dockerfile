ARG BASE_IMAGE=ghcr.io/osgeo/gdal:ubuntu-full-latest
FROM ${BASE_IMAGE} AS utf8ctype

# Build against the runtime's libc, including for older supported Ubuntu images.
# Upstream images may contain stale third-party repositories. Ubuntu's package
# indexes can still refresh; installation itself must succeed.
RUN (apt-get update || true) \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends gcc libc6-dev
COPY utf8_ctype.c /src/utf8_ctype.c
COPY tests/utf8_ctype.c /src/test_utf8_ctype.c
RUN gcc -shared -fPIC -O2 -Wall -Wextra -Werror -o /src/libutf8ctype.so /src/utf8_ctype.c \
    && gcc -O2 -Wall -Wextra -Werror -o /src/test-utf8-ctype /src/test_utf8_ctype.c \
    && /src/test-utf8-ctype C

FROM ${BASE_IMAGE}

ENV DEBIAN_FRONTEND=noninteractive

RUN (apt-get update || true) \
    && apt-get install -y --no-install-recommends curl ca-certificates \
    && . /etc/os-release \
    && curl -fsSL "https://packages.microsoft.com/config/ubuntu/${VERSION_ID}/packages-microsoft-prod.deb" -o /tmp/packages-microsoft-prod.deb \
    && dpkg -i /tmp/packages-microsoft-prod.deb \
    && (apt-get update || true) \
    && ACCEPT_EULA=Y apt-get install -y --no-install-recommends msodbcsql18 \
    && rm /tmp/packages-microsoft-prod.deb \
    && rm -rf /var/lib/apt/lists/*

# msodbcsql interprets narrow SQL text using the process LC_CTYPE. GDAL's CLI
# tools do not apply LANG/LC_ALL, so initialize just the character locale.
COPY --from=utf8ctype /src/libutf8ctype.so /usr/local/lib/libutf8ctype.so
ENV LD_PRELOAD=/usr/local/lib/libutf8ctype.so

# Exercise the constructor in the final image without shipping the test binary.
RUN --mount=type=bind,from=utf8ctype,source=/src/test-utf8-ctype,target=/tmp/test-utf8-ctype \
    /tmp/test-utf8-ctype UTF-8
