# r-ci

CI image for the R packages of the portfolio: `ghcr.io/sidneybissoli/r-ci`.

R release (`rocker/r-ver`), pandoc, qpdf and ghostscript, the system
libraries, and every R dependency (Suggests included) of the packages in
[`packages.txt`](packages.txt), plus the check tooling (rcmdcheck, lintr,
covr, pkgdown, devtools, testthat, …). Built weekly on Monday 06:00 UTC, on
every push to `main`, and on demand (`gh workflow run build.yaml -R
SidneyBissoli/r-ci`).

## Why

`r-lib/actions/setup-r` and `setup-r-dependencies` install system packages
through the Ubuntu apt mirror of the GitHub runners on every job. On
2026-10-23 that mirror (`azure.archive.ubuntu.com`) crawled — an 11 MB deb
in 166 s — and the two steps hung for up to two hours, three times in one
day, holding pull requests of cvmdata. Inside this image nothing is
installed at job time: the ubuntu jobs of the current R release go from
"install R and 150 packages" to "checkout and check".

The other jobs (R devel and oldrel-1, Windows, macOS) keep `setup-r`, with
a deadline on each setup step (`timeout-minutes`), so a stalled mirror
fails fast and the job is re-run instead of holding the PR.

## Use

In a workflow of one of the packages, the ubuntu job of the current R
release runs in the container and skips the setup steps:

```yaml
jobs:
  lint:
    runs-on: ubuntu-latest
    container: ghcr.io/sidneybissoli/r-ci:latest
    steps:
      - uses: actions/checkout@v7
      - run: lintr::lint_package()
        shell: Rscript {0}
```

A dependency the package gained after the last build is not in the image
until the next one. Keeping `r-lib/actions/setup-r-dependencies@v2` in the
job (with `cache: false`) covers that gap: with everything already
installed it takes seconds, and it installs only what is missing.

Tags: `latest`, `R<version>` (e.g. `R4.6.1`) and `R<version>-<yyyymmdd>`
for pinning a build.

## Adding a package

One line in `packages.txt` (`owner/repo default-branch`); the next build
fetches its DESCRIPTION. The R version moves with `rocker/r-ver` in the
`Dockerfile` (Dependabot proposes the bump).

## Measured

First build: see the run log of `Build image`; the job ceiling is twice the
measured duration.
