ARG BASE_IMAGE=ghcr.io/osgeo/gdal:ubuntu-full-latest
FROM ${BASE_IMAGE} AS utf8ctype

# Build against the runtime's libc, including for older supported Ubuntu images.
RUN apt-get update && apt-get install -y --no-install-recommends gcc libc6-dev
COPY utf8_ctype.c /src/utf8_ctype.c
COPY tests/utf8_ctype.c /src/test_utf8_ctype.c
RUN gcc -shared -fPIC -O2 -Wall -Wextra -Werror -o /src/libutf8ctype.so /src/utf8_ctype.c \
    && gcc -O2 -Wall -Wextra -Werror -o /src/test-utf8-ctype /src/test_utf8_ctype.c \
    && /src/test-utf8-ctype C

FROM ${BASE_IMAGE}

ENV DEBIAN_FRONTEND=noninteractive

RUN (apt-get update || true) \
    && apt-get install -y --no-install-recommends curl gnupg2 ca-certificates \
    && curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg \
    && . /etc/os-release \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/ubuntu/${VERSION_ID}/prod ${VERSION_CODENAME} main" > /etc/apt/sources.list.d/mssql-release.list \
    && (apt-get update || true) \
    && ACCEPT_EULA=Y apt-get install -y --no-install-recommends msodbcsql18 \
    && rm -rf /var/lib/apt/lists/*

# msodbcsql interprets narrow SQL text using the process LC_CTYPE. GDAL's CLI
# tools do not apply LANG/LC_ALL, so initialize just the character locale.
COPY --from=utf8ctype /src/libutf8ctype.so /usr/local/lib/libutf8ctype.so
ENV LD_PRELOAD=/usr/local/lib/libutf8ctype.so

# Exercise the constructor in the final image without shipping the test binary.
RUN --mount=type=bind,from=utf8ctype,source=/src/test-utf8-ctype,target=/tmp/test-utf8-ctype \
    /tmp/test-utf8-ctype UTF-8
