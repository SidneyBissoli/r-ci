# CI image for the R packages of the portfolio (cvmdata, healthbR, educabR,
# senado, welfarebR): R release, pandoc, the system libraries and every R
# dependency (Suggests included) of the packages listed in packages.txt,
# plus the check tooling. Rebuilt weekly by .github/workflows/build.yaml.
#
# Why: r-lib/actions/setup-r and setup-r-dependencies install system
# packages through the Ubuntu apt mirror of the GitHub runners on every
# job; on 2026-10-23 that mirror crawled and the two steps hung for hours.
# Inside this image nothing is installed at job time.
FROM rocker/r-ver:4.6.1

LABEL org.opencontainers.image.source="https://github.com/SidneyBissoli/r-ci" \
      org.opencontainers.image.description="R release + pandoc + the dependencies of the portfolio's R packages, for CI" \
      org.opencontainers.image.licenses="MIT"

ENV DEBIAN_FRONTEND=noninteractive \
    # pak installs the system requirements of the R packages (apt, as root)
    PKG_SYSREQS=true \
    # rocker already points CRAN at the P3M Ubuntu binaries; keep R quiet
    R_KEEP_PKG_SOURCE=yes \
    NOT_CRAN=true

# Tools the checks call besides R: pandoc (vignettes, pkgdown), qpdf and
# ghostscript (--compact-vignettes=gs+qpdf), git and curl (actions/checkout,
# downloads), gnupg (codecov-action verifies its uploader with gpg and
# refuses to run without it), locales for the Portuguese strings of the
# packages.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl git gnupg qpdf ghostscript locales libxml2-dev \
      libcurl4-openssl-dev libssl-dev libgit2-dev \
 && sed -i 's/^# *\(pt_BR.UTF-8\)/\1/; s/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen \
 && locale-gen \
 && /rocker_scripts/install_pandoc.sh \
 && rm -rf /var/lib/apt/lists/*

# The DESCRIPTION files are fetched by the build workflow from the default
# branch of each repository, so a dependency added yesterday is in next
# Monday's image (or in the next dispatched build).
COPY descriptions/ /tmp/descriptions/
COPY install-deps.R /tmp/install-deps.R
RUN Rscript /tmp/install-deps.R && rm -rf /tmp/descriptions /tmp/install-deps.R

# A job in this container runs as root; R CMD check is fine with that.
WORKDIR /work
CMD ["R", "--version"]
