# gdal-mssql-docker

Docker images combining [GDAL](https://gdal.org/) with Microsoft's ODBC
Driver 18 for SQL Server, so `gdalinfo`/`ogrinfo`/`ogr2ogr` and friends can
read and write SQL Server / Azure SQL databases via GDAL's `MSSQLSpatial`
driver.

Built on top of the official [`ghcr.io/osgeo/gdal`](https://github.com/OSGeo/gdal/tree/master/docker)
`ubuntu-full` images — the only upstream variant compiled with ODBC support
(`ubuntu-small` and the Alpine variants are not, so `MSSQLSpatial` can never
work there — not something we can fix by installing a driver on top).

## Usage

```
docker pull ghcr.io/kosovojs/gdal-mssql-docker:latest
docker run --rm -v /path/to/data:/data ghcr.io/kosovojs/gdal-mssql-docker:latest \
  ogrinfo "MSSQL:server=myserver;database=mydb;UID=user;PWD=pass"
```

## Tags

- `ubuntu-full-<gdal_version>` — pinned, e.g. `ubuntu-full-3.13.3`
- `ubuntu-full-<major>.<minor>` — floating, tracks the newest patch in that line, e.g. `ubuntu-full-3.13`
- `ubuntu-full-latest` / `latest` — newest GDAL version this repo builds

## Supported GDAL versions

Latest patch of every GDAL major.minor line upstream currently publishes,
down to the floor set by `MIN_GDAL` in
[`.github/workflows/build.yml`](.github/workflows/build.yml) (currently
`3.6`). Rebuilt weekly (Monday 03:00 UTC), plus on every push that touches
the Dockerfile, locale library, tests, workflow, or discovery script.

## Non-ASCII SQL text

The image preloads a small library that sets `LC_CTYPE=C.UTF-8` at process
startup. This lets Microsoft's ODBC driver interpret UTF-8 SQL text correctly,
including non-ASCII literals in `-sql` and `-where` (for example, `'Rīga'`).
GDAL command-line tools do not call `setlocale()`, so setting `LANG` or
`LC_ALL` alone does not fix this. Other locale categories stay unchanged;
`LC_NUMERIC` remains `C` for decimal-point formatting and parsing.

The library applies to dynamically linked processes throughout the image.
Overriding `LD_PRELOAD` replaces this default. Image builds check UTF-8 to
UTF-16LE conversion and unchanged numeric formatting without a SQL Server.

## Known gaps

- **GDAL 3.13** (built on Ubuntu 26.04 "resolute") currently can't get
  `msodbcsql18` — Microsoft hasn't published a trusted signing key for that
  Ubuntu release yet. That one image tag will start building automatically
  the moment Microsoft catches up; no action needed here.

## Building locally

```
docker build --build-arg BASE_IMAGE=ghcr.io/osgeo/gdal:ubuntu-full-3.13.3 -t gdal-mssql .
```

## License

The [LICENSE](LICENSE) in this repo (MIT) covers only the files here — the
Dockerfile, build script, and CI workflow. It does not apply to GDAL or to
Microsoft's ODBC Driver for SQL Server, which are installed into the image
and remain under their own respective licenses (GDAL's MIT-style license;
msodbcsql18's Microsoft EULA, accepted via `ACCEPT_EULA=Y` at install time).
