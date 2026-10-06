#' Read Nation's bundled BNC/COCA Level 6 word-family lists
#'
#' @return A list with dictionary, supplementary, catalog, resource and provenance.
#' @export
bnccoca_data <- function() {
  readRDS(system.file("extdata", "bnccoca", "ac81c7a6", "bnccoca.rds",
    package = "ldfreq", mustWork = TRUE))
}
