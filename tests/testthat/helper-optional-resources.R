# Data-dependent integration tests never download resources implicitly.
skip_optional_resources <- function(resources) {
  if (!all(lexdiv_resource_info(resources)$available))
    testthat::skip(paste("Optional reference data not prepared:", paste(resources, collapse = ", ")))
}
