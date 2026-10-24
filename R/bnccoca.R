#' Read Nation's cached BNC/COCA Level 6 word-family lists
#'
#' @return A list with dictionary, supplementary, catalog, resource and provenance.
#' @export
bnccoca_data <- function() {
  readRDS(.lex_resource_file("bnccoca", "extdata", "bnccoca", "ac81c7a6", "bnccoca.rds"))
}
