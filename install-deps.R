# Installs, into the image, every dependency of the packages whose
# DESCRIPTION the build workflow fetched into /tmp/descriptions/<pkg>/, with
# their Suggests (R CMD check needs them), plus the tooling the workflows
# call. pak resolves the union once and installs the system requirements
# (PKG_SYSREQS=true in the Dockerfile).

pak_repo <- sprintf(
  "https://r-lib.github.io/p/pak/stable/%s/%s/%s",
  .Platform$pkgType,
  R.Version()$os,
  R.Version()$arch
)
install.packages("pak", repos = pak_repo)

descs <- list.files(
  "/tmp/descriptions",
  pattern = "^DESCRIPTION$",
  recursive = TRUE,
  full.names = TRUE
)
if (length(descs) == 0L) {
  stop("no DESCRIPTION under /tmp/descriptions: the build did not fetch them")
}
message("packages: ", paste(basename(dirname(descs)), collapse = ", "))

# what the four CI workflows and the ETL robots call, beyond the packages'
# own dependencies
tooling <- c(
  "rcmdcheck",
  "lintr",
  "cyclocomp",
  "covr",
  "xml2",
  "pkgdown",
  "devtools",
  "roxygen2",
  "testthat",
  "spelling",
  "urlchecker",
  "sessioninfo",
  "pointblank",
  "digest",
  "jsonlite",
  "arrow"
)

pak::pkg_install(
  c(paste0("deps::", descs), tooling),
  dependencies = TRUE,
  upgrade = TRUE
)
pak::pak_cleanup(force = TRUE)

# the image is only useful if the tooling loads
for (p in c("rcmdcheck", "lintr", "covr", "pkgdown", "testthat")) {
  suppressPackageStartupMessages(library(p, character.only = TRUE))
}
message("R ", getRversion(), ", ", length(.packages(all.available = TRUE)), " packages installed")
